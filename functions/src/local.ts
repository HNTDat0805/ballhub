/**
 * Script chạy máy chủ HTTP Node/Express độc lập tại local (cổng 5001).
 * Cho phép lập trình viên kiểm thử và chạy ứng dụng Flutter với API backend
 * mà không cần cài đặt hoặc khởi động Firebase Emulator Suite.
 */
import { app } from './app';

const PORT = process.env.PORT || 5001;

const server = app.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`⚽ Ballhub REST API Server is running locally!`);
  console.log(`🚀 Base URL: http://localhost:${PORT}/api/v1`);
  console.log(`📖 Health Check: http://localhost:${PORT}/api/v1/health`);
  console.log(`📚 OpenAPI Docs: http://localhost:${PORT}/api/v1/docs`);
  console.log(`=======================================================`);
});

process.on('SIGTERM', () => {
  server.close(() => console.log('Process terminated'));
});
