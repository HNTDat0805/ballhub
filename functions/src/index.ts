import { onRequest } from 'firebase-functions/v2/https';
import { app } from './app';

// Export Cloud Functions HTTPS handler
export const api = onRequest(
  {
    cors: true,
    maxInstances: 10,
    region: 'asia-southeast1',
  },
  app
);

export { app };
