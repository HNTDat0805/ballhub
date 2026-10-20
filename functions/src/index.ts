import { onRequest } from 'firebase-functions/v2/https';
import { app } from './app';

/**
 * Điểm kích hoạt Firebase Cloud Function HTTPS 2nd Generation.
 * Định tuyến toàn bộ các yêu cầu HTTP tới Express app tại khu vực asia-southeast1 (Singapore).
 */
export const api = onRequest(
  {
    cors: true,
    maxInstances: 10,
    region: 'asia-southeast1',
  },
  app
);

export { app };
