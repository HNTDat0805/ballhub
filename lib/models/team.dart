import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

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
}