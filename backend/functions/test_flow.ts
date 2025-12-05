import 'dotenv/config';
import * as admin from 'firebase-admin';
import { runFlow } from '@genkit-ai/flow';
import './src/genkit'; // Initialize Genkit
import { chatFlow } from './src/flows/chat_flow';
import './src/firebase'; // Initialize Firebase

async function test() {
    console.log('Starting test...');
    console.log('Using API Key:', process.env.GOOGLE_AI_API_KEY?.substring(0, 8) + '...');
    try {
        const response = await runFlow(chatFlow, {
            userId: 'test-user-1',
            sessionId: 'test-session-1',
            message: 'I need a haircut in Panama. Please SEARCH for real providers using the search tool.',
        });

        console.log('Response:', JSON.stringify(response, null, 2));
    } catch (e) {
        console.error('Error:', e);
    }
}

test();
