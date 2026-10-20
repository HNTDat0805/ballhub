import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../domain/models/match.dart';
import '../../domain/models/tournament.dart';
import '../controllers/tournament_controller.dart';
import '../widgets/role_selector_widget.dart';
import '../widgets/score_confirmation_dialog.dart';
import '../widgets/status_badge.dart';

class MatchDetailScreen extends StatefulWidget {
  final TournamentMatch match;
  final Tournament tournament;
  final TournamentController controller;

  const MatchDetailScreen({
    super.key,
    required this.match,
    required this.tournament,
    required this.controller,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late TextEditingController _homeScoreController;
  late TextEditingController _awayScoreController;
  late TextEditingController _notesController;
  late MatchStatus _status;

  @override
  void initState() {
    super.initState();
    _homeScoreController = TextEditingController(
      text: widget.match.homeScore != null ? widget.match.homeScore.toString() : '',
    );
    _awayScoreController = TextEditingController(
      text: widget.match.awayScore != null ? widget.match.awayScore.toString() : '',
    );
    _notesController = TextEditingController(text: widget.match.notes ?? '');
    _status = widget.match.status;
  }

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveScore({required bool confirmResult}) async {
    final homeText = _homeScoreController.text.trim();
    final awayText = _awayScoreController.text.trim();

    final homeScore = int.tryParse(homeText);
    final awayScore = int.tryParse(awayText);

    if (homeScore == null || awayScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tỷ số hợp lệ cho cả hai đội')),
      );
      return;
    }

    if (homeScore < 0 || awayScore < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tỷ số trận đấu không được là số âm')),
      );
      return;
    }

    String? reason;
    if (confirmResult) {
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => ScoreConfirmationDialog(
          homeScore: homeScore,
          awayScore: awayScore,
          homeTeamName: widget.match.homeTeamName,
          awayTeamName: widget.match.awayTeamName,
          isAlreadyConfirmed: widget.match.isConfirmed,
        ),
      );
      if (reason == null && widget.match.isConfirmed) {
        // User cancelled dialog
        return;
      }
    }

    final user = AuthContext.instance.currentUser;

    final ok = await widget.controller.updateMatchResult(
      tournamentId: widget.tournament.id,
      matchId: widget.match.id,
      homeScore: homeScore,
      awayScore: awayScore,
      status: confirmResult ? MatchStatus.finished : _status,
      isConfirmed: confirmResult,
      updatedBy: '${user.name} (${user.role.displayName})',
      notes: _notesController.text.trim(),
      reason: reason,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmResult
              ? 'Đã xác nhận kết quả & cập nhật lại Bảng xếp hạng!'
              : 'Đã lưu tỷ số nháp thành công!'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage ?? 'Có lỗi xảy ra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final dateStr = '${match.scheduledTime.day}/${match.scheduledTime.month}/${match.scheduledTime.year} lúc ${match.scheduledTime.hour.toString().padLeft(2, '0')}:${match.scheduledTime.minute.toString().padLeft(2, '0')}';

    return ListenableBuilder(
      listenable: AuthContext.instance,
      builder: (context, _) {
        final canManage = AuthContext.instance.canManageMatch(widget.tournament.organizerId);

        return Scaffold(
          appBar: AppBar(
            title: Text(match.roundName),
            actions: const [
              RoleSelectorWidget(),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Match Header Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              match.roundName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                            ),
                            MatchStatusBadge(
                              status: _status,
                              isConfirmed: match.isConfirmed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Scoreboard
                        Row(
                          children: [
                            // Home Team
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      match.homeTeamName.isNotEmpty ? match.homeTeamName[0] : 'H',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    match.homeTeamName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Text('Đội nhà', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),

                            // VS / Score indicator
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  if (match.hasValidScore) ...[
                                    Text(
                                      '${match.homeScore} : ${match.awayScore}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: match.isOfficialResult ? const Color(0xFF0F9D58) : Colors.black87,
                                      ),
                                    ),
                                    if (match.isOfficialResult)
                                      const Text(
                                        'CHÍNH THỨC',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F9D58)),
                                      ),
                                  ] else
                                    const Text(
                                      'VS',
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),

                            // Away Team
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.red.shade100,
                                    child: Text(
                                      match.awayTeamName.isNotEmpty ? match.awayTeamName[0] : 'A',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    match.awayTeamName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Text('Đội khách', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(match.venue, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Operator Score Entry Form (Organizer/Admin only)
                if (canManage) ...[
                  const Text(
                    'CẬP NHẬT TỶ SỐ VÀ TRẠNG THÁI (BAN TỔ CHỨC)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _homeScoreController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: 'Bàn thắng (${match.homeTeamName})',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _awayScoreController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: 'Bàn thắng (${match.awayTeamName})',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<MatchStatus>(
                            initialValue: _status,
                            decoration: const InputDecoration(labelText: 'Trạng thái diễn biến trận đấu'),
                            items: MatchStatus.values.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s.displayName));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Ghi chú trận đấu (Thẻ phạt, cầu thủ ghi bàn...)',
                              hintText: 'Nhập thông tin chi tiết biên bản trận đấu',
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: widget.controller.isLoading
                                      ? null
                                      : () => _saveScore(confirmResult: false),
                                  child: const Text('Lưu tỷ số nháp'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
                                  onPressed: widget.controller.isLoading
                                      ? null
                                      : () => _saveScore(confirmResult: true),
                                  child: const Text('Xác nhận chính thức'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Readonly message for non-organizers
                  Card(
                    color: Colors.blue.shade50,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bạn đang xem dưới vai trò ${AuthContext.instance.currentUser.role.displayName}. '
                              'Chỉ Ban Tổ Chức mới có quyền cập nhật và xác nhận tỷ số trận đấu.',
                              style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
