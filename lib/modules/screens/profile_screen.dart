import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'passenger_home_screen.dart';
import 'book_ride_screen.dart';
import 'my_bookings_screen.dart';
import 'login_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Bottom nav handler ────────────────────────────────────────
  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const PassengerHomeScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
      return;
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const BookRideScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const MyBookingsScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.yellow[50], shape: BoxShape.circle),
                ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                      color: Colors.yellow[100], shape: BoxShape.circle),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: Colors.yellow[800], shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 22),
                ),
              ]),
              const SizedBox(height: 20),
              const Text(
                'Logging Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Would you like to logout from\nEasy Ride?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Yes, Logout',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const LoginScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    }
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'passenger': return Colors.yellow[800]!;
      case 'driver':    return const Color(0xFF2E7D32);
      case 'admin':     return const Color(0xFF6A1B9A);
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),

      // ── APP BAR ────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/taxi_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'Easy Ride',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _confirmLogout,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Colors.grey[600], size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BOTTOM NAVIGATION BAR ──────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_taxi_outlined),
              activeIcon: Icon(Icons.local_taxi_rounded),
              label: 'Book Ride',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),

      // ── BODY ───────────────────────────────────────────────
      body: user == null
          ? Center(
              child: Text('No user data',
                  style: TextStyle(color: Colors.grey[400])),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    children: [

                      // ── PROFILE HEADER CARD ───────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            // Avatar with yellow ring
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.yellow[700]!, width: 2.5),
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.yellow[800],
                                child: user.profilePhoto != null
                                    ? ClipOval(
                                        child: Image.network(
                                          '${user.profilePhoto!}?t=${DateTime.now().millisecondsSinceEpoch}',
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.person,
                                                  size: 44,
                                                  color: Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.person,
                                        size: 44, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // User type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getUserTypeColor(user.userType)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _getUserTypeColor(user.userType)
                                        .withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_outlined,
                                      size: 13,
                                      color:
                                          _getUserTypeColor(user.userType)),
                                  const SizedBox(width: 5),
                                  Text(
                                    user.userType[0].toUpperCase() +
                                        user.userType.substring(1),
                                    style: TextStyle(
                                      color: _getUserTypeColor(user.userType),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── INFO SECTION ──────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email',
                              value: user.email,
                              isFirst: true,
                            ),
                            Divider(
                                height: 1,
                                indent: 56,
                                color: Colors.grey.shade100),
                            _buildInfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: user.phone ?? 'Not provided',
                              isFirst: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── ACTIONS SECTION (no logout) ───────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            _buildActionRow(
                              icon: Icons.edit_outlined,
                              label: 'Edit Profile',
                              iconBg: Colors.yellow[50]!,
                              iconColor: Colors.yellow[800]!,
                              isFirst: true,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => EditProfileScreen()),
                                );
                                if (mounted) {
                                  await Provider.of<AuthProvider>(context,
                                          listen: false)
                                      .loadUserProfile();
                                }
                              },
                            ),
                            Divider(
                                height: 1,
                                indent: 56,
                                color: Colors.grey.shade100),
                            _buildActionRow(
                              icon: Icons.lock_outline_rounded,
                              label: 'Change Password',
                              iconBg: Colors.orange[50]!,
                              iconColor: Colors.orange[700]!,
                              isFirst: false,
                              isLast: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ChangePasswordScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Footer ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_taxi,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 5),
                          Text(
                            'Online Taxi Service',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Info row ──────────────────────────────────────────────────
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isFirst,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: isFirst ? 16 : 12,
        bottom: isFirst ? 12 : 16,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.grey[500], size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action row ────────────────────────────────────────────────
  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required bool isFirst,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(18) : Radius.zero,
        topRight: isFirst ? const Radius.circular(18) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(18) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isFirst ? 16 : 12,
          bottom: isLast ? 16 : 12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[300], size: 22),
          ],
        ),
      ),
    );
  }
}