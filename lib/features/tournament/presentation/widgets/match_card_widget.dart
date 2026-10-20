import 'package:flutter/material.dart';
import '../../domain/models/match.dart';
import 'status_badge.dart';

/// Thẻ hiển thị tóm tắt trận đấu bóng đá (Match Card).
///
/// Thể hiện: Đội nhà, đội khách, tỷ số (hoặc 'vs'), thời gian thi đấu,
/// địa điểm sân bóng và huy hiệu trạng thái (Chưa diễn ra, Đang diễn ra, Đã kết thúc).
class MatchCardWidget extends StatelessWidget {
  final TournamentMatch match;
  final VoidCallback? onTap;

  const MatchCardWidget({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${match.scheduledTime.day.toString().padLeft(2, '0')}/${match.scheduledTime.month.toString().padLeft(2, '0')} ${match.scheduledTime.hour.toString().padLeft(2, '0')}:${match.scheduledTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // Header: Round and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          match.roundName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  MatchStatusBadge(
                    status: match.status,
                    isConfirmed: match.isConfirmed,
                  ),
                ],
              ),
              const Divider(height: 18),
              // Teams and score
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            match.homeTeamName,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            match.homeTeamName.isNotEmpty ? match.homeTeamName[0] : 'H',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score Box
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: match.isOfficialResult
                          ? const Color(0xFF0F9D58).withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: match.isOfficialResult ? const Color(0xFF0F9D58) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      match.scoreDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: match.isOfficialResult ? const Color(0xFF0F9D58) : Colors.black87,
                      ),
                    ),
                  ),

                  // Away Team
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.red.shade100,
                          child: Text(
                            match.awayTeamName.isNotEmpty ? match.awayTeamName[0] : 'A',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            match.awayTeamName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Venue
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    match.venue,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
