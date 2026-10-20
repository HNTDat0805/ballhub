import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';

class RoleSelectorWidget extends StatelessWidget {
  const RoleSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthContext.instance,
      builder: (context, _) {
        final current = AuthContext.instance.currentUser;
        return PopupMenuButton<AppUser>(
          tooltip: 'Chuyển đổi vai trò người dùng (Thử nghiệm phân quyền)',
          offset: const Offset(0, 48),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  current.isOrganizer
                      ? Icons.admin_panel_settings
                      : (current.isCaptain ? Icons.sports_soccer : Icons.person_outline),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    current.name.split(' ').last,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
              ],
            ),
          ),
          itemBuilder: (context) {
            return AuthContext.sampleUsers.map((user) {
              final isSelected = user.id == current.id;
              return PopupMenuItem<AppUser>(
                value: user,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? const Color(0xFF0F9D58) : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          user.role.displayName,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList();
          },
          onSelected: (user) {
            AuthContext.instance.switchUser(user);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã chuyển sang vai trò: ${user.name} (${user.role.displayName})'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
