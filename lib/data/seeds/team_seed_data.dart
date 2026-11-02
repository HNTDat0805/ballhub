import '../../models/team.dart';

/// Dữ liệu mẫu khởi tạo (Seed / Mock Data) cho phân hệ Đội bóng, Thành viên & Cáp kèo (Teams & Matchmaking).
///
/// Tách rời hoàn toàn khỏi `TeamService` để:
/// 1. Giữ logic nghiệp vụ của Service tinh gọn, dễ đọc và dễ bảo trì.
/// 2. Phục vụ dữ liệu giả lập cho việc chạy thử nghiệm khi chưa có máy chủ backend hoặc offline.
/// 3. Dễ dàng bổ sung đội bóng mẫu hoặc cấu hình ứng viên giao hữu mà không can thiệp code chức năng.
class TeamSeedData {
  /// Danh sách đội bóng phong trào mẫu trải dài các khu vực (TP.HCM, Hà Nội, Đà Nẵng,...)
  static List<Team> getSampleTeams({String keyword = '', String area = ''}) {
    final now = DateTime.now();
    final sample = [
      Team(
        teamId: 'team_sao_vang',
        teamName: 'FC Sao Vàng',
        area: 'Bình Thạnh, TP. Hồ Chí Minh',
        description: 'Đội bóng phong trào giao lưu cuối tuần, tinh thần thể thao văn minh.',
        captainId: 'user_captain_01',
        captainName: 'Trần Đội Trưởng',
        memberCount: 14,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Team(
        teamId: 'team_rong_do',
        teamName: 'FC Rồng Đỏ',
        area: 'Bình Thạnh, TP. Hồ Chí Minh',
        description: 'Chuyên cáp kèo sân 7 buổi tối, trình độ phong trào trung bình khá.',
        captainId: 'user_captain_02',
        captainName: 'Lê Đội Trưởng',
        memberCount: 12,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      Team(
        teamId: 'team_chien_binh',
        teamName: 'FC Chiến Binh Sài Gòn',
        area: 'Quận 1, TP. Hồ Chí Minh',
        description: 'Tập hợp anh em văn phòng đam mê bóng đá, tìm đối giao hữu thứ 4 & thứ 7.',
        captainId: 'user_captain_03',
        captainName: 'Nguyễn Văn Đội Trưởng',
        memberCount: 16,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Team(
        teamId: 'team_cau_vong',
        teamName: 'FC Cầu Vồng Trẻ',
        area: 'Thủ Đức, TP. Hồ Chí Minh',
        description: 'Đội bóng thanh niên nhiệt huyết, tìm đối giao lưu học hỏi kinh nghiệm.',
        captainId: 'user_captain_04',
        captainName: 'Phạm Đội Trưởng',
        memberCount: 15,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Team(
        teamId: 'team_thu_do',
        teamName: 'FC Thủ Đô Hà Nội',
        area: 'Cầu Giấy, Hà Nội',
        description:
            'Đội bóng giao lưu phong trào sân 7 tại Mỹ Đình và Cầu Giấy.',
        captainId: 'user_captain_05',
        captainName: 'Hoàng Đội Trưởng',
        memberCount: 18,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Team(
        teamId: 'team_song_han',
        teamName: 'FC Sông Hàn Đà Nẵng',
        area: 'Hải Châu, Đà Nẵng',
        description: 'Đội bóng trẻ nhiệt huyết khu vực Tuyên Sơn và Hải Châu.',
        captainId: 'user_captain_06',
        captainName: 'Vũ Đội Trưởng',
        memberCount: 14,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Team(
        teamId: 'team_dat_cang',
        teamName: 'FC Đất Cảng Hải Phòng',
        area: 'Lê Chân, Hải Phòng',
        description: 'Đội bóng phong trào cáp kèo sân Lạch Tray và Lê Chân.',
        captainId: 'user_captain_07',
        captainName: 'Đặng Đội Trưởng',
        memberCount: 15,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      Team(
        teamId: 'team_tay_do',
        teamName: 'FC Tây Đô Cần Thơ',
        area: 'Ninh Kiều, Cần Thơ',
        description:
            'Giao lưu bóng đá sân cỏ nhân tạo bến Ninh Kiều cuối tuần.',
        captainId: 'user_captain_08',
        captainName: 'Lâm Đội Trưởng',
        memberCount: 13,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Team(
        teamId: 'team_dat_thu',
        teamName: 'FC Đất Thủ Bình Dương',
        area: 'TP. Thủ Dầu Một, Bình Dương',
        description: 'Giao lưu phong trào khu vực Thủ Dầu Một và Thuận An.',
        captainId: 'user_captain_09',
        captainName: 'Bùi Đội Trưởng',
        memberCount: 16,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Team(
        teamId: 'team_bien_hoa',
        teamName: 'FC Miền Đông Đồng Nai',
        area: 'TP. Biên Hòa, Đồng Nai',
        description: 'Đội bóng giao hữu thể thao cuối tuần sân Biên Hòa.',
        captainId: 'user_captain_10',
        captainName: 'Dương Đội Trưởng',
        memberCount: 14,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      Team(
        teamId: 'team_pho_bien',
        teamName: 'FC Phố Biển Nha Trang',
        area: 'TP. Nha Trang, Khánh Hòa',
        description: 'Đội bóng phong trào biển Nha Trang, tìm đối giao hữu.',
        captainId: 'user_captain_11',
        captainName: 'Phan Đội Trưởng',
        memberCount: 12,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Team(
        teamId: 'team_xu_nghe',
        teamName: 'FC Xứ Nghệ Vinh',
        area: 'TP. Vinh, Nghệ An',
        description: 'Đam mê bóng đá sân cỏ nhân tạo thành phố Vinh.',
        captainId: 'user_captain_12',
        captainName: 'Hồ Đội Trưởng',
        memberCount: 17,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    return sample.where((t) {
      if (area.isNotEmpty &&
          !t.area.toLowerCase().contains(area.toLowerCase())) {
        return false;
      }
      if (keyword.isNotEmpty) {
        final q = keyword.toLowerCase();
        if (!t.teamName.toLowerCase().contains(q) &&
            !t.area.toLowerCase().contains(q) &&
            !(t.description?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Danh sách thành viên mẫu của đội bóng
  static List<TeamMember> getSampleMembers(String teamId) {
    return [
      TeamMember(
        userId: 'user_captain_01',
        role: 'Captain',
        fullName: 'Trần Đội Trưởng',
        position: 'Tiền đạo',
      ),
      TeamMember(
        userId: 'member_02',
        role: 'Member',
        fullName: 'Nguyễn Văn Hậu',
        position: 'Hậu vệ',
      ),
      TeamMember(
        userId: 'member_03',
        role: 'Member',
        fullName: 'Lê Minh Tiền',
        position: 'Tiền vệ',
      ),
      TeamMember(
        userId: 'member_04',
        role: 'Member',
        fullName: 'Đặng Thủ Môn',
        position: 'Thủ môn',
      ),
    ];
  }

  /// Danh sách ứng viên đối thủ mẫu cho tính năng cáp kèo giao hữu (Matchmaking)
  static List<MatchmakingCandidate> getSampleCandidates({String area = ''}) {
    final teams = getSampleTeams(area: area);
    return [
      if (teams.isNotEmpty)
        MatchmakingCandidate(
          team: teams[0],
          matchScore: 95,
          reason: 'Cùng khu vực Bình Thạnh, trình độ phong trào cân bằng',
        ),
      if (teams.length > 1)
        MatchmakingCandidate(
          team: teams[1],
          matchScore: 88,
          reason: 'Thường xuyên thi đấu khung giờ tối 19:00 - 20:30',
        ),
      if (teams.length > 2)
        MatchmakingCandidate(
          team: teams[2],
          matchScore: 82,
          reason: 'Tỷ lệ thắng 60%, phong cách thi đấu cởi mở',
        ),
    ];
  }
}
