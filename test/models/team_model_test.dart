import 'package:ballhub/models/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Team & Matchmaking Domain Models Tests', () {
    test('Team.fromMap should parse map correctly', () {
      final map = {
        'teamId': 'team_123',
        'teamName': 'FC Sao Vàng',
        'area': 'Bình Thạnh, TP.HCM',
        'description': 'Đội bóng phong trào',
        'captainId': 'cap_01',
        'captainName': 'Nguyễn Văn Đội Trưởng',
        'memberCount': 11,
        'createdAt': '2026-10-31T08:00:00.000Z',
      };

      final team = Team.fromMap(map);
      expect(team.teamId, 'team_123');
      expect(team.teamName, 'FC Sao Vàng');
      expect(team.area, 'Bình Thạnh, TP.HCM');
      expect(team.memberCount, 11);
      expect(team.createdAt, isNotNull);
    });

    test('MatchmakingCandidate.fromMap should parse candidate correctly', () {
      final map = {
        'team': {
          'teamId': 'team_456',
          'teamName': 'FC Rồng Bay',
          'area': 'Bình Thạnh',
          'captainId': 'cap_02',
          'captainName': 'Trần Đội Phó',
          'memberCount': 9,
        },
        'matchScore': 90,
        'reason': 'Cùng khu vực (Bình Thạnh)',
      };

      final candidate = MatchmakingCandidate.fromMap(map);
      expect(candidate.team.teamName, 'FC Rồng Bay');
      expect(candidate.matchScore, 90);
      expect(candidate.reason, contains('Bình Thạnh'));
    });

    test('FriendlyInvitation.fromMap should parse invitation correctly', () {
      final map = {
        'id': 'inv_789',
        'fromTeamId': 'team_123',
        'fromTeamName': 'FC Sao Vàng',
        'toTeamId': 'team_456',
        'toTeamName': 'FC Rồng Bay',
        'message': 'Giao hữu tối Chủ Nhật nhé!',
        'venue': 'Sân Thống Nhất',
        'status': 'Pending',
        'createdAt': '2026-10-31T09:00:00.000Z',
      };

      final inv = FriendlyInvitation.fromMap(map);
      expect(inv.id, 'inv_789');
      expect(inv.fromTeamName, 'FC Sao Vàng');
      expect(inv.toTeamName, 'FC Rồng Bay');
      expect(inv.status, 'Pending');
    });
  });
}
