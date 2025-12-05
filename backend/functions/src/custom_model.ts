import { defineModel, GenerationCommonConfigSchema } from '@genkit-ai/ai/model';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { z } from 'zod';

const apiKey = process.env.GOOGLE_AI_API_KEY || '';
const genAI = new GoogleGenerativeAI(apiKey);

export const gemini20Flash = defineModel(
    {
        name: 'googleai/gemini-2.0-flash',
        label: 'Gemini 2.0 Flash',
        configSchema: GenerationCommonConfigSchema,
        supports: {
            multiturn: true,
            tools: true,
            systemRole: true,
            media: false,
        },
    },
    async (input, config) => {
        const model = genAI.getGenerativeModel({
            model: 'gemini-2.0-flash',
        });

        // Convert messages
        const history = input.messages.slice(0, -1).map((m: any) => {
            const part: any = {};

            // Handle text content
            if (m.content[0]?.text) {
                part.text = m.content[0].text;
            }

            // Handle tool requests in history
            if (m.content[0]?.toolRequest) {
                return {
                    role: 'model',
                    parts: [{
                        functionCall: {
                            name: m.content[0].toolRequest.name,
                            args: m.content[0].toolRequest.input
                        }
                    }]
                };
            }

            // Handle tool responses in history
            if (m.content[0]?.toolResponse) {
                return {
                    role: 'function',
                    parts: [{
                        functionResponse: {
                            name: m.content[0].toolResponse.name,
                            response: {
                                name: m.content[0].toolResponse.name,
                                content: m.content[0].toolResponse.output
                            }
                        }
                    }]
                };
            }

            // Fallback: If part is empty, add a space to satisfy API requirements
            if (!part.text && !part.functionCall && !part.functionResponse) {
                part.text = ' ';
            }

            return {
                role: m.role === 'user' ? 'user' : 'model',
                parts: [part],
            };
        });

        const lastMessage = input.messages[input.messages.length - 1];
        const prompt = lastMessage.content.map(c => c.text).join('');

        // Handle tools if present
        let tools: any[] = [];
        if (input.tools) {
            tools = [{
                functionDeclarations: input.tools.map((t: any) => {
                    const parameters = { ...t.inputSchema };
                    // Remove fields not supported by Gemini API
                    if (parameters.additionalProperties !== undefined) delete parameters.additionalProperties;
                    if (parameters.$schema !== undefined) delete parameters.$schema;

                    // Recursively clean properties if needed (simplified for now)
                    // Ideally we should traverse the schema, but top-level removal usually suffices for Genkit schemas

                    return {
                        name: t.name,
                        description: t.description,
                        parameters: parameters,
                    };
                }),
            }];
        }

        const chat = model.startChat({
            history: history as any,
            tools: tools.length > 0 ? tools : undefined,
        });

        const result = await chat.sendMessage(prompt);
        const response = await result.response;
        const text = response.text();

        // Handle tool calls in response
        const functionCalls = response.functionCalls();

        const toolRequest = functionCalls ? functionCalls.map((fc: any) => ({
            name: fc.name,
            input: fc.args,
        })) : [];

        // If there are tool calls, we should probably not return text, or Genkit might get confused.
        // Or we return both. Let's try returning candidates with the tool request.

        const candidateMessage: any = {
            role: 'model',
            content: [],
        };

        if (text) {
            candidateMessage.content.push({ text: text });
        }

        if (toolRequest.length > 0) {
            candidateMessage.content.push(...toolRequest.map((tr: any) => ({
                toolRequest: {
                    name: tr.name,
                    input: tr.input,
                }
            })));
        }

        return {
            candidates: [{
                index: 0,
                message: candidateMessage,
                finishReason: toolRequest.length > 0 ? 'stop' : 'stop',
            }],
        };
    }
);
