import { configureGenkit } from '@genkit-ai/core';
import { googleAI } from '@genkit-ai/googleai';

export const ai = configureGenkit({
    plugins: [
        googleAI({
            apiKey: process.env.GOOGLE_AI_API_KEY, // Gemini Pro API key
        }),
    ],
    logLevel: 'debug',
    enableTracingAndMetrics: true,
});
