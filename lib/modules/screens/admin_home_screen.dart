import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'admin_routes_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_passengers_screen.dart';
import 'admin_edit_profile_screen.dart';
import 'admin_vehicle_types_screen.dart';
import 'login_screens.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final int _currentIndex = 0;

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

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    Widget screen;
    switch (index) {
      case 1:
        screen = const AdminRoutesScreen();
        break;
      case 2:
        screen = const AdminDriversScreen();
        break;
      case 3:
        screen = const AdminPassengersScreen();
        break;
      case 4:
        screen = const AdminEditProfileScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: screen),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle)),
              Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 20),
            const Text('Logging Out?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Would you like to logout from\nEasy Ride?', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), foregroundColor: Colors.black54),
                child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Yes, Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              )),
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
          PageRouteBuilder(pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const LoginScreen()),
              transitionDuration: const Duration(milliseconds: 500)), (route) => false);
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Stack(alignment: Alignment.center, children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle)),
                  Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle)),
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22)),
                ]),
                const SizedBox(height: 18),
                const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 6),
                Text('Update your admin password', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 24),
                _passwordField(controller: currentCtrl, label: 'Current Password', show: showCurrent,
                    onToggle: () => setDialogState(() => showCurrent = !showCurrent)),
                const SizedBox(height: 12),
                _passwordField(controller: newCtrl, label: 'New Password', show: showNew,
                    onToggle: () => setDialogState(() => showNew = !showNew)),
                const SizedBox(height: 12),
                _passwordField(controller: confirmCtrl, label: 'Confirm New Password', show: showConfirm,
                    onToggle: () => setDialogState(() => showConfirm = !showConfirm)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: Colors.black54),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Please fill all fields'), backgroundColor: Colors.grey[800]));
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('New passwords do not match!'), backgroundColor: Colors.grey[800]));
                        return;
                      }
                      if (newCtrl.text.length < 12) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Password must be at least 12 characters'), backgroundColor: Colors.grey[800]));
                        return;
                      }
                      try {
                        await _apiService.post('/change-password', {
                          'current_password': currentCtrl.text,
                          'new_password': newCtrl.text,
                          'confirm_password': confirmCtrl.text,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Password changed successfully!'), backgroundColor: Colors.yellow[800]));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Failed: Wrong current password!'), backgroundColor: Colors.grey[800]));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                        elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.yellow[800], size: 20),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey[400], size: 18),
          onPressed: onToggle,
        ),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: false,
        titleSpacing: 20, automaticallyImplyLeading: false,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Text('Easy Ride', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: 0.3)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _confirmLogout, borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.logout_rounded, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 5),
                  Text('Logout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                ]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex, onTap: _onNavTap,
          type: BottomNavigationBarType.fixed, backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800], unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route_rounded), label: 'Routes'),
            BottomNavigationBarItem(icon: Icon(Icons.drive_eta_outlined), activeIcon: Icon(Icons.drive_eta_rounded), label: 'Drivers'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'Passengers'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── PROFILE CARD ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.yellow[700]!, width: 2.5)),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.yellow[800],
                        backgroundImage: user?.profilePhoto != null
                            ? NetworkImage('${user!.profilePhoto!}?t=${DateTime.now().millisecondsSinceEpoch}')
                            : null,
                        child: user?.profilePhoto == null
                            ? const Icon(Icons.admin_panel_settings_rounded, size: 26, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome back', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(user?.name ?? 'Admin',
                          style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      Text(user?.email ?? '',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12), overflow: TextOverflow.ellipsis),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.yellow[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.yellow[200]!)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.shield_rounded, size: 12, color: Colors.yellow[800]),
                        const SizedBox(width: 4),
                        Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.yellow[800])),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── SECTION LABEL ─────────────────────────
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 10),
                  const Text('Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                ]),

                const SizedBox(height: 14),

                // ── MANAGEMENT GRID ───────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _buildMenuCard(
                      icon: Icons.route_rounded,
                      label: 'Routes',
                      sublabel: 'Manage routes & prices',
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      onTap: () => _onNavTap(1),
                    ),
                    _buildMenuCard(
                      icon: Icons.drive_eta_rounded,
                      label: 'Drivers',
                      sublabel: 'Manage drivers',
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () => _onNavTap(2),
                    ),
                    _buildMenuCard(
                      icon: Icons.people_rounded,
                      label: 'Passengers',
                      sublabel: 'Manage passengers',
                      iconBg: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFE65100),
                      onTap: () => _onNavTap(3),
                    ),
                    _buildMenuCard(
                      icon: Icons.lock_rounded,
                      label: 'Password',
                      sublabel: 'Update admin password',
                      iconBg: Colors.yellow[50]!,
                      iconColor: Colors.yellow[800]!,
                      onTap: _showChangePasswordDialog,
                    ),
                    // ✅ New Vehicle Types card
                    _buildMenuCard(
                      icon: Icons.directions_car_rounded,
                      label: 'Vehicle Types',
                      sublabel: 'Manage vehicle types',
                      iconBg: const Color(0xFFEDE7F6),
                      iconColor: const Color(0xFF4527A0),
                      onTap: () => Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const AdminVehicleTypesScreen()),
                        transitionDuration: const Duration(milliseconds: 300),
                      )),
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

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 3),
          Text(sublabel, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}