import { MatchEntity, MatchStatus, StandingsRowEntity, TournamentRegistrationEntity } from '../types/tournament.types';

export class StandingsService {
  static compute(
    teams: TournamentRegistrationEntity[],
    matches: MatchEntity[]
  ): StandingsRowEntity[] {
    const stats: Record<string, {
      teamId: string;
      teamName: string;
      logoUrl: string;
      played: number;
      won: number;
      drawn: number;
      lost: number;
      goalsFor: number;
      goalsAgainst: number;
      goalDifference: number;
      points: number;
    }> = {};

    for (const team of teams) {
      stats[team.teamId] = {
        teamId: team.teamId,
        teamName: team.teamName,
        logoUrl: team.logoUrl || '',
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        goalsFor: 0,
        goalsAgainst: 0,
        goalDifference: 0,
        points: 0,
      };
    }

    // Only confirmed, finished matches with non-null scores count towards standings
    const confirmedMatches = matches.filter(
      (m) => m.status === MatchStatus.finished && m.isConfirmed && m.homeScore != null && m.awayScore != null
    );

    for (const match of confirmedMatches) {
      const home = stats[match.homeTeamId];
      const away = stats[match.awayTeamId];
      if (!home || !away) continue;

      const hScore = match.homeScore!;
      const aScore = match.awayScore!;

      home.played += 1;
      away.played += 1;

      home.goalsFor += hScore;
      home.goalsAgainst += aScore;
      home.goalDifference = home.goalsFor - home.goalsAgainst;

      away.goalsFor += aScore;
      away.goalsAgainst += hScore;
      away.goalDifference = away.goalsFor - away.goalsAgainst;

      if (hScore > aScore) {
        home.won += 1;
        home.points += 3;
        away.lost += 1;
      } else if (hScore < aScore) {
        away.won += 1;
        away.points += 3;
        home.lost += 1;
      } else {
        home.drawn += 1;
        home.points += 1;
        away.drawn += 1;
        away.points += 1;
      }
    }

    const list = Object.values(stats);

    list.sort((a, b) => {
      // 1. Points
      if (b.points !== a.points) return b.points - a.points;

      // 2. Goal Difference
      if (b.goalDifference !== a.goalDifference) return b.goalDifference - a.goalDifference;

      // 3. Goals For
      if (b.goalsFor !== a.goalsFor) return b.goalsFor - a.goalsFor;

      // 4. Head-to-Head points between tied teams
      const h2h = this.compareHeadToHead(a.teamId, b.teamId, confirmedMatches);
      if (h2h !== 0) return h2h;

      // 5. Alphabetical fallback
      return a.teamName.localeCompare(b.teamName);
    });

    return list.map((item, index) => ({
      teamId: item.teamId,
      teamName: item.teamName,
      logoUrl: item.logoUrl,
      played: item.played,
      won: item.won,
      drawn: item.drawn,
      lost: item.lost,
      goalsFor: item.goalsFor,
      goalsAgainst: item.goalsAgainst,
      goalDifference: item.goalDifference,
      points: item.points,
      rank: index + 1,
    }));
  }

  private static compareHeadToHead(
    teamAId: string,
    teamBId: string,
    matches: MatchEntity[]
  ): number {
    let ptsA = 0;
    let ptsB = 0;

    for (const m of matches) {
      if (m.homeTeamId === teamAId && m.awayTeamId === teamBId) {
        if (m.homeScore! > m.awayScore!) ptsA += 3;
        else if (m.homeScore! < m.awayScore!) ptsB += 3;
        else { ptsA += 1; ptsB += 1; }
      } else if (m.homeTeamId === teamBId && m.awayTeamId === teamAId) {
        if (m.homeScore! > m.awayScore!) ptsB += 3;
        else if (m.homeScore! < m.awayScore!) ptsA += 3;
        else { ptsA += 1; ptsB += 1; }
      }
    }

    return ptsB - ptsA;
  }
}
