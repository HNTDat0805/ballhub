import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Lựa chọn bộ lọc dùng cho [FilterSelectionModal]
class FilterOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const FilterOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

/// Modal Bottom Sheet chung cho các bộ lọc thả xuống (Dropdown/Picker)
class FilterSelectionModal<T> extends StatelessWidget {
  final String title;
  final List<FilterOption<T>> options;
  final T? selectedValue;

  const FilterSelectionModal({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
  });

  /// Hiển thị modal lựa chọn bộ lọc và trả về giá trị được chọn
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<FilterOption<T>> options,
    T? selectedValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FilterSelectionModal<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (ctx, idx) {
                  final opt = options[idx];
                  final isSelected = opt.value == selectedValue;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryDarkGreen : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: opt.subtitle != null
                        ? Text(
                            opt.subtitle!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryDarkGreen, size: 20)
                        : null,
                    onTap: () => Navigator.pop(context, opt.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
