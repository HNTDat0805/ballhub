import 'package:flutter/material.dart';
import '../../domain/models/match.dart';
import '../../domain/models/tournament.dart';
import '../../domain/models/tournament_team.dart';

/// Huy hiệu hiển thị trạng thái của giải đấu bóng đá (Chuẩn bị, Mở đăng ký, Đang diễn ra,...)
class TournamentStatusBadge extends StatelessWidget {
  final TournamentStatus status;

  const TournamentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      TournamentStatus.preparing => (Colors.blue.shade50, Colors.blue.shade800),
      TournamentStatus.registrationOpen => (Colors.green.shade50, Colors.green.shade800),
      TournamentStatus.inProgress => (Colors.orange.shade50, Colors.orange.shade900),
      TournamentStatus.completed => (Colors.purple.shade50, Colors.purple.shade800),
      TournamentStatus.cancelled => (Colors.red.shade50, Colors.red.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Huy hiệu trạng thái duyệt đơn đăng ký của đội bóng (Chờ duyệt, Đã duyệt, Từ chối,...)
class RegistrationStatusBadge extends StatelessWidget {
  final RegistrationStatus status;

  const RegistrationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      RegistrationStatus.pending => (Colors.amber.shade50, Colors.amber.shade900),
      RegistrationStatus.approved => (Colors.green.shade50, Colors.green.shade800),
      RegistrationStatus.rejected => (Colors.red.shade50, Colors.red.shade800),
      RegistrationStatus.cancelled => (Colors.grey.shade100, Colors.grey.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Huy hiệu trạng thái trận đấu (Chưa diễn ra, Đang diễn ra, Chờ xác nhận, Kết quả chính thức,...)
class MatchStatusBadge extends StatelessWidget {
  final MatchStatus status;
  final bool isConfirmed;

  const MatchStatusBadge({
    super.key,
    required this.status,
    this.isConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    String text = status.displayName;
    Color bg;
    Color fg;

    if (status == MatchStatus.finished) {
      if (isConfirmed) {
        text = 'Chính thức';
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
      } else {
        text = 'Chờ xác nhận';
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
      }
    } else if (status == MatchStatus.inProgress) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (status == MatchStatus.postponed) {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade800;
    } else if (status == MatchStatus.cancelled) {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
    } else {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
