import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import 'driver_home_screen.dart';
import 'driver_available_rides_screen.dart';
import 'driver_my_rides_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_edit_profile_screen.dart';
import 'driver_payment_details_screen.dart';
import 'change_password_screen.dart';
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
    with SingleTickerProviderStateMixin {
  final int _currentIndex = 4;
  int _photoKey = DateTime.now().millisecondsSinceEpoch;

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
      Provider.of<DriverProvider>(context, listen: false).getProfile();
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
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverEarningsScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        break;
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dp = Provider.of<DriverProvider>(context);
    final user = authProvider.user;
    final profile = dp.driverProfile;
    final totalPending = dp.nowBookings.length + dp.scheduledBookings.length;

    final double avgRating = double.tryParse(profile?['average_rating']?.toString() ?? '0') ?? 0.0;
    final int totalRatings = int.tryParse(profile?['total_ratings']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('Easy Ride',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: 0.3)),
          ]),
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
      body: user == null
          ? Center(child: Text('No user data', style: TextStyle(color: Colors.grey[400])))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                    // ── PROFILE CARD ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.yellow[700]!, width: 2.5),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.yellow[800],
                            child: user.profilePhoto != null
                                ? ClipOval(
                                    child: Image.network(
                                      '${user.profilePhoto!}?t=$_photoKey',
                                      width: 88, height: 88, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, size: 44, color: Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 44, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(user.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.2)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.drive_eta_outlined, size: 13, color: Color(0xFF2E7D32)),
                            SizedBox(width: 5),
                            Text('Driver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                          ]),
                        ),
                        const SizedBox(height: 10),
                        _AvailabilityBadge(status: dp.driverStatus),

                        // ✅ Star Rating Section
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.yellow[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.yellow[200]!),
                          ),
                          child: Column(children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              ...List.generate(5, (i) {
                                if (avgRating >= i + 1) return Icon(Icons.star_rounded, color: Colors.yellow[800], size: 26);
                                else if (avgRating >= i + 0.5) return Icon(Icons.star_half_rounded, color: Colors.yellow[800], size: 26);
                                else return Icon(Icons.star_outline_rounded, color: Colors.grey[300], size: 26);
                              }),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              totalRatings > 0
                                  ? '${avgRating.toStringAsFixed(1)} out of 5  •  $totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'}'
                                  : 'No ratings yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: totalRatings > 0 ? Colors.yellow[900] : Colors.grey[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    _InfoSection(children: [
                      _InfoRow(icon: Icons.mail_outline_rounded, label: 'Email', value: user.email, isFirst: true),
                      Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                      _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phone ?? 'Not provided', isFirst: false),
                    ]),

                    const SizedBox(height: 16),

                    if (profile != null) ...[
                      _InfoSection(children: [
                        _InfoRow(icon: Icons.directions_car_outlined, label: 'Vehicle Type', value: profile['vehicle_type']?.toString() ?? 'Not set', isFirst: true),
                        Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                        _InfoRow(icon: Icons.confirmation_number_outlined, label: 'Vehicle Number', value: profile['vehicle_number']?.toString() ?? 'Not set', isFirst: false),
                        Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                        _InfoRow(icon: Icons.card_membership_outlined, label: 'License Number', value: profile['license_number']?.toString() ?? 'Not set', isFirst: false),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    if (profile != null &&
                        ((profile['account_number']?.toString() ?? '').isNotEmpty ||
                            (profile['mobile_payment_number']?.toString() ?? '').isNotEmpty ||
                            profile['qr_code_image'] != null)) ...[
                      _InfoSection(children: [
                        if ((profile['account_number']?.toString() ?? '').isNotEmpty) ...[
                          _InfoRow(icon: Icons.account_balance_outlined, label: 'Account Number', value: profile['account_number'].toString(), isFirst: true),
                          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                        ],
                        if ((profile['mobile_payment_number']?.toString() ?? '').isNotEmpty) ...[
                          _InfoRow(
                            icon: Icons.phone_android_outlined,
                            label: 'Mobile Payment',
                            value: profile['mobile_payment_number'].toString(),
                            isFirst: (profile['account_number']?.toString() ?? '').isEmpty,
                          ),
                          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                        ],
                        if (profile['qr_code_image'] != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('QR Code', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  profile['qr_code_image'],
                                  width: 120, height: 120, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120, height: 120,
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Icons.qr_code_rounded, size: 48, color: Colors.grey[300]),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    _InfoSection(children: [
                      _ActionRow(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profile',
                        iconBg: Colors.yellow[50]!,
                        iconColor: Colors.yellow[800]!,
                        isFirst: true,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEditProfileScreen()));
                          if (mounted) {
                            await Provider.of<AuthProvider>(context, listen: false).loadUserProfile();
                            await Provider.of<DriverProvider>(context, listen: false).getProfile();
                            setState(() => _photoKey = DateTime.now().millisecondsSinceEpoch);
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                      _ActionRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        iconBg: Colors.orange[50]!,
                        iconColor: Colors.orange[700]!,
                        isFirst: false,
                        isLast: false,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen()));
                        },
                      ),
                      Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                      _ActionRow(
                        icon: Icons.payment_rounded,
                        label: 'Payment Details',
                        iconBg: Colors.blue[50]!,
                        iconColor: Colors.blue[700]!,
                        isFirst: false,
                        isLast: false,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPaymentDetailsScreen()));
                        },
                      ),
                      Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                      _ActionRow(
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        iconBg: Colors.red[50]!,
                        iconColor: Colors.red[400]!,
                        isFirst: false,
                        isLast: true,
                        onTap: _confirmLogout,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    Center(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.local_taxi, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 5),
                        Text('Online Taxi Service', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final String status;
  const _AvailabilityBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color; String label; IconData icon;
    switch (status) {
      case 'available': color = const Color(0xFF2E7D32); label = 'Online'; icon = Icons.wifi_rounded; break;
      case 'booked': color = const Color(0xFFE65100); label = 'On a Ride'; icon = Icons.directions_car_rounded; break;
      default: color = Colors.grey; label = 'Offline'; icon = Icons.wifi_off_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<Widget> children;
  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 12, 16, 12),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.grey[500], size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon, required this.label, required this.iconBg,
    required this.iconColor, required this.isFirst, required this.onTap, this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(18) : Radius.zero,
        topRight: isFirst ? const Radius.circular(18) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(18) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 12, 16, isLast ? 16 : 12),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
        ]),
      ),
    );
  }
}