import { FieldRepository } from '../repositories/field.repository';
import { SlotRepository } from '../repositories/slot.repository';
import { FieldSlotEntity, FieldSlotStatus } from '../types/booking.types';
import { AuthUser, UserRole } from '../types/auth.types';

export class SlotService {
  constructor(
    private readonly fields = new FieldRepository(),
    private readonly slots = new SlotRepository(),
  ) {}

  async list(fieldId: string, dateKey?: string): Promise<FieldSlotEntity[]> {
    await this.requireField(fieldId);
    return this.slots.list(fieldId, { dateKey });
  }

  async create(
    fieldId: string,
    data: Pick<FieldSlotEntity, 'dateKey' | 'startsAt' | 'endsAt' | 'basePrice' | 'currency'>,
    user: AuthUser,
  ): Promise<FieldSlotEntity> {
    const field = await this.requireOwner(fieldId, user);
    const durationMinutes = Math.round((Date.parse(data.endsAt) - Date.parse(data.startsAt)) / 60_000);
    if (durationMinutes <= 0) throw new Error('Khung giờ không hợp lệ.');
    const existing = await this.slots.list(fieldId, { dateKey: data.dateKey });
    const overlaps = existing.some((slot) => data.startsAt < slot.endsAt && data.endsAt > slot.startsAt);
    if (overlaps) throw new Error('Khung giờ bị chồng lấn với một ca đã có.');
    const now = new Date().toISOString();
    const slot: FieldSlotEntity = {
      id: `slot_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
      fieldId: field.id,
      ...data,
      durationMinutes,
      status: FieldSlotStatus.available,
      bookingId: null,
      holdExpiresAt: null,
      blockReason: null,
      createdAt: now,
      updatedAt: now,
    };
    await this.slots.save(slot);
    return slot;
  }

  async update(
    fieldId: string,
    slotId: string,
    data: Partial<Pick<FieldSlotEntity, 'basePrice' | 'status' | 'blockReason'>>,
    user: AuthUser,
  ): Promise<FieldSlotEntity> {
    await this.requireOwner(fieldId, user);
    const slot = await this.slots.find(fieldId, slotId);
    if (!slot) throw new Error('Không tìm thấy khung giờ.');
    if (slot.status === FieldSlotStatus.booked && data.status !== undefined)
      throw new Error('Không thể đổi trạng thái của ca đã được xác nhận.');
    const updated: FieldSlotEntity = { ...slot, ...data, updatedAt: new Date().toISOString() };
    await this.slots.save(updated);
    return updated;
  }

  /** Chủ sân khóa một khung giờ để không ai có thể đặt */
  async block(fieldId: string, slotId: string, reason: string, user: AuthUser): Promise<FieldSlotEntity> {
    await this.requireOwner(fieldId, user);
    const slot = await this.slots.find(fieldId, slotId);
    if (!slot) throw new Error('Không tìm thấy khung giờ.');
    if (slot.status === FieldSlotStatus.booked)
      throw new Error('Không thể khóa khung giờ đã được xác nhận booking.');
    if (slot.status === FieldSlotStatus.held)
      throw new Error('Không thể khóa khung giờ đang được giữ chỗ.');
    const updated: FieldSlotEntity = {
      ...slot,
      status: FieldSlotStatus.blocked,
      blockReason: reason,
      updatedAt: new Date().toISOString(),
    };
    await this.slots.save(updated);
    return updated;
  }

  /** Chủ sân mở khóa một khung giờ đã bị block */
  async unblock(fieldId: string, slotId: string, user: AuthUser): Promise<FieldSlotEntity> {
    await this.requireOwner(fieldId, user);
    const slot = await this.slots.find(fieldId, slotId);
    if (!slot) throw new Error('Không tìm thấy khung giờ.');
    if (slot.status !== FieldSlotStatus.blocked) throw new Error('Khung giờ này chưa bị khóa.');
    const updated: FieldSlotEntity = {
      ...slot,
      status: FieldSlotStatus.available,
      blockReason: null,
      updatedAt: new Date().toISOString(),
    };
    await this.slots.save(updated);
    return updated;
  }

  private async requireField(fieldId: string) {
    const field = await this.fields.findById(fieldId);
    if (!field) throw new Error('Không tìm thấy sân bóng.');
    return field;
  }

  private async requireOwner(fieldId: string, user: AuthUser) {
    const field = await this.requireField(fieldId);
    if (user.role !== UserRole.admin && field.ownerId !== user.uid)
      throw new Error('Bạn không có quyền quản lý sân này.');
    return field;
  }
}
