import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'admin_home_screen.dart';
import 'admin_routes_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_edit_profile_screen.dart';
import 'login_screens.dart';

class AdminPassengersScreen extends StatefulWidget {
  const AdminPassengersScreen({super.key});

  @override
  State<AdminPassengersScreen> createState() =>
      _AdminPassengersScreenState();
}

class _AdminPassengersScreenState
    extends State<AdminPassengersScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final int _currentIndex = 3;

  List<dynamic> _passengers = [];
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadPassengers();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Bottom nav ────────────────────────────────────────────────
  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    Widget screen;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) =>
                FadeTransition(opacity: a, child: const AdminHomeScreen()),
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (r) => false,
        );
        return;
      case 1:
        screen = const AdminRoutesScreen();
        break;
      case 2:
        screen = const AdminDriversScreen();
        break;
      case 4:
        screen = const AdminEditProfileScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            FadeTransition(opacity: a, child: screen),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ── Logout dialog ─────────────────────────────────────────────
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
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(alignment: Alignment.center, children: [
                Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        shape: BoxShape.circle)),
                Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        shape: BoxShape.circle)),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 22),
                ),
              ]),
              const SizedBox(height: 20),
              const Text('Logging Out?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Text('Would you like to logout from\nEasy Ride?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.5)),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
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
                opacity: animation, child: const LoginScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    }
  }

  // ── Load passengers ───────────────────────────────────────────
  Future<void> _loadPassengers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/admin/passengers');
      setState(() {
        _passengers = response['passengers'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Add / Edit passenger dialog ───────────────────────────────
  void _showPassengerDialog({dynamic passenger}) {
    final isEdit = passenger != null;
    final nameCtrl =
        TextEditingController(text: passenger?['name'] ?? '');
    final emailCtrl =
        TextEditingController(text: passenger?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    final phoneCtrl =
        TextEditingController(text: passenger?['phone'] ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      shape: BoxShape.circle),
                  child: Icon(
                      isEdit
                          ? Icons.edit_rounded
                          : Icons.person_add_rounded,
                      color: Colors.yellow[800],
                      size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  isEdit ? 'Edit Passenger' : 'Add New Passenger',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // Full Name
                _dialogField(
                  controller: nameCtrl,
                  label: 'Full Name',
                  hint: 'e.g. Tenzin Wangchuk',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF1565C0),
                ),
                const SizedBox(height: 12),

                // Email (add-only)
                if (!isEdit) ...[
                  _dialogField(
                    controller: emailCtrl,
                    label: 'Email',
                    hint: 'e.g. tenzin@email.com',
                    icon: Icons.email_rounded,
                    iconColor: const Color(0xFF00695C),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Password (add-only)
                  _dialogField(
                    controller: passwordCtrl,
                    label: 'Password',
                    icon: Icons.lock_rounded,
                    iconColor: const Color(0xFF6A1B9A),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                ],

                // Phone
                _dialogField(
                  controller: phoneCtrl,
                  label: 'Phone Number',
                  hint: 'e.g. +975 17 123456',
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.black54,
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            (!isEdit &&
                                (emailCtrl.text.trim().isEmpty ||
                                    passwordCtrl.text.isEmpty))) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content:
                                const Text('Please fill all fields'),
                            backgroundColor: Colors.grey[800],
                          ));
                          return;
                        }
                        try {
                          if (isEdit) {
                            await _apiService.put(
                                '/admin/passengers/${passenger['id']}',
                                {
                                  'name': nameCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                });
                          } else {
                            await _apiService
                                .post('/admin/passengers', {
                              'name': nameCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'password': passwordCtrl.text,
                              'phone': phoneCtrl.text.trim(),
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadPassengers();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(isEdit
                                  ? 'Passenger updated!'
                                  : 'Passenger added!'),
                              backgroundColor: Colors.yellow[800],
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.grey[800],
                            ));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[800],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          isEdit ? 'Update' : 'Add Passenger',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete dialog ─────────────────────────────────────────────
  Future<void> _deletePassenger(dynamic passenger) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red[400], size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Delete Passenger',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                'Delete ${passenger['name']}?\nThis will also remove all their bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService
            .delete('/admin/passengers/${passenger['id']}');
        _loadPassengers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Passenger deleted'),
            backgroundColor: Colors.grey[800],
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.grey[800],
          ));
        }
      }
    }
  }

  // ── Dialog field helper ───────────────────────────────────────
  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.yellow[800]!, width: 2),
        ),
      ),
    );
  }

  // ── Date formatter ────────────────────────────────────────────
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),

      // ── APP BAR ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/taxi_logo.png',
                width: 36, height: 36, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('Easy Ride',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: 0.3)),
          ],
        ),
        actions: [
          InkWell(
            onTap: _loadPassengers,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.refresh_rounded,
                  color: Colors.grey[600], size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
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
                    Text('Logout',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BOTTOM NAV ────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(
                  color: Colors.grey.shade100, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.route_outlined),
              activeIcon: Icon(Icons.route_rounded),
              label: 'Routes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.drive_eta_outlined),
              activeIcon: Icon(Icons.drive_eta_rounded),
              label: 'Drivers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Passengers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),

      // ── FAB ───────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPassengerDialog(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Passenger',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.yellow[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // ── BODY ─────────────────────────────────────────────
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.yellow[800]!),
              ),
            )
          : _passengers.isEmpty
              ? FadeTransition(
                  opacity: _fadeAnim,
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle),
                          child: Icon(Icons.people_rounded,
                              size: 38,
                              color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 16),
                        Text('No passengers yet',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500])),
                        const SizedBox(height: 6),
                        Text('Tap + Add Passenger to create one',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400])),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: RefreshIndicator(
                    color: Colors.yellow[800],
                    onRefresh: _loadPassengers,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 100),
                      itemCount: _passengers.length,
                      itemBuilder: (context, index) =>
                          _buildPassengerCard(
                              _passengers[index]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildPassengerCard(dynamic passenger) {
    final profilePhoto = passenger['profile_photo'];
    final totalRides = passenger['total_rides'] ?? 0;
    final name = passenger['name'] ?? '';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────
            Row(
              children: [
                // Avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellow[50],
                    border: Border.all(
                        color: Colors.yellow[200]!, width: 1.5),
                  ),
                  child: profilePhoto != null
                      ? ClipOval(
                          child: Image.network(
                            profilePhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatarFallback(initials),
                          ),
                        )
                      : _avatarFallback(initials),
                ),
                const SizedBox(width: 14),

                // Name + email
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(passenger['email'] ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),

                // Rides badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF90CAF9)),
                  ),
                  child: Text(
                    '$totalRides rides',
                    style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            Divider(height: 20, color: Colors.grey.shade100),

            // ── Info row ─────────────────────────────────
            Row(
              children: [
                Icon(Icons.phone_rounded,
                    size: 14, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(passenger['phone'] ?? 'N/A',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 18),
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(
                  _formatDate(passenger['created_at'] ?? ''),
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            Divider(height: 20, color: Colors.grey.shade100),

            // ── Action buttons ───────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showPassengerDialog(passenger: passenger),
                  icon: Icon(Icons.edit_rounded,
                      size: 15, color: Colors.yellow[800]),
                  label: Text('Edit',
                      style: TextStyle(
                          color: Colors.yellow[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: Colors.yellow[200]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deletePassenger(passenger),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 15, color: Colors.red[400]),
                  label: Text('Delete',
                      style: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String initials) {
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
            color: Colors.yellow[800],
            fontWeight: FontWeight.w800,
            fontSize: 18),
      ),
    );
  }
}