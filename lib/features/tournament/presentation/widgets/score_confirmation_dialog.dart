import 'package:flutter/material.dart';

/// Hộp thoại xác nhận kết quả tỷ số trận đấu bóng đá.
///
/// Yêu cầu người phê duyệt xác nhận tỷ số chính thức, đồng thời bắt buộc
/// nhập lý do giải trình nếu tỷ số được điều chỉnh lại sau khi đã từng chốt kết quả trước đó.
class ScoreConfirmationDialog extends StatefulWidget {
  final int homeScore;
  final int awayScore;
  final String homeTeamName;
  final String awayTeamName;
  final bool isAlreadyConfirmed;

  const ScoreConfirmationDialog({
    super.key,
    required this.homeScore,
    required this.awayScore,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.isAlreadyConfirmed,
  });

  @override
  State<ScoreConfirmationDialog> createState() => _ScoreConfirmationDialogState();
}

class _ScoreConfirmationDialogState extends State<ScoreConfirmationDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isAlreadyConfirmed ? Icons.warning_amber_rounded : Icons.verified_outlined,
            color: widget.isAlreadyConfirmed ? const Color(0xFFF57C00) : const Color(0xFF0F9D58),
          ),
          const SizedBox(width: 8),
          Text(
            widget.isAlreadyConfirmed ? 'Cảnh báo sửa kết quả' : 'Xác nhận kết quả trận đấu',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    widget.homeTeamName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${widget.homeScore} - ${widget.awayScore}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F9D58),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.awayTeamName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.isAlreadyConfirmed) ...[
            const Text(
              'Trận đấu này ĐÃ CÓ kết quả chính thức được tính vào bảng xếp hạng. '
              'Việc chỉnh sửa sẽ tự động tính toán lại toàn bộ bảng thứ hạng của giải và lưu vết thay đổi.',
              style: TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do điều chỉnh (bắt buộc) *',
                hintText: 'Vd: Đính chính biên bản trọng tài',
              ),
            ),
          ] else ...[
            const Text(
              'Sau khi xác nhận, tỷ số này sẽ chính thức được ghi nhận và tự động cộng điểm vào Bảng xếp hạng.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isAlreadyConfirmed ? const Color(0xFFF57C00) : const Color(0xFF0F9D58),
          ),
          onPressed: () {
            if (widget.isAlreadyConfirmed && _reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập lý do điều chỉnh')),
              );
              return;
            }
            Navigator.of(context).pop(_reasonController.text.trim());
          },
          child: const Text('Xác nhận & Cập nhật BXH'),
        ),
      ],
    );
  }
}
