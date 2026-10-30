import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { authenticate } from './middleware/auth.middleware';
import { tournamentRouter } from './routes/tournament.routes';
import { registrationRouter } from './routes/registration.routes';
import { matchRouter } from './routes/match.routes';
import { standingsRouter } from './routes/standings.routes';
import { fieldRouter } from './routes/field.routes';
import { bookingRouter, ownerBookingRouter } from './routes/booking.routes';
import { slotRouter } from './routes/slot.routes';

/**
 * Cấu hình ứng dụng Express trung tâm cho Ballhub REST API v1.
 * Thiết lập các middleware bảo mật, CORS, xác thực người dùng và định tuyến tài nguyên.
 */
export const app = express();

// Middlewares
const isProduction = process.env.NODE_ENV === 'production';
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : ['https://ballhub.vn', 'https://ballhub-ac5a7.web.app', 'https://ballhub-ac5a7.firebaseapp.com'];

app.use(
  cors({
    origin: (origin, callback) => {
      // Cho phép requests không có origin (ví dụ: Flutter Mobile Client qua Http, Postman)
      if (!origin) return callback(null, true);
      // Môi trường development & local emulator cho phép toàn bộ origin
      if (!isProduction) return callback(null, true);
      // Trên Production, bắt buộc origin phải nằm trong whitelist được cấp phép
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Chính sách bảo mật CORS chặn truy cập từ Origin này.'));
    },
    credentials: true,
  })
);
app.use(express.json());
app.use(authenticate);

// Health check endpoint
app.get('/api/v1/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'Ballhub Tournament REST API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// OpenAPI Documentation JSON endpoint
app.get('/api/v1/docs', (req: Request, res: Response) => {
  res.json({
    openapi: '3.0.0',
    info: {
      title: 'Ballhub Tournament & Results Management API',
      version: '1.0.0',
      description: 'API-First REST API for Ballhub tournaments, team registrations, match schedules, results, and automatic standings calculation.',
    },
    paths: {
      '/api/v1/tournaments': {
        get: { summary: 'List all tournaments with filters' },
        post: { summary: 'Create a new tournament (Organizer/Admin only)' },
      },
      '/api/v1/tournaments/{id}': {
        get: { summary: 'Get tournament details' },
        patch: { summary: 'Update tournament (Organizer/Admin only)' },
        delete: { summary: 'Delete tournament (Organizer/Admin only)' },
      },
      '/api/v1/tournaments/{id}/registrations': {
        get: { summary: 'List registered teams' },
        post: { summary: 'Register a team (Captain/Organizer/Admin)' },
      },
      '/api/v1/tournaments/{id}/registrations/{registrationId}': {
        patch: { summary: 'Approve/Reject team registration (Organizer/Admin only)' },
        delete: { summary: 'Cancel team registration (Captain/Organizer/Admin)' },
      },
      '/api/v1/tournaments/{id}/schedule': {
        post: { summary: 'Auto-generate match schedule (Round Robin / Knockout)' },
      },
      '/api/v1/tournaments/{id}/matches': {
        get: { summary: 'List matches for tournament' },
      },
      '/api/v1/matches/{matchId}': {
        get: { summary: 'Get single match details' },
        patch: { summary: 'Update match schedule details' },
      },
      '/api/v1/matches/{matchId}/result': {
        put: { summary: 'Update match score, audit log, and atomically recompute standings' },
      },
      '/api/v1/tournaments/{id}/standings': {
        get: { summary: 'Get tournament standings / leaderboard table' },
      },
      '/api/v1/tournaments/{id}/audits': {
        get: { summary: 'Get audit logs for match score changes' },
      },
    },
  });
});

// Mount Resource Routes under /api/v1
app.use('/api/v1/tournaments', tournamentRouter);
app.use('/api/v1/tournaments', registrationRouter);
app.use('/api/v1', matchRouter);
app.use('/api/v1', standingsRouter);
app.use('/api/v1/fields', fieldRouter);
app.use('/api/v1', slotRouter);
app.use('/api/v1/bookings', bookingRouter);
app.use('/api/v1/owner', ownerBookingRouter);

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: `Endpoint ${req.method} ${req.originalUrl} không tồn tại trên hệ thống API Ballhub.`,
    },
  });
});

// Global error handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('API Error:', err);
  res.status(err.status || 500).json({
    success: false,
    error: {
      code: err.code || 'INTERNAL_SERVER_ERROR',
      message: err.message || 'Đã xảy ra lỗi máy chủ nội bộ.',
    },
  });
});
