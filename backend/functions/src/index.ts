import 'dotenv/config';
import './genkit'; // Initialize Genkit FIRST
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { runFlow } from '@genkit-ai/flow';
import { chatFlow } from './flows/chat_flow';
import './firebase'; // Ensure Firebase is initialized

/**
 * Firestore trigger: When a chat message is created
 * Processes user messages and generates AI responses
 */
export const onChatMessage = onDocumentCreated(
    'chat_messages/{messageId}',
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) {
            console.log('No data associated with the event');
            return;
        }

        const message = snapshot.data();

        // Only process user messages, not AI responses
        if (message.role !== 'user') {
            console.log('Skipping non-user message');
            return;
        }

        console.log('Processing user message:', {
            messageId: snapshot.id,
            sessionId: message.sessionId,
            userId: message.userId,
        });

        try {
            // Run the chat flow
            const response = await runFlow(chatFlow, {
                userId: message.userId,
                sessionId: message.sessionId,
                message: message.content,
            });

            // Write AI response back to Firestore
            await snapshot.ref.parent.add({
                sessionId: message.sessionId,
                role: 'assistant',
                content: response.text,
                toolCalls: response.toolCalls || [],
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log('AI response written successfully');
        } catch (error) {
            console.error('Error processing chat message:', error);

            // Write error message
            await snapshot.ref.parent.add({
                sessionId: message.sessionId,
                role: 'assistant',
                content: 'I apologize, but I encountered an error. Please try again.',
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }
);
