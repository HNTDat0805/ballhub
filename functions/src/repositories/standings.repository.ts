import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { StandingsRowEntity } from '../types/tournament.types';

export class StandingsRepository {
  private getRef(tournamentId: string) {
    return db.collection('tournaments').doc(tournamentId).collection('standings');
  }

  private getMemoryMap(tournamentId: string): Map<string, StandingsRowEntity> {
    if (!MemoryStore.standings.has(tournamentId)) {
      MemoryStore.standings.set(tournamentId, new Map());
    }
    return MemoryStore.standings.get(tournamentId)!;
  }

  async findByTournament(tournamentId: string): Promise<StandingsRowEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      const list = Array.from(this.getMemoryMap(tournamentId).values());
      list.sort((a, b) => a.rank - b.rank);
      return list;
    }

    const snap = await this.getRef(tournamentId).get();
    const list: StandingsRowEntity[] = [];
    snap.forEach((doc) => list.push(doc.data() as StandingsRowEntity));
    list.sort((a, b) => a.rank - b.rank);
    return list;
  }

  async saveBatch(
    tournamentId: string,
    rows: StandingsRowEntity[],
    transaction?: FirebaseFirestore.Transaction
  ): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const map = this.getMemoryMap(tournamentId);
      for (const row of rows) {
        map.set(row.teamId, row);
      }
      return;
    }

    const ref = this.getRef(tournamentId);

    if (transaction) {
      for (const row of rows) {
        transaction.set(ref.doc(row.teamId), row);
      }
      return;
    }

    const batch = db.batch();
    for (const row of rows) {
      batch.set(ref.doc(row.teamId), row);
    }
    await batch.commit();
  }
}
