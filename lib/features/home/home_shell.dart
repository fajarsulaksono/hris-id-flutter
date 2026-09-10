import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../attendance/presentation/attendance_screen.dart';
import '../auth/application/auth_controller.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../leave/presentation/leave_screen.dart';
import '../payroll/presentation/payroll_screen.dart';
import '../profile/presentation/profile_screen.dart';

/// Navigator utama untuk pengguna yang sudah login.
///
/// Menu ditampilkan role-aware berdasarkan ability dari `/auth/me`
/// (mirror `Security::can` web). Bila profil belum termuat (offline),
/// seluruh menu ditampilkan sebagai fallback.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    bool canShow(String ability) => user?.hasAbility(ability) ?? true;

    final showAttendance =
        canShow('view_attendance') || canShow('view_my_attendance');
    final showLeave = canShow('view_leave');
    final showPayroll = canShow('view_payroll');

    final pages = <Widget>[
      const DashboardScreen(),
      if (showAttendance) const AttendanceScreen(),
      if (showLeave) const LeaveScreen(),
      if (showPayroll) const PayrollScreen(),
      const ProfileScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Beranda',
      ),
      if (showAttendance)
        const NavigationDestination(
          icon: Icon(Icons.access_time_outlined),
          selectedIcon: Icon(Icons.access_time),
          label: 'Absensi',
        ),
      if (showLeave)
        const NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available),
          label: 'Cuti',
        ),
      if (showPayroll)
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Gaji',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: destinations,
      ),
    );
  }
}