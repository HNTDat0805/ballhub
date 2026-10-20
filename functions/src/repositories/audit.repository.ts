import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { MatchAuditEntity } from '../types/tournament.types';

export class AuditRepository {
  private getRef(tournamentId: string) {
    return db.collection('tournaments').doc(tournamentId).collection('audits');
  }

  async save(audit: MatchAuditEntity, transaction?: FirebaseFirestore.Transaction): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      if (!MemoryStore.audits.has(audit.tournamentId)) {
        MemoryStore.audits.set(audit.tournamentId, []);
      }
      MemoryStore.audits.get(audit.tournamentId)!.push(audit);
      return;
    }

    const docRef = this.getRef(audit.tournamentId).doc(audit.id);
    if (transaction) {
      transaction.set(docRef, audit);
    } else {
      await docRef.set(audit);
    }
  }

  async findByTournament(tournamentId: string): Promise<MatchAuditEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      const list = MemoryStore.audits.get(tournamentId) || [];
      return [...list].sort(
        (a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
      );
    }

    const snap = await this.getRef(tournamentId).get();
    const list: MatchAuditEntity[] = [];
    snap.forEach((doc) => list.push(doc.data() as MatchAuditEntity));
    list.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
    return list;
  }
}
