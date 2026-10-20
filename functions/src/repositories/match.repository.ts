import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { MatchEntity, MatchStatus } from '../types/tournament.types';

export class MatchRepository {
  private getRef(tournamentId: string) {
    return db.collection('tournaments').doc(tournamentId).collection('matches');
  }

  private getMemoryMap(tournamentId: string): Map<string, MatchEntity> {
    if (!MemoryStore.matches.has(tournamentId)) {
      MemoryStore.matches.set(tournamentId, new Map());
    }
    return MemoryStore.matches.get(tournamentId)!;
  }

  async findById(tournamentId: string, matchId: string): Promise<MatchEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      return this.getMemoryMap(tournamentId).get(matchId) || null;
    }

    const snap = await this.getRef(tournamentId).doc(matchId).get();
    if (!snap.exists) return null;
    return snap.data() as MatchEntity;
  }

  async findGlobalById(matchId: string): Promise<{ match: MatchEntity; tournamentId: string } | null> {
    if (MemoryStore.isMemoryMode()) {
      for (const [tId, matches] of MemoryStore.matches.entries()) {
        const match = matches.get(matchId);
        if (match) return { match, tournamentId: tId };
      }
      return null;
    }

    const snap = await db.collectionGroup('matches').where('id', '==', matchId).limit(1).get();
    if (snap.empty) return null;
    const doc = snap.docs[0];
    const match = doc.data() as MatchEntity;
    const tournamentId = doc.ref.parent.parent?.id || match.tournamentId;
    return { match, tournamentId };
  }

  async findByTournament(
    tournamentId: string,
    filters?: { round?: number; status?: MatchStatus; teamId?: string }
  ): Promise<MatchEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      let list = Array.from(this.getMemoryMap(tournamentId).values());
      if (filters?.round) {
        list = list.filter((m) => m.round === filters.round);
      }
      if (filters?.status) {
        list = list.filter((m) => m.status === filters.status);
      }
      if (filters?.teamId) {
        list = list.filter(
          (m) => m.homeTeamId === filters.teamId || m.awayTeamId === filters.teamId
        );
      }
      list.sort((a, b) => {
        if (a.round !== b.round) return a.round - b.round;
        return new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime();
      });
      return list;
    }

    let query: FirebaseFirestore.Query = this.getRef(tournamentId);

    if (filters?.round) {
      query = query.where('round', '==', filters.round);
    }
    if (filters?.status) {
      query = query.where('status', '==', filters.status);
    }

    const snap = await query.get();
    let list: MatchEntity[] = [];
    snap.forEach((doc) => list.push(doc.data() as MatchEntity));

    if (filters?.teamId) {
      list = list.filter(
        (m) => m.homeTeamId === filters.teamId || m.awayTeamId === filters.teamId
      );
    }

    list.sort((a, b) => {
      if (a.round !== b.round) return a.round - b.round;
      return new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime();
    });
    return list;
  }

  async saveBatch(tournamentId: string, matches: MatchEntity[]): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const map = this.getMemoryMap(tournamentId);
      for (const match of matches) {
        map.set(match.id, match);
      }
      return;
    }

    const batch = db.batch();
    const ref = this.getRef(tournamentId);
    for (const match of matches) {
      batch.set(ref.doc(match.id), match);
    }
    await batch.commit();
  }

  async update(tournamentId: string, matchId: string, data: Partial<MatchEntity>): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const map = this.getMemoryMap(tournamentId);
      const existing = map.get(matchId);
      if (existing) {
        map.set(matchId, { ...existing, ...data });
      }
      return;
    }
    await this.getRef(tournamentId).doc(matchId).update(data);
  }
}
