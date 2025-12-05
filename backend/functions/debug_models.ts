import 'dotenv/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

async function listModels() {
    const apiKey = process.env.GOOGLE_AI_API_KEY;
    if (!apiKey) {
        console.error('❌ No GOOGLE_AI_API_KEY found in environment');
        return;
    }

    console.log('🔑 Using API Key:', apiKey.substring(0, 8) + '...');

    const genAI = new GoogleGenerativeAI(apiKey);

    try {
        // For listing models, we can't use the SDK directly easily in all versions, 
        // but let's try to just instantiate a model and run a simple prompt.
        // If this works, the key is good and the model exists.

        const modelName = 'gemini-1.5-flash';
        console.log(`\n🧪 Testing model: ${modelName}...`);
        const model = genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent('Hello, are you working?');
        const response = await result.response;
        console.log('✅ Success! Response:', response.text());

    } catch (error: any) {
        console.error('\n❌ Error testing model:', error.message);
        if (error.response) {
            console.error('Full Error Response:', JSON.stringify(error.response, null, 2));
        }
    }
}

listModels();
