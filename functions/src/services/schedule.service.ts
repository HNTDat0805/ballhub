import {
  MatchEntity,
  MatchStatus,
  TournamentEntity,
  TournamentFormat,
  TournamentRegistrationEntity,
} from '../types/tournament.types';

/**
 * Dịch vụ thuật toán tạo lịch thi đấu Backend (Schedule Service).
 *
 * Triển khai thuật toán:
 * 1. Thuật toán vòng tròn Berger (Berger Round Robin System) với xoay vòng vị trí.
 * 2. Xử lý số đội lẻ thông qua lượt nghỉ (BYE).
 * 3. Hỗ trợ lượt về (Double Round Robin) đảo sân nhà/khách và dãn cách ngày.
 * 4. Thuật toán phân nhánh giải đấu loại trực tiếp (Knockout Bracket).
 * 5. Cơ chế sáp nhập an toàn (Safe Merge) bảo vệ các trận đã có kết quả chính thức.
 */
export class ScheduleService {
  static generate(
    tournament: TournamentEntity,
    approvedTeams: TournamentRegistrationEntity[],
    existingMatches: MatchEntity[] = [],
    defaultVenue: string = 'Sân vận động chính'
  ): MatchEntity[] {
    if (approvedTeams.length < 2) {
      return existingMatches;
    }

    let newMatches: MatchEntity[];

    switch (tournament.format) {
      case TournamentFormat.roundRobinSingle:
        newMatches = this.generateRoundRobin(tournament, approvedTeams, false, defaultVenue);
        break;
      case TournamentFormat.roundRobinDouble:
        newMatches = this.generateRoundRobin(tournament, approvedTeams, true, defaultVenue);
        break;
      case TournamentFormat.knockout:
        newMatches = this.generateKnockout(tournament, approvedTeams, defaultVenue);
        break;
      default:
        newMatches = this.generateRoundRobin(tournament, approvedTeams, false, defaultVenue);
    }

    // Safe merge: preserve any existing matches that already have confirmed/finished results
    if (existingMatches.length > 0) {
      const confirmedMatches = existingMatches.filter(
        (m) => m.status === MatchStatus.finished && m.isConfirmed
      );
      if (confirmedMatches.length > 0) {
        const merged: MatchEntity[] = [];
        for (const generated of newMatches) {
          const existing = existingMatches.find(
            (e) =>
              (e.homeTeamId === generated.homeTeamId && e.awayTeamId === generated.awayTeamId) ||
              (e.round === generated.round &&
                e.homeTeamId === generated.homeTeamId &&
                e.awayTeamId === generated.awayTeamId)
          );
          merged.push(existing || generated);
        }
        return merged;
      }
    }

    return newMatches;
  }

  private static generateRoundRobin(
    tournament: TournamentEntity,
    teams: TournamentRegistrationEntity[],
    isDouble: boolean,
    venue: string
  ): MatchEntity[] {
    const matches: MatchEntity[] = [];
    const teamList: (TournamentRegistrationEntity | null)[] = [...teams];

    // If odd number of teams, add null as BYE
    const isOdd = teamList.length % 2 !== 0;
    if (isOdd) {
      teamList.push(null);
    }

    const n = teamList.length;
    const totalRounds = n - 1;
    const matchesPerRound = Math.floor(n / 2);

    let baseTime = new Date(tournament.startDate);
    baseTime.setHours(8, 0, 0, 0);

    // Leg 1
    for (let round = 0; round < totalRounds; round++) {
      const roundNum = round + 1;
      const roundName = `Vòng ${roundNum}`;

      for (let mIdx = 0; mIdx < matchesPerRound; mIdx++) {
        const t1 = teamList[mIdx];
        const t2 = teamList[n - 1 - mIdx];

        if (!t1 || !t2) continue; // BYE round for that team

        // Alternate home/away for balance
        const isEvenRound = round % 2 === 0;
        const home = isEvenRound ? t1 : t2;
        const away = isEvenRound ? t2 : t1;

        const matchTime = new Date(baseTime.getTime() + round * 24 * 3600 * 1000 + mIdx * 2 * 3600 * 1000);

        matches.push({
          id: `m_${tournament.id}_r${roundNum}_${home.teamId}_${away.teamId}`,
          tournamentId: tournament.id,
          round: roundNum,
          roundName: roundName,
          homeTeamId: home.teamId,
          homeTeamName: home.teamName,
          awayTeamId: away.teamId,
          awayTeamName: away.teamName,
          scheduledTime: matchTime.toISOString(),
          venue: `${venue} - Sân ${mIdx + 1}`,
          status: MatchStatus.scheduled,
          isConfirmed: false,
        });
      }

      // Rotate array for Berger round-robin (keep index 0 fixed)
      const last = teamList.pop()!;
      teamList.splice(1, 0, last);
    }

    // Leg 2 (Return leg if double round-robin)
    if (isDouble) {
      const leg1Matches = [...matches];
      for (const m of leg1Matches) {
        const returnRound = m.round + totalRounds;
        const returnRoundName = `Vòng ${returnRound} (Lượt về)`;
        const origTime = new Date(m.scheduledTime);
        const returnTime = new Date(origTime.getTime() + totalRounds * 24 * 3600 * 1000);

        matches.push({
          id: `m_${tournament.id}_r${returnRound}_${m.awayTeamId}_${m.homeTeamId}`,
          tournamentId: tournament.id,
          round: returnRound,
          roundName: returnRoundName,
          homeTeamId: m.awayTeamId,
          homeTeamName: m.awayTeamName,
          awayTeamId: m.homeTeamId,
          awayTeamName: m.homeTeamName,
          scheduledTime: returnTime.toISOString(),
          venue: m.venue,
          status: MatchStatus.scheduled,
          isConfirmed: false,
        });
      }
    }

    return matches;
  }

  private static generateKnockout(
    tournament: TournamentEntity,
    teams: TournamentRegistrationEntity[],
    venue: string
  ): MatchEntity[] {
    const matches: MatchEntity[] = [];
    let baseTime = new Date(tournament.startDate);
    baseTime.setHours(9, 0, 0, 0);

    const count = teams.length;
    let roundName = 'Vòng 1';
    if (count <= 2) roundName = 'Chung kết';
    else if (count <= 4) roundName = 'Bán kết';
    else if (count <= 8) roundName = 'Tứ kết';

    const matchPairs = Math.floor(count / 2);
    for (let i = 0; i < matchPairs; i++) {
      const home = teams[i * 2];
      const away = teams[i * 2 + 1];
      const matchTime = new Date(baseTime.getTime() + i * 2 * 3600 * 1000);

      matches.push({
        id: `m_${tournament.id}_ko1_${home.teamId}_${away.teamId}`,
        tournamentId: tournament.id,
        round: 1,
        roundName: roundName,
        homeTeamId: home.teamId,
        homeTeamName: home.teamName,
        awayTeamId: away.teamId,
        awayTeamName: away.teamName,
        scheduledTime: matchTime.toISOString(),
        venue: `${venue} - Sân ${i + 1}`,
        status: MatchStatus.scheduled,
        isConfirmed: false,
      });
    }

    return matches;
  }
}
