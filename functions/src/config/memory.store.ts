import {
  TournamentEntity,
  TournamentRegistrationEntity,
  MatchEntity,
  StandingsRowEntity,
  MatchAuditEntity,
} from '../types/tournament.types';

export class MemoryStore {
  static tournaments = new Map<string, TournamentEntity>();
  static registrations = new Map<string, Map<string, TournamentRegistrationEntity>>();
  static matches = new Map<string, Map<string, MatchEntity>>();
  static standings = new Map<string, Map<string, StandingsRowEntity>>();
  static audits = new Map<string, MatchAuditEntity[]>();

  static clear(): void {
    this.tournaments.clear();
    this.registrations.clear();
    this.matches.clear();
    this.standings.clear();
    this.audits.clear();
  }

  static isMemoryMode(): boolean {
    return (
      process.env.USE_MEMORY_STORE === 'true' ||
      process.env.NODE_ENV === 'test' ||
      !process.env.FIRESTORE_EMULATOR_HOST && !process.env.GOOGLE_APPLICATION_CREDENTIALS
    );
  }
}
