import { defineFlow, runFlow } from '@genkit-ai/flow';
import { gemini15Flash, geminiPro } from '@genkit-ai/googleai';
import { generate } from '@genkit-ai/ai';
import { z } from 'zod';
import * as fs from 'fs';
import * as path from 'path';
import { searchProvidersTool, checkAvailabilityTool, bookAppointmentTool, searchProviders, checkAvailability, bookAppointment } from '../tools';
import { db } from '../firebase';
import { gemini20Flash } from '../custom_model';

// Load system prompt
const SYSTEM_PROMPT = `
You are a helpful AI receptionist.
When you receive tool outputs, use them to answer the user's question naturally.
CRITICAL: DO NOT output raw JSON, 'tool_outputs' blocks, or debug information in your final response.
Only provide the natural language answer. The system will handle showing the data cards to the user.
`;

/**
 * Main chat flow
 */
export const chatFlow = defineFlow(
    {
        name: 'chatFlow',
        inputSchema: z.object({
            userId: z.string(),
            sessionId: z.string(),
            message: z.string(),
        }),
        outputSchema: z.object({
            text: z.string(),
            toolCalls: z.array(z.any()).optional(),
        }),
    },
    async ({ userId, sessionId, message }) => {
        console.log('Chat flow started:', { userId, sessionId, message });

        try {
            // Load conversation history
            const history = await loadChatHistory(sessionId);

            // Build context
            const context = await buildContext(userId, sessionId);

            // Build full prompt with system context
            const fullPrompt = `${SYSTEM_PROMPT}\n\n${context}\n\nUser: ${message}`;

            // First turn: Generate tool requests
            const result = await generate({
                model: gemini20Flash,
                prompt: fullPrompt,
                history: history as any,
                tools: [
                    searchProvidersTool,
                    checkAvailabilityTool,
                    bookAppointmentTool,
                ],
                config: {
                    temperature: 0.7,
                },
            });

            const toolRequests = result.toolRequests() || [];
            let responseText = result.text() || '';

            // Execute tools and collect outputs
            const toolCallsWithOutputs: any[] = [];

            if (toolRequests.length > 0) {
                console.log(`Processing ${toolRequests.length} tool requests...`);

                for (const request of toolRequests) {
                    if (!request.toolRequest) continue;

                    const toolName = request.toolRequest.name;
                    const toolInput = request.toolRequest.input as any;

                    console.log(`Executing tool: ${toolName}`);
                    let output: any = null;

                    try {
                        switch (toolName) {
                            case 'searchProviders':
                                output = await searchProviders(
                                    toolInput.query,
                                    toolInput.location,
                                    toolInput.industryId,
                                    toolInput.maxResults
                                );
                                break;
                            case 'checkAvailability':
                                output = await checkAvailability(
                                    toolInput.providerId,
                                    toolInput.date,
                                    toolInput.serviceId
                                );
                                break;
                            case 'bookAppointment':
                                output = await bookAppointment(
                                    toolInput.clientId,
                                    toolInput.providerId,
                                    toolInput.serviceId,
                                    toolInput.date,
                                    toolInput.time,
                                    toolInput.notes
                                );
                                break;
                            default:
                                console.warn(`Unknown tool: ${toolName}`);
                                output = { error: 'Unknown tool' };
                        }
                    } catch (err: any) {
                        console.error(`Error executing tool ${toolName}:`, err);
                        output = { error: err.message };
                    }

                    toolCallsWithOutputs.push({
                        name: toolName,
                        input: toolInput,
                        output: output,
                    });
                }

                // Second turn: Generate final response based on tool outputs
                // We construct a new prompt that includes the tool outputs
                // This forces the model to use the REAL data

                // Note: In a full Genkit flow we'd append to history, but here we'll just 
                // do a single-shot generation with the outputs as context for simplicity and speed

                const toolOutputsContext = toolCallsWithOutputs.map(tc =>
                    `Tool '${tc.name}' returned: ${JSON.stringify(tc.output)}`
                ).join('\n\n');

                const secondTurnPrompt = `${fullPrompt}\n\nSystem: I have executed the tools. Here are the results:\n${toolOutputsContext}\n\nPlease provide a helpful response to the user based ONLY on these results.`;

                console.log('Generating final response with tool outputs...');

                const secondResult = await generate({
                    model: gemini20Flash,
                    prompt: secondTurnPrompt,
                    history: history as any, // We reuse history but prompt is augmented
                    config: {
                        temperature: 0.7,
                    },
                });

                responseText = secondResult.text() || '';
            }

            // Clean up any raw tool outputs that might have leaked into the text
            responseText = responseText.replace(/```tool_outputs[\s\S]*?```/g, '').trim();
            responseText = responseText.replace(/tool_outputs\n' \+[\s\S]*?}/g, '').trim();

            if (!responseText && toolCallsWithOutputs.length > 0) {
                responseText = "I've found some results for you:";
            }

            return {
                text: responseText,
                toolCalls: toolCallsWithOutputs,
            };
        } catch (error: any) {
            console.error('Error in chat flow:', error);
            if (error.stack) console.error(error.stack);

            return {
                text: `I apologize, but I encountered an error: ${error.message || 'Unknown error'}. Please try again.`,
                toolCalls: [],
            };
        }
    }
);

/**
 * Load conversation history from Firestore
 */
async function loadChatHistory(sessionId: string) {
    try {
        const messagesSnapshot = await db
            .collection('chat_messages')
            .where('sessionId', '==', sessionId)
            .orderBy('timestamp', 'asc')
            .limit(50) // Last 50 messages
            .get();

        return messagesSnapshot.docs.map(doc => {
            const data = doc.data();
            const role = data.role === 'user' ? 'user' : 'model';
            return {
                role: role as 'user' | 'model',
                content: [{ text: data.content }],
            };
        });
    } catch (error) {
        console.error('Error loading chat history:', error);
        return [];
    }
}

/**
 * Build context for the conversation
 */
async function buildContext(userId: string, sessionId: string): Promise<string> {
    try {
        // Get user profile
        const userDoc = await db.collection('users').doc(userId).get();
        const user = userDoc.data();

        if (!user) {
            return '';
        }

        // Get session info
        const sessionDoc = await db.collection('chat_sessions').doc(sessionId).get();
        const session = sessionDoc.data();

        let context = `\n## Current User Context\n`;
        context += `- User: ${user.businessName || user.email}\n`;
        context += `- Role: ${user.role || 'client'}\n`;

        if (session?.providerId) {
            const providerDoc = await db.collection('users').doc(session.providerId).get();
            const provider = providerDoc.data();
            if (provider) {
                context += `- Inquiring about: ${provider.businessName}\n`;
            }
        }

        if (user.location) {
            context += `- Location: ${user.location.city || 'Unknown'}\n`;
        }

        return context;
    } catch (error) {
        console.error('Error building context:', error);
        return '';
    }
}
