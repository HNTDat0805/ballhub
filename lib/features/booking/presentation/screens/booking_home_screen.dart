import 'package:flutter/material.dart';
import '../../../../core/auth/auth_context.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api_booking_repository.dart';
import '../../data/booking_repository.dart';
import '../controllers/booking_controllers.dart';
import 'field_list_screen.dart';
import 'my_bookings_screen.dart';
import 'owner_bookings_screen.dart';
import 'owner_dashboard_screen.dart';
import 'owner_fields_screen.dart';

/// Dashboard chính cho Ballhub — màn hình Home tích hợp booking
class BookingHomeScreen extends StatefulWidget {
  final BookingRepository? repository;

  const BookingHomeScreen({super.key, this.repository});

  @override
  State<BookingHomeScreen> createState() => _BookingHomeScreenState();
}

class _BookingHomeScreenState extends State<BookingHomeScreen> {
  late final BookingRepository _repo;
  late final OwnerBookingController _ownerCtrl;
  late final BookingListController _userCtrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiBookingRepository();
    final user = AuthContext.instance.currentUser;

    if (user.isFieldOwner) {
      _ownerCtrl = OwnerBookingController(repository: _repo);
      _ownerCtrl.addListener(_onUpdate);
      _ownerCtrl.loadOwnerBookings();
    } else {
      _userCtrl = BookingListController(repository: _repo);
      _userCtrl.addListener(_onUpdate);
      _userCtrl.loadMyBookings();
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final user = AuthContext.instance.currentUser;
    if (user.isFieldOwner) {
      _ownerCtrl.removeListener(_onUpdate);
      _ownerCtrl.dispose();
    } else {
      _userCtrl.removeListener(_onUpdate);
      _userCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthContext.instance.currentUser;

    // Build screens and nav items based on role
    final (screens, navItems) = user.isFieldOwner
        ? _buildOwnerNav()
        : _buildUserNav();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: navItems,
      ),
    );
  }

  (List<Widget>, List<NavigationDestination>) _buildUserNav() {
    return (
      [
        FieldListScreen(repository: _repo),
        MyBookingsScreen(repository: _repo),
        _ProfileTab(),
      ],
      const [
        NavigationDestination(
          icon: Icon(Icons.sports_soccer_outlined),
          selectedIcon: Icon(Icons.sports_soccer_rounded),
          label: 'Tìm sân',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today_rounded),
          label: 'Đặt sân của tôi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Tài khoản',
        ),
      ],
    );
  }

  (List<Widget>, List<NavigationDestination>) _buildOwnerNav() {
    return (
      [
        OwnerDashboardScreen(repository: _repo),
        OwnerFieldsScreen(repository: _repo),
        OwnerBookingsScreen(repository: _repo),
        _ProfileTab(),
      ],
      const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business_rounded),
          label: 'Sân của tôi',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note_rounded),
          label: 'Đặt sân',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileTab — Tab tài khoản với role switcher (dev only)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final user = AuthContext.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(user.email, style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            user.role.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Chuyển tài khoản (Development)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // User switcher
          ...AuthContext.sampleUsers.map((sampleUser) {
            final isActive = sampleUser.id == user.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.05) : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    sampleUser.name[0].toUpperCase(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(sampleUser.name, style: const TextStyle(fontSize: 14)),
                subtitle: Text(sampleUser.role.displayName, style: const TextStyle(fontSize: 12)),
                trailing: isActive
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen)
                    : const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.textSecondary),
                onTap: isActive
                    ? null
                    : () {
                        AuthContext.instance.switchUser(sampleUser);
                        setState(() {});
                        // Show restart hint
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã chuyển sang ${sampleUser.name}. Quay lại màn hình chính để cập nhật UI.'),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // App info
          const ListTile(
            leading: Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
            title: Text('Phiên bản', style: TextStyle(fontSize: 14)),
            trailing: Text('v1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          const ListTile(
            leading: Icon(Icons.sports_soccer_rounded, color: AppTheme.primaryGreen),
            title: Text('Ballhub - Đặt sân bóng', style: TextStyle(fontSize: 14)),
            subtitle: Text('Kết nối sân bóng và cộng đồng thể thao'),
          ),
        ],
      ),
    );
  }
}
