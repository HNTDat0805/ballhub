export interface TeamEntity {
  teamId: string;
  teamName: string;
  teamNameLower: string;
  area: string;
  description: string;
  captainId: string;
  captainName: string;
  memberCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface TeamMemberEntity {
  id: string; // ${teamId}_${userId}
  teamId: string;
  userId: string;
  role: 'Captain' | 'Member';
  fullName: string;
  avatarBase64?: string | null;
  position?: string | null;
  joinedAt: string;
}

export type JoinRequestStatus = 'Pending' | 'Approved' | 'Rejected';

export interface JoinRequestEntity {
  requestId: string;
  teamId: string;
  userId: string;
  message: string;
  status: JoinRequestStatus;
  fullName: string;
  avatarBase64?: string | null;
  position?: string | null;
  createdAt: string;
  reviewedAt?: string | null;
  reviewedBy?: string | null;
}

export type InvitationStatus = 'Pending' | 'Accepted' | 'Declined' | 'Cancelled';

export interface FriendlyInvitationEntity {
  id: string;
  fromTeamId: string;
  fromTeamName: string;
  fromCaptainId: string;
  fromCaptainName: string;
  toTeamId: string;
  toTeamName: string;
  toCaptainId: string;
  toCaptainName: string;
  message: string;
  proposedDate?: string | null;
  venue?: string | null;
  status: InvitationStatus;
  createdAt: string;
  updatedAt: string;
}
