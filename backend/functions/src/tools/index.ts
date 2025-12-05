import { defineTool } from '@genkit-ai/ai';
import { z } from 'zod';
import * as admin from 'firebase-admin';
import { db } from '../firebase';

// --- Implementation Functions ---

export async function searchProviders(query: string, location?: string, industryId?: string, maxResults: number = 5) {
    console.log('Searching providers:', { query, location, industryId, maxResults });

    // Ensure maxResults is a valid integer
    const limit = Number.isInteger(Number(maxResults)) ? Number(maxResults) : 5;

    try {
        if (!db) {
            console.error('Firestore DB instance is undefined!');
            return [];
        }
        // Search businesses first
        let businessQuery: admin.firestore.Query = db.collection('businesses');

        // Apply filters
        if (industryId) {
            businessQuery = businessQuery.where('industryId', '==', industryId);
        }

        console.log('Executing business query...');
        const businessesSnapshot = await businessQuery.limit(limit).get();
        console.log(`Found ${businessesSnapshot.size} businesses`);

        const businesses = businessesSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                name: data.name || 'Business',
                type: 'business' as const,
                businessName: data.name || 'Business', // Add businessName for UI compatibility
                rating: data.rating || 0,
                reviewCount: data.reviewCount || 0,
                services: [], // TODO: Fetch actual services
                location: data.location?.city,
                address: data.location?.address || data.location?.city, // Add address for UI
            };
        });

        // Search providers
        console.log('Executing provider query...');
        let providerQuery: admin.firestore.Query = db.collection('users').where('role', '==', 'provider');

        if (industryId) {
            providerQuery = providerQuery.where('industries', 'array-contains', industryId);
        }

        const providersSnapshot = await providerQuery.limit(limit).get();
        console.log(`Found ${providersSnapshot.size} providers`);

        const providers = providersSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                name: data.businessName || 'Provider',
                type: 'provider' as const,
                businessName: data.businessName || 'Provider',
                rating: 0, // TODO: Calculate from reviews
                reviewCount: 0,
                services: [], // TODO: Fetch services
                location: data.location?.city,
                address: data.location?.address || data.location?.city,
            };
        });

        // Combine and return
        const results = [...businesses, ...providers].slice(0, limit);

        console.log(`Found ${results.length} results`);
        return results;
    } catch (error) {
        console.error('Error searching providers:', error);
        return [];
    }
}

export async function checkAvailability(providerId: string, date: string, serviceId?: string) {
    console.log('Checking availability:', { providerId, date, serviceId });

    try {
        // Get provider name
        const providerDoc = await db.collection('users').doc(providerId).get();
        const providerName = providerDoc.data()?.businessName || 'Provider';

        // TODO: Implement actual availability checking
        // For now, return mock slots
        const slots = [
            '09:00',
            '10:00',
            '11:00',
            '14:00',
            '15:00',
            '16:00',
        ];

        return {
            date,
            slots,
            providerName,
        };
    } catch (error) {
        console.error('Error checking availability:', error);
        return {
            date,
            slots: [],
            providerName: 'Unknown',
        };
    }
}

export async function bookAppointment(clientId: string, providerId: string, serviceId: string, date: string, time: string, notes?: string) {
    console.log('Booking appointment:', { clientId, providerId, serviceId, date, time });

    try {
        // Get client, provider, and service details
        const [clientDoc, providerDoc, serviceDoc] = await Promise.all([
            db.collection('users').doc(clientId).get(),
            db.collection('users').doc(providerId).get(),
            db.collection('services').doc(serviceId).get(),
        ]);

        if (!clientDoc.exists || !providerDoc.exists || !serviceDoc.exists) {
            return {
                appointmentId: '',
                status: 'error' as const,
                message: 'Invalid client, provider, or service ID',
            };
        }

        const client = clientDoc.data()!;
        const provider = providerDoc.data()!;
        const service = serviceDoc.data()!;

        // Create appointment
        const appointmentRef = await db.collection('appointments').add({
            clientId,
            clientName: client.businessName || 'Client',
            clientEmail: client.email,
            clientPhone: client.phoneNumber || '',
            providerId,
            providerName: provider.businessName || 'Provider',
            serviceId,
            serviceName: service.name,
            servicePrice: service.price,
            serviceDuration: service.durationMinutes,
            appointmentDate: admin.firestore.Timestamp.fromDate(new Date(date)),
            appointmentTime: time,
            status: 'pending',
            notes: notes || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log('Appointment created:', appointmentRef.id);

        return {
            appointmentId: appointmentRef.id,
            status: 'success' as const,
            message: `Appointment booked successfully! Confirmation ID: ${appointmentRef.id}`,
        };
    } catch (error) {
        console.error('Error booking appointment:', error);
        return {
            appointmentId: '',
            status: 'error' as const,
            message: 'Failed to create appointment. Please try again.',
        };
    }
}

// --- Tool Definitions ---

export const searchProvidersTool = defineTool(
    {
        name: 'searchProviders',
        description: 'Search for service providers or businesses by service type, location, or industry. Returns top matching results with ratings and basic info.',
        inputSchema: z.object({
            query: z.string().describe('Service name or keywords (e.g., "haircut", "massage", "plumber")'),
            location: z.string().optional().describe('City or area preference'),
            industryId: z.string().optional().describe('Industry/category ID if known'),
            maxResults: z.coerce.number().default(5).describe('Maximum number of results to return'),
        }),
        outputSchema: z.any(),
    },
    async (input) => searchProviders(input.query, input.location, input.industryId, input.maxResults)
);

export const checkAvailabilityTool = defineTool(
    {
        name: 'checkAvailability',
        description: 'Check available time slots for a provider on a specific date. Returns list of available times.',
        inputSchema: z.object({
            providerId: z.string().describe('Provider ID'),
            date: z.string().describe('Date in YYYY-MM-DD format'),
            serviceId: z.string().optional().describe('Service ID if specific service'),
        }),
        outputSchema: z.object({
            date: z.string(),
            slots: z.array(z.string()),
            providerName: z.string(),
        }),
    },
    async (input) => checkAvailability(input.providerId, input.date, input.serviceId)
);

export const bookAppointmentTool = defineTool(
    {
        name: 'bookAppointment',
        description: 'Create a new appointment booking. Requires all details to be confirmed first.',
        inputSchema: z.object({
            clientId: z.string().describe('Client user ID'),
            providerId: z.string().describe('Provider ID'),
            serviceId: z.string().describe('Service ID'),
            date: z.string().describe('Appointment date (YYYY-MM-DD)'),
            time: z.string().describe('Appointment time (HH:mm)'),
            notes: z.string().optional().describe('Special requests or notes'),
        }),
        outputSchema: z.object({
            appointmentId: z.string(),
            status: z.enum(['success', 'error']),
            message: z.string(),
        }),
    },
    async (input) => bookAppointment(input.clientId, input.providerId, input.serviceId, input.date, input.time, input.notes)
);
