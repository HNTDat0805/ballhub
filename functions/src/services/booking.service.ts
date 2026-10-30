import { BookingConflictError, BookingRepository } from '../repositories/booking.repository';
import { FieldRepository } from '../repositories/field.repository';
import { SlotRepository } from '../repositories/slot.repository';
import { BookingEntity, BookingStatus, FieldSlotStatus, FieldStatus } from '../types/booking.types';
import { AuthUser, UserRole } from '../types/auth.types';

export class BookingService {
  constructor(private readonly bookings = new BookingRepository(), private readonly fields = new FieldRepository(), private readonly slots = new SlotRepository()) {}
  async create(data: { fieldId: string; slotIds: string[]; customerNote?: string }, user: AuthUser): Promise<BookingEntity> {
    const field = await this.fields.findById(data.fieldId);
    if (!field) throw new BookingRequestError('NOT_FOUND', 'Không tìm thấy sân bóng.', 404);
    if (field.status !== FieldStatus.active) throw new BookingRequestError('FIELD_UNAVAILABLE', 'Sân hiện không nhận đặt chỗ.', 409);
    const uniqueSlotIds = [...new Set(data.slotIds)];
    if (uniqueSlotIds.length !== data.slotIds.length) throw new BookingRequestError('VALIDATION_ERROR', 'Không được chọn trùng khung giờ.', 400);
    const slots = await Promise.all(uniqueSlotIds.map((id) => this.slots.find(field.id, id)));
    if (slots.some((slot) => !slot)) throw new BookingRequestError('NOT_FOUND', 'Có khung giờ không tồn tại.', 404);
    const selected = slots as NonNullable<(typeof slots)[number]>[];
    const sorted = [...selected].sort((a, b) => a.startsAt.localeCompare(b.startsAt));
    if (sorted.some((slot, index) => slot.status !== FieldSlotStatus.available || (index > 0 && sorted[index - 1].endsAt !== slot.startsAt))) throw new BookingRequestError('BOOKING_CONFLICT', 'Khung giờ không còn trống hoặc không liền kề.', 409);
    const now = new Date().toISOString();
    const total = selected.reduce((sum, slot) => sum + slot.basePrice, 0);
    const booking: BookingEntity = {
      id: `booking_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`, fieldId: field.id, ownerId: field.ownerId, bookerId: user.uid,
      dateKey: sorted[0].dateKey, startsAt: sorted[0].startsAt, endsAt: sorted[sorted.length - 1].endsAt, slotIds: uniqueSlotIds,
      fieldNameSnapshot: field.name, fieldAddressSnapshot: field.address, priceSnapshot: total, currency: selected[0].currency,
      bookerNameSnapshot: user.name ?? user.uid, bookerPhoneSnapshot: '', status: BookingStatus.pending, statusReason: null,
      subtotalAmount: total, discountAmount: 0, totalAmount: total, customerNote: data.customerNote ?? null, ownerNote: null,
      cancellationReason: null, confirmedAt: null, rejectedAt: null, cancelledAt: null, completedAt: null, reviewedBy: null, createdAt: now, updatedAt: now,
    };
    try { await this.bookings.reserve(booking); return booking; }
    catch (error) { if (error instanceof BookingConflictError) throw new BookingRequestError('BOOKING_CONFLICT', error.message, 409); throw error; }
  }
  async mine(user: AuthUser): Promise<BookingEntity[]> { return this.bookings.list({ bookerId: user.uid }); }
  async ownerBookings(user: AuthUser): Promise<BookingEntity[]> { return this.bookings.list({ ownerId: user.uid }); }
  async get(id: string, user: AuthUser): Promise<BookingEntity> { const booking = await this.requireBooking(id); this.assertParticipant(booking, user); return booking; }
  async cancel(id: string, reason: string | undefined, user: AuthUser): Promise<BookingEntity> { const booking = await this.requireBooking(id); if (booking.bookerId !== user.uid && user.role !== UserRole.admin) throw new BookingRequestError('FORBIDDEN', 'Bạn không có quyền hủy booking này.', 403); return this.transition(booking, BookingStatus.cancelledByUser, reason, true); }
  async confirm(id: string, user: AuthUser): Promise<BookingEntity> { const booking = await this.requireBooking(id); this.assertOwner(booking, user); return this.transition(booking, BookingStatus.confirmed, undefined, false); }
  async reject(id: string, reason: string | undefined, user: AuthUser): Promise<BookingEntity> { const booking = await this.requireBooking(id); this.assertOwner(booking, user); return this.transition(booking, BookingStatus.rejected, reason, true); }
  private async transition(booking: BookingEntity, status: BookingStatus, reason: string | undefined, release: boolean) { if (booking.status !== BookingStatus.pending) throw new BookingRequestError('INVALID_BOOKING_STATE', 'Booking không còn ở trạng thái chờ xử lý.', 409); try { return await this.bookings.transition(booking, status, reason, release); } catch (error) { if (error instanceof BookingConflictError) throw new BookingRequestError('BOOKING_CONFLICT', error.message, 409); throw error; } }
  private async requireBooking(id: string) { const booking = await this.bookings.find(id); if (!booking) throw new BookingRequestError('NOT_FOUND', 'Không tìm thấy booking.', 404); return booking; }
  private assertParticipant(booking: BookingEntity, user: AuthUser) { if (user.role !== UserRole.admin && booking.bookerId !== user.uid && booking.ownerId !== user.uid) throw new BookingRequestError('FORBIDDEN', 'Bạn không có quyền xem booking này.', 403); }
  private assertOwner(booking: BookingEntity, user: AuthUser) { if (user.role !== UserRole.admin && booking.ownerId !== user.uid) throw new BookingRequestError('FORBIDDEN', 'Bạn không có quyền quản lý booking này.', 403); }
}
export class BookingRequestError extends Error { constructor(readonly code: string, message: string, readonly status: number) { super(message); } }
