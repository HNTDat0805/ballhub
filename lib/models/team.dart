import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class Team {
  final String teamId;
  final String teamName;
  final String area;
  final String? description;
  final String captainId;
  final String captainName;
  final int memberCount;
  final DateTime? createdAt;

  Team({
    required this.teamId,
    required this.teamName,
    required this.area,
    this.description,
    required this.captainId,
    required this.captainName,
    required this.memberCount,
    this.createdAt,
  });

  factory Team.fromMap(Map<String, dynamic> m) => Team(
        teamId: m['teamId'] ?? '',
        teamName: m['teamName'] ?? '',
        area: m['area'] ?? '',
        description: m['description'],
        captainId: m['captainId'] ?? '',
        captainName: m['captainName'] ?? '',
        memberCount: (m['memberCount'] as num?)?.toInt() ?? 0,
        createdAt: _toDate(m['createdAt']),
      );
}

class TeamMember {
  final String userId;
  final String role; // Captain / Member
  final String fullName;
  final String? avatarBase64;
  final String? position;

  TeamMember({
    required this.userId,
    required this.role,
    required this.fullName,
    this.avatarBase64,
    this.position,
  });

  factory TeamMember.fromMap(Map<String, dynamic> m) => TeamMember(
        userId: m['userId'] ?? '',
        role: m['role'] ?? 'Member',
        fullName: m['fullName'] ?? '(Không rõ)',
        avatarBase64: m['avatarBase64'],
        position: m['position'],
      );
}

class JoinRequest {
  final String requestId;
  final String teamId;
  final String userId;
  final String? message;
  final String fullName;
  final String? avatarBase64;
  final String? position;

  JoinRequest({
    required this.requestId,
    required this.teamId,
    required this.userId,
    this.message,
    required this.fullName,
    this.avatarBase64,
    this.position,
  });

  factory JoinRequest.fromMap(Map<String, dynamic> m) => JoinRequest(
        requestId: m['requestId'] ?? '',
        teamId: m['teamId'] ?? '',
        userId: m['userId'] ?? '',
        message: m['message'],
        fullName: m['fullName'] ?? '(Không rõ)',
        avatarBase64: m['avatarBase64'],
        position: m['position'],
      );
}

class MatchmakingCandidate {
  final Team team;
  final int matchScore;
  final String reason;

  MatchmakingCandidate({
    required this.team,
    required this.matchScore,
    required this.reason,
  });

  factory MatchmakingCandidate.fromMap(Map<String, dynamic> m) => MatchmakingCandidate(
        team: Team.fromMap(Map<String, dynamic>.from(m['team'] as Map)),
        matchScore: (m['matchScore'] as num?)?.toInt() ?? 50,
        reason: m['reason']?.toString() ?? '',
      );
}

class FriendlyInvitation {
  final String id;
  final String fromTeamId;
  final String fromTeamName;
  final String toTeamId;
  final String toTeamName;
  final String message;
  final String? venue;
  final String? proposedDate;
  final String status;
  final DateTime? createdAt;

  FriendlyInvitation({
    required this.id,
    required this.fromTeamId,
    required this.fromTeamName,
    required this.toTeamId,
    required this.toTeamName,
    required this.message,
    this.venue,
    this.proposedDate,
    required this.status,
    this.createdAt,
  });

  factory FriendlyInvitation.fromMap(Map<String, dynamic> m) => FriendlyInvitation(
        id: m['id'] ?? '',
        fromTeamId: m['fromTeamId'] ?? '',
        fromTeamName: m['fromTeamName'] ?? '',
        toTeamId: m['toTeamId'] ?? '',
        toTeamName: m['toTeamName'] ?? '',
        message: m['message'] ?? '',
        venue: m['venue'],
        proposedDate: m['proposedDate'],
        status: m['status'] ?? 'Pending',
        createdAt: _toDate(m['createdAt']),
      );
}