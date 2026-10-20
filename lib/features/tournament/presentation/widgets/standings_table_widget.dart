import 'package:flutter/material.dart';
import '../../domain/models/standings_row.dart';

/// Bảng hiển thị thứ hạng giải đấu (Standings / Leaderboard Table).
///
/// Trình bày dữ liệu chuẩn bóng đá chuyên nghiệp:
/// - Xếp hạng nổi bật (Top 1 màu vàng cúp vô địch, Top 2-3 màu bạc/đồng).
/// - Các cột thống kê: Đội bóng, Trận (P), Thắng (W), Hòa (D), Thua (L),
///   Bàn thắng (GF), Bàn thua (GA), Hiệu số (GD) và Điểm (PTS).
class StandingsTableWidget extends StatelessWidget {
  final List<StandingsRow> standings;

  const StandingsTableWidget({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.leaderboard_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Chưa có dữ liệu bảng xếp hạng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Bảng xếp hạng sẽ tự động tính toán ngay khi có trận đấu được xác nhận kết quả.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1A237E),
            child: const Row(
              children: [
                Icon(Icons.emoji_events, color: Color(0xFFFFB300), size: 20),
                SizedBox(width: 8),
                Text(
                  'BẢNG XẾP HẠNG BÓNG ĐÁ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columnSpacing: 14,
              horizontalMargin: 12,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 52,
              columns: const [
                DataColumn(label: Text('Hạng', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Đội bóng', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Trận', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('T', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('H', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('BT', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('BB', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('HS', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Điểm', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F9D58))), numeric: true),
              ],
              rows: standings.map((row) {
                final isFirst = row.rank == 1;
                final isSecond = row.rank == 2;
                final isThird = row.rank == 3;

                Color? rankColor;
                if (isFirst) rankColor = const Color(0xFFFFB300);
                if (isSecond) rankColor = Colors.grey.shade400;
                if (isThird) rankColor = const Color(0xFFCD7F32);

                return DataRow(
                  color: isFirst
                      ? WidgetStateProperty.all(Colors.amber.shade50.withValues(alpha: 0.4))
                      : null,
                  cells: [
                    DataCell(
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: rankColor != null
                            ? BoxDecoration(
                                color: rankColor,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          '${row.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rankColor != null ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              row.teamName.isNotEmpty ? row.teamName[0] : 'T',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              row.teamName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text('${row.played}')),
                    DataCell(Text('${row.won}')),
                    DataCell(Text('${row.drawn}')),
                    DataCell(Text('${row.lost}')),
                    DataCell(Text('${row.goalsFor}')),
                    DataCell(Text('${row.goalsAgainst}')),
                    DataCell(
                      Text(
                        (row.goalDifference > 0) ? '+${row.goalDifference}' : '${row.goalDifference}',
                        style: TextStyle(
                          color: row.goalDifference > 0
                              ? Colors.green.shade700
                              : (row.goalDifference < 0 ? Colors.red.shade700 : Colors.black87),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9D58).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${row.points}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F9D58),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: const Text(
              'Ghi chú: T (Thắng 3đ), H (Hòa 1đ), B (Bại 0đ). Tiêu chí xếp hạng: Điểm -> Hiệu số (HS) -> Bàn thắng (BT) -> Đối đầu.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
