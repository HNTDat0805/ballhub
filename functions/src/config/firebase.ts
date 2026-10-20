import * as admin from 'firebase-admin';

/**
 * Khởi tạo Firebase Admin SDK.
 * Khi chạy trên Cloud Functions hoặc môi trường Emulator / Local,
 * SDK sẽ sử dụng GOOGLE_APPLICATION_CREDENTIALS hoặc cấu hình projectId mặc định.
 */
if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || 'ballhub-ac5a7',
  });
}

export const db = admin.firestore();
export const auth = admin.auth();
export { admin };
