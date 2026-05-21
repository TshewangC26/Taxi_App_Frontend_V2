import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import 'driver_available_rides_screen.dart';
import 'driver_my_rides_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_payment_details_screen.dart';
import 'driver_profile_screen.dart';
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
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()));
      return;
    }
  }

  // ── Hamburger menu bottom sheet ───────────────────────────────
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
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Contact Us ──
            _menuItem(
              icon: Icons.headset_mic_rounded,
              iconColor: Colors.yellow[800]!,
              iconBg: Colors.yellow[50]!,
              title: 'Contact Us',
              subtitle: 'Get in touch with our support team',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ContactUsScreen()));
              },
            ),
            Divider(height: 1, color: Colors.grey.shade100),

            // ── About Us ──
            _menuItem(
              icon: Icons.info_outline_rounded,
              iconColor: Colors.blue[700]!,
              iconBg: Colors.blue[50]!,
              title: 'About Us',
              subtitle: 'Learn more about Easy Ride',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()));
              },
            ),
            Divider(height: 1, color: Colors.grey.shade100),

            // ── Logout ──
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
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
        ]),
      ),
    );
  }

  // ── Logout confirmation dialog ────────────────────────────────
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
              Container(width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62,
                  decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('Easy Ride',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: 0.3)),
          ],
        ),
        actions: [
          // ✅ Hamburger menu icon instead of Logout button
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

                const SizedBox(height: 24),

                // ── QUICK ACTIONS ─────────────────────────────
                const _SectionLabel(title: 'Quick Actions'),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.list_alt_rounded,
                      label: 'Available\nRides',
                      iconColor: Colors.white,
                      bgColor: Colors.yellow[800]!,
                      badge: totalPending,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DriverAvailableRidesScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.history_rounded,
                      label: 'My Rides',
                      iconColor: Colors.white,
                      bgColor: const Color(0xFF455A64),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DriverMyRidesScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Earnings',
                      iconColor: Colors.white,
                      bgColor: const Color(0xFF00695C),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DriverEarningsScreen())),
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.payment_rounded,
                      label: 'Payment\nDetails',
                      iconColor: Colors.white,
                      bgColor: const Color(0xFF283593),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DriverPaymentDetailsScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      iconColor: Colors.white,
                      bgColor: const Color(0xFF546E7A),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DriverProfileScreen())),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: 0.1));
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final int badge;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            if (badge > 0)
              Positioned(top: -5, right: -5,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                      color: Colors.yellow[800], shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5)),
                  child: Center(child: Text('$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                )),
          ]),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}