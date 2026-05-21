import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import 'driver_home_screen.dart';
import 'driver_available_rides_screen.dart';
import 'driver_my_rides_screen.dart';
import 'driver_profile_screen.dart';
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with SingleTickerProviderStateMixin {
  final int _currentIndex = 3;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false).getEarnings();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverHomeScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ), (r) => false);
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverAvailableRidesScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        break;
      case 2:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverMyRidesScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        break;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverProfileScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        break;
    }
  }

  // ✅ Hamburger menu
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
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
        ]),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
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
                    backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
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
            pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const LoginScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (r) => false,
        );
      }
    }
  }

  String _calculateAverage(dynamic totalEarnings, dynamic totalRides) {
    try {
      final earnings = double.parse(totalEarnings.toString());
      final rides = int.parse(totalRides.toString());
      if (rides == 0) return '0';
      return (earnings / rides).toStringAsFixed(2);
    } catch (_) { return '0'; }
  }

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DriverProvider>(context);
    final totalPending = dp.nowBookings.length + dp.scheduledBookings.length;

    final totalEarnings = dp.earnings?['total_earnings'] ?? '0';
    final totalRides = dp.earnings?['total_rides']?.toString() ?? '0';
    final avgPerRide = _calculateAverage(dp.earnings?['total_earnings'], dp.earnings?['total_rides']);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Text('Easy Ride',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: 0.3)),
        ]),
        actions: [
          InkWell(
            onTap: () => dp.getEarnings(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 20),
            ),
          ),
          // ✅ Hamburger menu
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
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
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
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
            const BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'My Rides'),
            const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Earnings'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      body: dp.isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                    // ── TOTAL EARNINGS HERO ───────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.yellow[800],
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_wallet_rounded, size: 32, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('Nu. $totalEarnings',
                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // ── STAT CARDS ────────────────────────
                    Row(children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_taxi_rounded,
                          label: 'Total Rides',
                          value: totalRides,
                          iconBg: Colors.yellow[50]!,
                          iconColor: Colors.yellow[800]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_up_rounded,
                          label: 'Avg per Ride',
                          value: 'Nu. $avgPerRide',
                          iconBg: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // ── SUMMARY CARD ──────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(9)),
                              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 15),
                            ),
                            const SizedBox(width: 10),
                            const Text('Earnings Summary',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                          ]),
                          const SizedBox(height: 18),
                          _SummaryRow(label: 'Total Rides Completed', value: totalRides),
                          Divider(height: 20, color: Colors.grey.shade100),
                          _SummaryRow(label: 'Total Earnings', value: 'Nu. $totalEarnings', valueColor: Colors.yellow[800], bold: true),
                          Divider(height: 20, color: Colors.grey.shade100),
                          _SummaryRow(label: 'Average per Ride', value: 'Nu. $avgPerRide'),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({required this.icon, required this.label, required this.value, required this.iconBg, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(height: 14),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow({required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      Text(value, style: TextStyle(
        color: valueColor ?? Colors.black87,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        fontSize: bold ? 15 : 13,
      )),
    ]);
  }
}