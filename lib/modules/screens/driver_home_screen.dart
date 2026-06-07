import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import 'driver_available_rides_screen.dart';
import 'driver_my_rides_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_payment_details_screen.dart';
import 'driver_profile_screen.dart' as profile;
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final int _currentIndex = 0;
  Timer? _countdownTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false).getProfile();
      Provider.of<DriverProvider>(context, listen: false).getAvailableBookings();
      Provider.of<DriverProvider>(context, listen: false).getMyRides();
    });

    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _getCountdown(String dateStr, String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final scheduledDateTime = DateTime.parse(dateStr).copyWith(hour: hour, minute: minute);
      final now = DateTime.now();
      final diff = scheduledDateTime.difference(now);
      if (diff.isNegative) return 'Time has passed';
      if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} left';
      if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} left';
      if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} left';
      return 'Starting now!';
    } catch (_) {
      return '';
    }
  }

  Color _getCountdownColor(String dateStr, String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final scheduledDateTime = DateTime.parse(dateStr).copyWith(hour: hour, minute: minute);
      final diff = scheduledDateTime.difference(DateTime.now());
      if (diff.inHours < 1) return Colors.red;
      if (diff.inHours < 3) return Colors.orange;
      return const Color(0xFF2E7D32);
    } catch (_) {
      return Colors.grey;
    }
  }

  String _formatScheduledDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) { return dateStr; }
  }

  String _formatScheduledTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) { return timeStr; }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverAvailableRidesScreen()));
      return;
    }
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverMyRidesScreen()));
      return;
    }
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen()));
      return;
    }
    if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const profile.DriverProfileScreen()));
      return;
    }
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            _menuItem(
              icon: Icons.headset_mic_rounded,
              iconColor: Colors.yellow[800]!,
              iconBg: Colors.yellow[50]!,
              title: 'Contact Us',
              subtitle: 'Get in touch with our support team',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()));
              },
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            _menuItem(
              icon: Icons.info_outline_rounded,
              iconColor: Colors.blue[700]!,
              iconBg: Colors.blue[50]!,
              title: 'About Us',
              subtitle: 'Learn more about Easy Ride',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen()));
              },
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            _menuItem(
              icon: Icons.logout_rounded,
              iconColor: Colors.red[400]!,
              iconBg: Colors.red[50]!,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: () {
                Navigator.pop(ctx);
                _confirmLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
        ]),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle)),
              Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 20),
            const Text('Logging Out?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.2)),
            const SizedBox(height: 8),
            Text('Would you like to logout from\nEasy Ride?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: Colors.black54,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Yes, Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
                opacity: animation, child: const LoginScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFF2E7D32);
      case 'booked':    return const Color(0xFFE65100);
      case 'offline':   return Colors.grey;
      default:          return Colors.grey;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'available': return const Color(0xFFE8F5E9);
      case 'booked':    return const Color(0xFFFFF3E0);
      case 'offline':   return Colors.grey[100]!;
      default:          return Colors.grey[100]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available': return Icons.wifi_rounded;
      case 'booked':    return Icons.directions_car_rounded;
      case 'offline':   return Icons.wifi_off_rounded;
      default:          return Icons.wifi_off_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'available': return 'Online — Accepting rides';
      case 'booked':    return 'Booked — On a ride';
      case 'offline':   return 'Offline — Not accepting rides';
      default:          return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider   = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);
    final user           = authProvider.user;
    final status         = driverProvider.driverStatus;
    final isOffline      = status == 'offline';
    final profilePhoto   = user?.profilePhoto;
    final totalPending   = driverProvider.nowBookings.length + driverProvider.scheduledBookings.length;

    // ✅ Only show ACCEPTED scheduled rides in reminder (not pending)
    final seen = <int>{};
    final scheduledBookings = driverProvider.myRides.where((b) {
      final id = b['id'] as int? ?? 0;
      final bStatus = b['status'] ?? '';
      final bType = b['booking_type'] ?? '';
      if (seen.contains(id)) return false;
      if (bType != 'scheduled') return false;
      if (bStatus != 'accepted' && bStatus != 'in_progress') return false;
      seen.add(id);
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => FadeTransition(
                    opacity: animation, child: const DriverHomeScreen()),
                transitionDuration: const Duration(milliseconds: 300),
              ),
              (route) => false,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
              const SizedBox(width: 10),
              const Text('Easy Ride',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: 0.3)),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _openMenu,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(Icons.menu_rounded, color: Colors.grey[700], size: 22),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.list_alt_outlined),
                if (totalPending > 0)
                  Positioned(top: -4, right: -6,
                    child: Container(width: 14, height: 14,
                        decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                        child: Center(child: Text('$totalPending',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))))),
              ]),
              activeIcon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.list_alt_rounded),
                if (totalPending > 0)
                  Positioned(top: -4, right: -6,
                    child: Container(width: 14, height: 14,
                        decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                        child: Center(child: Text('$totalPending',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))))),
              ]),
              label: 'Rides',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'My Rides'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Earnings'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── PROFILE CARD ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.yellow[700]!, width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.yellow[800],
                        backgroundImage: profilePhoto != null
                            ? NetworkImage('$profilePhoto?t=${DateTime.now().millisecondsSinceEpoch}')
                            : null,
                        child: profilePhoto == null
                            ? const Icon(Icons.person, size: 28, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Welcome back', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(user?.name ?? 'Driver',
                            style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Text(user?.email ?? '',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.drive_eta_outlined, size: 12, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text('Driver',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── AVAILABILITY TOGGLE CARD ──────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: _getStatusBg(status),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Availability',
                            style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(_getStatusLabel(status),
                            style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.w500)),
                        if (status == 'booked')
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text('Cannot toggle while on a ride',
                                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                          ),
                      ]),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: !isOffline,
                        activeColor: const Color(0xFF2E7D32),
                        activeTrackColor: const Color(0xFF2E7D32).withOpacity(0.3),
                        inactiveThumbColor: Colors.grey[400],
                        inactiveTrackColor: Colors.grey[200],
                        onChanged: status == 'booked'
                            ? null
                            : (value) async {
                                final success = await driverProvider.toggleAvailability();
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        driverProvider.driverStatus == 'available'
                                            ? 'You are now Online!'
                                            : 'You are now Offline!',
                                      ),
                                      backgroundColor: driverProvider.driverStatus == 'available'
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey[800],
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ]),
                ),

                // ── PENDING BOOKINGS ALERT ────────────────────
                if (totalPending > 0) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DriverAvailableRidesScreen())),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.yellow[200]!),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: Colors.yellow[800], borderRadius: BorderRadius.circular(11)),
                          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$totalPending pending booking${totalPending > 1 ? 's' : ''}',
                                style: TextStyle(color: Colors.yellow[900], fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('Tap to view available rides',
                                style: TextStyle(color: Colors.yellow[800], fontSize: 12)),
                          ]),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.yellow[700], size: 22),
                      ]),
                    ),
                  ),
                ],

                // ── SCHEDULED BOOKINGS REMINDER ───────────────
                const SizedBox(height: 24),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 10),
                  const Text('Scheduled Rides',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                ]),
                const SizedBox(height: 12),

                if (scheduledBookings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(children: [
                      Icon(Icons.calendar_today_rounded, size: 36, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text('No scheduled rides',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                      const SizedBox(height: 4),
                      Text('Accepted scheduled rides will appear here',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ]),
                  )
                else
                  ...scheduledBookings.map((booking) {
                    final dateStr = booking['scheduled_date'] ?? '';
                    final timeStr = booking['scheduled_time'] ?? '';
                    final countdown = _getCountdown(dateStr, timeStr);
                    final countdownColor = _getCountdownColor(dateStr, timeStr);
                    final pickup = booking['pickup_location'] ?? '';
                    final dropoff = booking['dropoff_location'] ?? '';
                    final passengerName = booking['passenger']?['name'] ?? 'Passenger';

                    return InkWell(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DriverMyRidesScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Row(children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle),
                                child: Icon(Icons.person_rounded, color: Colors.yellow[800], size: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(passengerName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                            ]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: countdownColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: countdownColor.withOpacity(0.4)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.timer_rounded, size: 12, color: countdownColor),
                                const SizedBox(width: 4),
                                Text(countdown,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: countdownColor)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_rounded, color: Color(0xFF5E35B1), size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_formatScheduledDate(dateStr)}  •  ${_formatScheduledTime(timeStr)}',
                                  style: const TextStyle(color: Color(0xFF4527A0), fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Container(width: 8, height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pickup,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                overflow: TextOverflow.ellipsis)),
                          ]),
                          Padding(padding: const EdgeInsets.only(left: 3.5),
                              child: Container(width: 1, height: 10, color: Colors.grey.shade300)),
                          Row(children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(dropoff,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text('Tap to view ride details',
                                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]),
                          ]),
                        ]),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}