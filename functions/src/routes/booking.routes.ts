import { Request, Response, Router } from 'express';
import { requireAuth, requireRoles } from '../middleware/auth.middleware';
import { bookingReasonSchema, createBookingSchema, validateBody } from '../middleware/validate.middleware';
import { BookingRequestError, BookingService } from '../services/booking.service';
import { UserRole } from '../types/auth.types';

export const bookingRouter = Router();
const service = new BookingService();
const bookingId = (req: Request) => Array.isArray(req.params.bookingId) ? req.params.bookingId[0] : req.params.bookingId;
const respond = (res: Response, error: unknown) => { const known = error instanceof BookingRequestError; res.status(known ? error.status : 500).json({ success: false, error: { code: known ? error.code : 'BOOKING_FAILED', message: error instanceof Error ? error.message : 'Không thể xử lý booking.' } }); };

bookingRouter.post('/', requireAuth, validateBody(createBookingSchema), async (req, res) => { try { res.status(201).json({ success: true, data: await service.create(req.body, req.user!) }); } catch (error) { respond(res, error); } });
bookingRouter.get('/me', requireAuth, async (req, res) => { try { res.json({ success: true, data: await service.mine(req.user!) }); } catch (error) { respond(res, error); } });
bookingRouter.get('/:bookingId', requireAuth, async (req, res) => { try { res.json({ success: true, data: await service.get(bookingId(req), req.user!) }); } catch (error) { respond(res, error); } });
bookingRouter.post('/:bookingId/cancel', requireAuth, validateBody(bookingReasonSchema), async (req, res) => { try { res.json({ success: true, data: await service.cancel(bookingId(req), req.body.reason, req.user!) }); } catch (error) { respond(res, error); } });

export const ownerBookingRouter = Router();
ownerBookingRouter.get('/bookings', requireAuth, requireRoles(UserRole.fieldOwner, UserRole.admin), async (req, res) => { try { res.json({ success: true, data: await service.ownerBookings(req.user!) }); } catch (error) { respond(res, error); } });
ownerBookingRouter.post('/bookings/:bookingId/confirm', requireAuth, requireRoles(UserRole.fieldOwner, UserRole.admin), async (req, res) => { try { res.json({ success: true, data: await service.confirm(bookingId(req), req.user!) }); } catch (error) { respond(res, error); } });
ownerBookingRouter.post('/bookings/:bookingId/reject', requireAuth, requireRoles(UserRole.fieldOwner, UserRole.admin), validateBody(bookingReasonSchema), async (req, res) => { try { res.json({ success: true, data: await service.reject(bookingId(req), req.body.reason, req.user!) }); } catch (error) { respond(res, error); } });
