import {
  TournamentEntity,
  TournamentRegistrationEntity,
  MatchEntity,
  StandingsRowEntity,
  MatchAuditEntity,
} from '../types/tournament.types';

/**
 * Kho lưu trữ bộ nhớ đệm In-Memory (MemoryStore) phục vụ kiểm thử đơn vị,
 * chạy headless và tự động fallback khi không có Firestore Emulator hoặc Cloud credentials.
 */
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
    // Tuyệt đối KHÔNG sử dụng In-Memory Mode trên môi trường Production hoặc Google Cloud Functions Runtime
    if (
      process.env.NODE_ENV === 'production' ||
      Boolean(process.env.K_SERVICE) ||
      Boolean(process.env.FUNCTION_TARGET) ||
      Boolean(process.env.FIREBASE_CONFIG)
    ) {
      return false;
    }

    return (
      process.env.USE_MEMORY_STORE === 'true' ||
      process.env.NODE_ENV === 'test' ||
      (!process.env.FIRESTORE_EMULATOR_HOST && !process.env.GOOGLE_APPLICATION_CREDENTIALS)
    );
  }
}
