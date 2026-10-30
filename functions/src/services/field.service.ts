import { FieldRepository } from '../repositories/field.repository';
import { FieldStatus, FootballFieldEntity } from '../types/booking.types';
import { AuthUser, UserRole } from '../types/auth.types';

export class FieldService {
  constructor(private readonly repo = new FieldRepository()) {}
  async list(filters: Record<string, string | undefined>, user?: AuthUser): Promise<FootballFieldEntity[]> {
    const status = filters.status ?? (filters.ownerId && (user?.role === UserRole.fieldOwner || user?.role === UserRole.admin) ? undefined : FieldStatus.active);
    return this.repo.list({ ...filters, status });
  }
  async get(id: string): Promise<FootballFieldEntity> { const field = await this.repo.findById(id); if (!field) throw new Error('Không tìm thấy sân bóng.'); return field; }
  async create(data: Omit<FootballFieldEntity, 'id'|'ownerId'|'createdAt'|'updatedAt'|'createdBy'|'updatedBy'>, user: AuthUser): Promise<FootballFieldEntity> {
    const now = new Date().toISOString(); const id = `field_${Date.now()}_${Math.random().toString(36).slice(2,7)}`;
    const field: FootballFieldEntity = { ...data, id, ownerId: user.uid, createdAt: now, updatedAt: now, createdBy: user.uid, updatedBy: user.uid };
    await this.repo.save(field); return field;
  }
  async update(id: string, data: Partial<FootballFieldEntity>, user: AuthUser): Promise<FootballFieldEntity> {
    const current = await this.get(id); this.assertOwner(current, user); const updated = { ...current, ...data, id, ownerId: current.ownerId, updatedAt: new Date().toISOString(), updatedBy: user.uid };
    await this.repo.update(id, updated); return updated;
  }
  private assertOwner(field: FootballFieldEntity, user: AuthUser): void { if (user.role !== UserRole.admin && field.ownerId !== user.uid) throw new Error('Bạn không có quyền quản lý sân này.'); }
}
