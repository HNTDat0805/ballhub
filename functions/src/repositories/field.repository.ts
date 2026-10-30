import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { FootballFieldEntity } from '../types/booking.types';

const collection = 'fields';
export class FieldRepository {
  async findById(id: string): Promise<FootballFieldEntity | null> {
    if (MemoryStore.isMemoryMode()) return MemoryStore.fields.get(id) ?? null;
    const snap = await db.collection(collection).doc(id).get();
    return snap.exists ? snap.data() as FootballFieldEntity : null;
  }
  async list(filters: { city?: string; district?: string; fieldType?: string; status?: string; ownerId?: string; search?: string } = {}): Promise<FootballFieldEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      return [...MemoryStore.fields.values()].filter((field) =>
        (!filters.city || field.city === filters.city) && (!filters.district || field.district === filters.district) &&
        (!filters.fieldType || field.fieldType === filters.fieldType) && (!filters.status || field.status === filters.status) &&
        (!filters.ownerId || field.ownerId === filters.ownerId) && (!filters.search || field.name.toLowerCase().includes(filters.search.toLowerCase())));
    }
    let query: FirebaseFirestore.Query = db.collection(collection);
    for (const [key, value] of Object.entries(filters)) if (value && key !== 'search') query = query.where(key, '==', value);
    const snap = await query.get();
    return snap.docs.map((doc) => doc.data() as FootballFieldEntity).filter((field) => !filters.search || field.name.toLowerCase().includes(filters.search.toLowerCase()));
  }
  async save(field: FootballFieldEntity): Promise<void> { if (MemoryStore.isMemoryMode()) { MemoryStore.fields.set(field.id, field); return; } await db.collection(collection).doc(field.id).set(field); }
  async update(id: string, data: Partial<FootballFieldEntity>): Promise<void> { if (MemoryStore.isMemoryMode()) { const current = MemoryStore.fields.get(id); if (current) MemoryStore.fields.set(id, { ...current, ...data }); return; } await db.collection(collection).doc(id).update(data); }
}
