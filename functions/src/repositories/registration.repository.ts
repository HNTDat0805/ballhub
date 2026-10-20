import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { RegistrationStatus, TournamentRegistrationEntity } from '../types/tournament.types';

export class RegistrationRepository {
  private getRef(tournamentId: string) {
    return db.collection('tournaments').doc(tournamentId).collection('registrations');
  }

  private getMemoryMap(tournamentId: string): Map<string, TournamentRegistrationEntity> {
    if (!MemoryStore.registrations.has(tournamentId)) {
      MemoryStore.registrations.set(tournamentId, new Map());
    }
    return MemoryStore.registrations.get(tournamentId)!;
  }

  async findById(tournamentId: string, registrationId: string): Promise<TournamentRegistrationEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      return this.getMemoryMap(tournamentId).get(registrationId) || null;
    }

    const snap = await this.getRef(tournamentId).doc(registrationId).get();
    if (!snap.exists) return null;
    return snap.data() as TournamentRegistrationEntity;
  }

  async findByTeamId(tournamentId: string, teamId: string): Promise<TournamentRegistrationEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      const map = this.getMemoryMap(tournamentId);
      for (const reg of map.values()) {
        if (reg.teamId === teamId) return reg;
      }
      return null;
    }

    const snap = await this.getRef(tournamentId).where('teamId', '==', teamId).limit(1).get();
    if (snap.empty) return null;
    return snap.docs[0].data() as TournamentRegistrationEntity;
  }

  async findByTournament(
    tournamentId: string,
    status?: RegistrationStatus
  ): Promise<TournamentRegistrationEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      let list = Array.from(this.getMemoryMap(tournamentId).values());
      if (status) {
        list = list.filter((r) => r.status === status);
      }
      list.sort((a, b) => new Date(a.registeredAt).getTime() - new Date(b.registeredAt).getTime());
      return list;
    }

    let query: FirebaseFirestore.Query = this.getRef(tournamentId);
    if (status) {
      query = query.where('status', '==', status);
    }
    const snap = await query.get();
    const list: TournamentRegistrationEntity[] = [];
    snap.forEach((doc) => list.push(doc.data() as TournamentRegistrationEntity));
    list.sort((a, b) => new Date(a.registeredAt).getTime() - new Date(b.registeredAt).getTime());
    return list;
  }

  async countApproved(tournamentId: string, transaction?: FirebaseFirestore.Transaction): Promise<number> {
    if (MemoryStore.isMemoryMode()) {
      const list = Array.from(this.getMemoryMap(tournamentId).values());
      return list.filter((r) => r.status === RegistrationStatus.approved).length;
    }

    const query = this.getRef(tournamentId).where('status', '==', RegistrationStatus.approved);
    if (transaction) {
      const snap = await transaction.get(query);
      return snap.size;
    }
    const snap = await query.get();
    return snap.size;
  }

  async save(registration: TournamentRegistrationEntity): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      this.getMemoryMap(registration.tournamentId).set(registration.id, registration);
      return;
    }
    await this.getRef(registration.tournamentId).doc(registration.id).set(registration);
  }

  async update(
    tournamentId: string,
    registrationId: string,
    data: Partial<TournamentRegistrationEntity>
  ): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const map = this.getMemoryMap(tournamentId);
      const existing = map.get(registrationId);
      if (existing) {
        map.set(registrationId, { ...existing, ...data });
      }
      return;
    }
    await this.getRef(tournamentId).doc(registrationId).update(data);
  }

  async delete(tournamentId: string, registrationId: string): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      this.getMemoryMap(tournamentId).delete(registrationId);
      return;
    }
    await this.getRef(tournamentId).doc(registrationId).delete();
  }
}
