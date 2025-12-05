import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp({
        projectId: process.env.GCLOUD_PROJECT_ID || process.env.GCLOUD_PROJECT,
    });
}

export const db = admin.firestore();
