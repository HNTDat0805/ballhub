import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/football_field.dart';
import '../controllers/booking_controllers.dart';
import '../widgets/booking_widgets.dart';
import 'owner_field_form_screen.dart';

/// Màn hình quản lý danh sách sân của chủ sân
class OwnerFieldsScreen extends StatefulWidget {
  final BookingRepository repository;

  const OwnerFieldsScreen({super.key, required this.repository});

  @override
  State<OwnerFieldsScreen> createState() => _OwnerFieldsScreenState();
}

class _OwnerFieldsScreenState extends State<OwnerFieldsScreen> {
  late final OwnerFieldController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OwnerFieldController(repository: widget.repository);
    _controller.addListener(_onUpdate);
    _loadMyFields();
  }

  void _loadMyFields() {
    final user = AuthContext.instance.currentUser;
    _controller.loadMyFields(user.id);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sân của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMyFields,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewField,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sân'),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const BookingLoadingState(message: 'Đang tải danh sách sân...');
    }

    if (_controller.errorMessage != null) {
      return BookingErrorState(
        message: _controller.errorMessage!,
        onRetry: _loadMyFields,
      );
    }

    if (_controller.fields.isEmpty) {
      return BookingEmptyState(
        title: 'Chưa có sân nào',
        subtitle: 'Tạo sân đầu tiên của bạn!',
        icon: Icons.add_business_rounded,
        actionLabel: 'Tạo sân ngay',
        onAction: _createNewField,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async => _loadMyFields(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        itemCount: _controller.fields.length,
        itemBuilder: (ctx, index) {
          final field = _controller.fields[index];
          return _OwnerFieldCard(
            field: field,
            onEdit: () => _editField(field),
            onStatusChange: (status) => _changeStatus(field, status),
          );
        },
      ),
    );
  }

  void _createNewField() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerFieldFormScreen(
          repository: widget.repository,
          onSaved: (field) {
            _loadMyFields();
          },
        ),
      ),
    );
  }

  void _editField(FootballField field) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerFieldFormScreen(
          repository: widget.repository,
          existingField: field,
          onSaved: (updated) {
            _loadMyFields();
          },
        ),
      ),
    );
  }

  Future<void> _changeStatus(FootballField field, String newStatus) async {
    final success = await _controller.updateStatus(field.id, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Cập nhật trạng thái sân thành công.' : (_controller.errorMessage ?? 'Lỗi.')),
          backgroundColor: success ? AppTheme.primaryGreen : AppTheme.dangerRed,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OwnerFieldCard
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerFieldCard extends StatelessWidget {
  final FootballField field;
  final VoidCallback? onEdit;
  final ValueChanged<String>? onStatusChange;

  const _OwnerFieldCard({
    required this.field,
    this.onEdit,
    this.onStatusChange,
  });

  static const _statusOptions = [
    ('active', 'Đang hoạt động', Icons.check_circle_rounded, AppTheme.primaryGreen),
    ('inactive', 'Tạm ngừng', Icons.pause_circle_rounded, AppTheme.textSecondary),
    ('maintenance', 'Bảo trì', Icons.construction_rounded, AppTheme.warningOrange),
    ('archived', 'Ẩn sân', Icons.archive_rounded, AppTheme.dangerRed),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    field.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                FieldStatusBadge(status: field.status),
              ],
            ),
            const SizedBox(height: 6),
            // Address
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    field.address,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Price + type
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${_fmtPrice(field.basePrice)} ${field.currency}/giờ',
                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.people_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(field.fieldType, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Action row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStatusMenu(context),
                    icon: const Icon(Icons.toggle_on_rounded, size: 15),
                    label: const Text('Trạng thái', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text('Đổi trạng thái sân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const Divider(),
            ..._statusOptions.map((opt) {
              final (status, label, icon, color) = opt;
              final isCurrent = field.status.name == status;
              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(label, style: TextStyle(color: isCurrent ? AppTheme.primaryGreen : null)),
                trailing: isCurrent ? const Icon(Icons.check_rounded, color: AppTheme.primaryGreen) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isCurrent) onStatusChange?.call(status);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _fmtPrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}
