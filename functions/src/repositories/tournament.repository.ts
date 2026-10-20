import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { TournamentEntity } from '../types/tournament.types';

const COLLECTION = 'tournaments';

export class TournamentRepository {
  async findById(id: string): Promise<TournamentEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      return MemoryStore.tournaments.get(id) || null;
    }

    const snap = await db.collection(COLLECTION).doc(id).get();
    if (!snap.exists) return null;
    return snap.data() as TournamentEntity;
  }

  async findAll(query?: { status?: string; search?: string }): Promise<TournamentEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      let list = Array.from(MemoryStore.tournaments.values());
      if (query?.status) {
        list = list.filter((t) => t.status === query.status);
      }
      if (query?.search) {
        const s = query.search.toLowerCase();
        list = list.filter(
          (t) => t.name.toLowerCase().includes(s) || t.location.toLowerCase().includes(s)
        );
      }
      list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
      return list;
    }

    let ref: FirebaseFirestore.Query = db.collection(COLLECTION);

    if (query?.status) {
      ref = ref.where('status', '==', query.status);
    }

    const snap = await ref.get();
    let list: TournamentEntity[] = [];
    snap.forEach((doc) => {
      list.push(doc.data() as TournamentEntity);
    });

    if (query?.search) {
      const s = query.search.toLowerCase();
      list = list.filter(
        (t) => t.name.toLowerCase().includes(s) || t.location.toLowerCase().includes(s)
      );
    }

    list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    return list;
  }

  async save(tournament: TournamentEntity): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.tournaments.set(tournament.id, tournament);
      return;
    }
    await db.collection(COLLECTION).doc(tournament.id).set(tournament);
  }

  async update(id: string, data: Partial<TournamentEntity>): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const existing = MemoryStore.tournaments.get(id);
      if (existing) {
        MemoryStore.tournaments.set(id, { ...existing, ...data });
      }
      return;
    }
    await db.collection(COLLECTION).doc(id).update(data);
  }

  async delete(id: string): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.tournaments.delete(id);
      MemoryStore.registrations.delete(id);
      MemoryStore.matches.delete(id);
      MemoryStore.standings.delete(id);
      MemoryStore.audits.delete(id);
      return;
    }

    const tRef = db.collection(COLLECTION).doc(id);
    const subcollections = ['registrations', 'matches', 'standings', 'audits'];
    for (const sub of subcollections) {
      const subSnap = await tRef.collection(sub).get();
      const batch = db.batch();
      subSnap.forEach((doc) => batch.delete(doc.ref));
      if (subSnap.size > 0) {
        await batch.commit();
      }
    }
    await tRef.delete();
  }
}
