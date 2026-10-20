export enum TournamentFormat {
  roundRobinSingle = 'roundRobinSingle',
  roundRobinDouble = 'roundRobinDouble',
  knockout = 'knockout',
}

export enum TournamentStatus {
  preparing = 'preparing',
  registrationOpen = 'registrationOpen',
  inProgress = 'inProgress',
  completed = 'completed',
  cancelled = 'cancelled',
}

export enum RegistrationStatus {
  pending = 'pending',
  approved = 'approved',
  rejected = 'rejected',
  cancelled = 'cancelled',
}

export enum MatchStatus {
  scheduled = 'scheduled',
  inProgress = 'inProgress',
  finished = 'finished',
  postponed = 'postponed',
  cancelled = 'cancelled',
}

export interface TournamentEntity {
  id: string;
  name: string;
  description: string;
  bannerUrl: string;
  location: string;
  startDate: string; // ISO 8601
  endDate: string; // ISO 8601
  registrationDeadline: string; // ISO 8601
  maxTeams: number;
  format: TournamentFormat;
  status: TournamentStatus;
  organizerId: string;
  organizerName: string;
  createdAt: string;
  updatedAt: string;
}

export interface TournamentRegistrationEntity {
  id: string;
  tournamentId: string;
  teamId: string;
  teamName: string;
  logoUrl: string;
  captainId: string;
  captainName: string;
  captainPhone: string;
  captainEmail: string;
  membersCount: number;
  status: RegistrationStatus;
  registeredAt: string;
  reviewedAt?: string | null;
  reviewedBy?: string | null;
  reviewNote?: string | null;
}

export interface MatchEntity {
  id: string;
  tournamentId: string;
  round: number;
  roundName: string;
  homeTeamId: string;
  homeTeamName: string;
  awayTeamId: string;
  awayTeamName: string;
  scheduledTime: string;
  venue: string;
  status: MatchStatus;
  homeScore?: number | null;
  awayScore?: number | null;
  isConfirmed: boolean;
  confirmedBy?: string | null;
  confirmedAt?: string | null;
  notes?: string | null;
}

export interface StandingsRowEntity {
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
  rank: number;
}

export interface MatchAuditEntity {
  id: string;
  tournamentId: string;
  matchId: string;
  action: string;
  oldHomeScore?: number | null;
  oldAwayScore?: number | null;
  newHomeScore?: number | null;
  newAwayScore?: number | null;
  updatedBy: string;
  updatedAt: string;
  reason?: string | null;
}
