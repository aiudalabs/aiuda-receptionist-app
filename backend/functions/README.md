# AI Chat Backend

Backend for Aiuda Receptionist AI chat powered by Firebase Genkit and Gemini Pro.

## Setup

1. Install dependencies:
```bash
cd backend/functions
npm install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env and add your GOOGLE_AI_API_KEY
```

3. Get Gemini API key:
- Go to https://makersuite.google.com/app/apikey
- Create API key
- Add to .env file

## Development

Run locally with Genkit Dev UI:
```bash
npm run dev
```

This opens http://localhost:4000 where you can test the chat flow interactively.

## Deploy

Deploy to Firebase:
```bash
npm run deploy
```

## Architecture

- **Trigger**: Firestore `chat_messages` collection
- **Flow**: Genkit chat flow with Gemini Pro
- **Tools**: Search providers, check availability, book appointments
- **Output**: AI response written back to Firestore

## Environment Variables

Required:
- `GOOGLE_AI_API_KEY` - Gemini Pro API key
- `FIREBASE_PROJECT_ID` - Firebase project ID
