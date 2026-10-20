import { AuditRepository } from '../repositories/audit.repository';
import { MatchRepository } from '../repositories/match.repository';
import { RegistrationRepository } from '../repositories/registration.repository';
import { StandingsRepository } from '../repositories/standings.repository';
import { TournamentRepository } from '../repositories/tournament.repository';
import {
  MatchAuditEntity,
  MatchEntity,
  MatchStatus,
  RegistrationStatus,
  TournamentStatus,
} from '../types/tournament.types';
import { AuthUser, UserRole } from '../types/auth.types';
import { ScheduleService } from './schedule.service';
import { StandingsService } from './standings.service';

export class MatchService {
  constructor(
    private matchRepo: MatchRepository = new MatchRepository(),
    private tourRepo: TournamentRepository = new TournamentRepository(),
    private regRepo: RegistrationRepository = new RegistrationRepository(),
    private standingsRepo: StandingsRepository = new StandingsRepository(),
    private auditRepo: AuditRepository = new AuditRepository()
  ) {}

  async generateSchedule(
    tournamentId: string,
    venue: string,
    user: AuthUser
  ): Promise<MatchEntity[]> {
    const tournament = await this.tourRepo.findById(tournamentId);
    if (!tournament) throw new Error(`Không tìm thấy giải đấu: ${tournamentId}`);

    if (user.role !== UserRole.admin && tournament.organizerId !== user.uid) {
      throw new Error('Chỉ ban tổ chức giải đấu hoặc admin mới có quyền tạo lịch thi đấu.');
    }

    if (tournament.status === TournamentStatus.completed || tournament.status === TournamentStatus.cancelled) {
      throw new Error('Không thể tạo lại lịch thi đấu cho giải đã kết thúc hoặc bị hủy.');
    }

    // Only approved teams are included in the schedule
    const approvedTeams = await this.regRepo.findByTournament(
      tournamentId,
      RegistrationStatus.approved
    );

    if (approvedTeams.length < 2) {
      throw new Error(
        `Cần ít nhất 2 đội bóng đã được duyệt để tạo lịch thi đấu. Hiện tại chỉ có ${approvedTeams.length} đội.`
      );
    }

    const existingMatches = await this.matchRepo.findByTournament(tournamentId);

    const matches = ScheduleService.generate(
      tournament,
      approvedTeams,
      existingMatches,
      venue
    );

    // Save batch of matches
    await this.matchRepo.saveBatch(tournamentId, matches);

    // Initialize or recalculate standings for approved teams
    const standings = StandingsService.compute(approvedTeams, matches);
    await this.standingsRepo.saveBatch(tournamentId, standings);

    // Advance tournament status to inProgress if currently preparing or registrationOpen
    if (
      tournament.status === TournamentStatus.preparing ||
      tournament.status === TournamentStatus.registrationOpen
    ) {
      await this.tourRepo.update(tournamentId, {
        status: TournamentStatus.inProgress,
        updatedAt: new Date().toISOString(),
      });
    }

    return matches;
  }

  async listMatches(
    tournamentId: string,
    filters?: { round?: number; status?: MatchStatus; teamId?: string }
  ): Promise<MatchEntity[]> {
    return this.matchRepo.findByTournament(tournamentId, filters);
  }

  async getMatch(tournamentId: string, matchId: string): Promise<MatchEntity> {
    const match = await this.matchRepo.findById(tournamentId, matchId);
    if (!match) throw new Error(`Không tìm thấy trận đấu: ${matchId}`);
    return match;
  }

  async getGlobalMatch(matchId: string): Promise<{ match: MatchEntity; tournamentId: string }> {
    const res = await this.matchRepo.findGlobalById(matchId);
    if (!res) throw new Error(`Không tìm thấy trận đấu: ${matchId}`);
    return res;
  }

  async updateMatchDetails(
    tournamentId: string,
    matchId: string,
    data: {
      scheduledTime?: string;
      venue?: string;
      notes?: string;
      status?: MatchStatus;
    },
    user: AuthUser
  ): Promise<MatchEntity> {
    const tournament = await this.tourRepo.findById(tournamentId);
    if (!tournament) throw new Error('Không tìm thấy giải đấu.');

    if (user.role !== UserRole.admin && tournament.organizerId !== user.uid) {
      throw new Error('Bạn không có quyền điều chỉnh lịch thi đấu này.');
    }

    const match = await this.matchRepo.findById(tournamentId, matchId);
    if (!match) throw new Error('Không tìm thấy trận đấu.');

    await this.matchRepo.update(tournamentId, matchId, data);
    return { ...match, ...data };
  }

  async updateMatchResult(
    tournamentId: string,
    matchId: string,
    data: {
      homeScore: number;
      awayScore: number;
      status?: MatchStatus;
      isConfirmed?: boolean;
      notes?: string;
      reason?: string;
    },
    user: AuthUser
  ): Promise<{ match: MatchEntity; standings: any[] }> {
    const tournament = await this.tourRepo.findById(tournamentId);
    if (!tournament) throw new Error('Không tìm thấy giải đấu.');

    if (tournament.status === TournamentStatus.completed) {
      throw new Error('Giải đấu đã kết thúc hoàn toàn, không thể chỉnh sửa kết quả trận đấu.');
    }

    if (user.role !== UserRole.admin && tournament.organizerId !== user.uid) {
      throw new Error('Chỉ ban tổ chức giải đấu hoặc admin mới có quyền cập nhật tỷ số trận đấu.');
    }

    const match = await this.matchRepo.findById(tournamentId, matchId);
    if (!match) throw new Error('Không tìm thấy trận đấu.');

    const now = new Date().toISOString();
    const isConfirmed = data.isConfirmed ?? true;
    const matchStatus = data.status ?? MatchStatus.finished;

    // Create Audit Log
    const auditId = `audit_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const audit: MatchAuditEntity = {
      id: auditId,
      tournamentId,
      matchId,
      action: match.isConfirmed ? 'adjust_score' : 'confirm_score',
      oldHomeScore: match.homeScore ?? null,
      oldAwayScore: match.awayScore ?? null,
      newHomeScore: data.homeScore,
      newAwayScore: data.awayScore,
      updatedBy: user.name || user.email || user.uid,
      updatedAt: now,
      reason: data.reason || (match.isConfirmed ? 'Điều chỉnh tỷ số trận đấu' : 'Nhập tỷ số chính thức'),
    };

    const updatedMatch: MatchEntity = {
      ...match,
      homeScore: data.homeScore,
      awayScore: data.awayScore,
      status: matchStatus,
      isConfirmed,
      confirmedBy: isConfirmed ? (user.name || user.uid) : null,
      confirmedAt: isConfirmed ? now : null,
      notes: data.notes ?? match.notes,
    };

    // Save match and audit log
    await this.matchRepo.update(tournamentId, matchId, updatedMatch);
    await this.auditRepo.save(audit);

    // Recalculate standings atomically
    const approvedTeams = await this.regRepo.findByTournament(
      tournamentId,
      RegistrationStatus.approved
    );
    const allMatches = await this.matchRepo.findByTournament(tournamentId);
    const standings = StandingsService.compute(approvedTeams, allMatches);
    await this.standingsRepo.saveBatch(tournamentId, standings);

    return { match: updatedMatch, standings };
  }

  async getStandings(tournamentId: string) {
    return this.standingsRepo.findByTournament(tournamentId);
  }

  async getAudits(tournamentId: string) {
    return this.auditRepo.findByTournament(tournamentId);
  }
}
