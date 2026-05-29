import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'admin_home_screen.dart';
import 'admin_routes_screen.dart';
import 'admin_passengers_screen.dart';
import 'admin_edit_profile_screen.dart';
import 'login_screens.dart';

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final int _currentIndex = 2;

  List<dynamic> _drivers = [];
  List<dynamic> _filteredDrivers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadDrivers();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filteredDrivers = _drivers
            .where((d) => (d['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchQuery))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Bottom nav ────────────────────────────────────────────────
  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => FadeTransition(
                opacity: a, child: const AdminHomeScreen()),
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (r) => false,
        );
        return;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(
              opacity: a, child: const AdminRoutesScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        return;
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(
              opacity: a, child: const AdminPassengersScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        return;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(
              opacity: a, child: const AdminEditProfileScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        return;
    }
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
                Container(width: 80, height: 80,
                    decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        shape: BoxShape.circle)),
                Container(width: 62, height: 62,
                    decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        shape: BoxShape.circle)),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 22),
                ),
              ]),
              const SizedBox(height: 20),
              const Text('Logging Out?',
                  style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Text('Would you like to logout from\nEasy Ride?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14,
                      color: Colors.grey[500], height: 1.5)),
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
                        style: TextStyle(fontSize: 15,
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
                        style: TextStyle(fontSize: 15,
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

  // ── Load drivers ──────────────────────────────────────────────
  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/admin/drivers');
      setState(() {
        _drivers = response['drivers'] ?? [];
        _filteredDrivers = _searchQuery.isEmpty
            ? List.from(_drivers)
            : _drivers
                .where((d) => (d['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Dialog field helper ───────────────────────────────────────
  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.yellow[800], size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
        ),
      ),
    );
  }

  Widget _vehicleDropdown(
      String value, void Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Vehicle Type',
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(Icons.directions_car_rounded,
            color: Colors.yellow[800], size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: '4-seater', child: Text('4-Seater')),
        DropdownMenuItem(value: '7-seater', child: Text('7-Seater')),
        DropdownMenuItem(value: '8-seater', child: Text('8-Seater')),
      ],
      onChanged: (v) => onChanged(v!),
    );
  }

  // ── Add driver dialog ─────────────────────────────────────────
  void _showAddDriverDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final vehicleNumCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    String vehicleType = '4-seater';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
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
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        shape: BoxShape.circle),
                    child: Icon(Icons.person_add_rounded,
                        color: Colors.yellow[800], size: 24),
                  ),
                  const SizedBox(height: 14),
                  const Text('Add New Driver',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 20),
                  _dialogField(controller: nameCtrl,
                      label: 'Full Name', icon: Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _dialogField(controller: emailCtrl,
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _dialogField(controller: passwordCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: true),
                  const SizedBox(height: 12),
                  _dialogField(controller: phoneCtrl,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _vehicleDropdown(vehicleType,
                      (v) => setDialogState(() => vehicleType = v)),
                  const SizedBox(height: 12),
                  _dialogField(controller: vehicleNumCtrl,
                      label: 'Vehicle Number',
                      icon: Icons.confirmation_number_outlined),
                  const SizedBox(height: 12),
                  _dialogField(controller: licenseCtrl,
                      label: 'License Number',
                      icon: Icons.card_membership_outlined),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.black54,
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty ||
                              emailCtrl.text.isEmpty ||
                              passwordCtrl.text.isEmpty ||
                              phoneCtrl.text.isEmpty ||
                              vehicleNumCtrl.text.isEmpty ||
                              licenseCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: const Text('Please fill all fields'),
                              backgroundColor: Colors.grey[800],
                            ));
                            return;
                          }
                          try {
                            await _apiService.post('/admin/drivers', {
                              'name': nameCtrl.text,
                              'email': emailCtrl.text,
                              'password': passwordCtrl.text,
                              'phone': phoneCtrl.text,
                              'vehicle_type': vehicleType,
                              'vehicle_number': vehicleNumCtrl.text,
                              'license_number': licenseCtrl.text,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadDrivers();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: const Text('Driver added!'),
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add Driver',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit driver dialog ────────────────────────────────────────
  void _showEditDriverDialog(dynamic driver) {
    final nameCtrl = TextEditingController(text: driver['name'] ?? '');
    final phoneCtrl = TextEditingController(text: driver['phone'] ?? '');
    final vehicleNumCtrl = TextEditingController(text: driver['vehicle_number'] ?? '');
    final licenseCtrl = TextEditingController(text: driver['license_number'] ?? '');
    String vehicleType = driver['vehicle_type'] ?? '4-seater';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
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
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        shape: BoxShape.circle),
                    child: Icon(Icons.edit_rounded,
                        color: Colors.yellow[800], size: 24),
                  ),
                  const SizedBox(height: 14),
                  const Text('Edit Driver',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 20),
                  _dialogField(controller: nameCtrl,
                      label: 'Full Name', icon: Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _dialogField(controller: phoneCtrl,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _vehicleDropdown(vehicleType,
                      (v) => setDialogState(() => vehicleType = v)),
                  const SizedBox(height: 12),
                  _dialogField(controller: vehicleNumCtrl,
                      label: 'Vehicle Number',
                      icon: Icons.confirmation_number_outlined),
                  const SizedBox(height: 12),
                  _dialogField(controller: licenseCtrl,
                      label: 'License Number',
                      icon: Icons.card_membership_outlined),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.black54,
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _apiService.put(
                                '/admin/drivers/${driver['id']}', {
                              'name': nameCtrl.text,
                              'phone': phoneCtrl.text,
                              'vehicle_type': vehicleType,
                              'vehicle_number': vehicleNumCtrl.text,
                              'license_number': licenseCtrl.text,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadDrivers();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: const Text('Driver updated!'),
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Update',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete dialog ─────────────────────────────────────────────
  Future<void> _deleteDriver(dynamic driver) async {
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
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red[400], size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Delete Driver',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                'Delete driver ${driver['name']}?\nThis will also delete all their bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14,
                    color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 14,
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontSize: 14,
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
        await _apiService.delete('/admin/drivers/${driver['id']}');
        _loadDrivers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Driver deleted'),
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

  // ── Status helpers ────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFF2E7D32);
      case 'booked':    return const Color(0xFFE65100);
      default:          return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'available': return const Color(0xFFE8F5E9);
      case 'booked':    return const Color(0xFFFFF3E0);
      default:          return const Color(0xFFF5F5F5);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available': return 'Online';
      case 'booked':    return 'On a Ride';
      default:          return 'Offline';
    }
  }

  // ✅ Show license image dialog
  void _showLicenseImageDialog(dynamic driver) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.card_membership_outlined,
                      color: Colors.yellow[800], size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87)),
                      Text('License: ${driver['license_number'] ?? 'N/A'}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey[400], size: 22),
                ),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  driver['license_image'],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.yellow[800]!),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            color: Colors.grey[400], size: 40),
                        const SizedBox(height: 8),
                        Text('Image not available',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
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
                style: TextStyle(color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 19, letterSpacing: 0.3)),
          ],
        ),
        actions: [
          InkWell(
            onTap: _loadDrivers,
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
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: Colors.grey.shade100, width: 1)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDriverDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Driver',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.yellow[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search drivers by name...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.yellow[800], size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.grey[400], size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                  borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.yellow[800]!),
                    ),
                  )
                : _drivers.isEmpty
                    ? FadeTransition(
                        opacity: _fadeAnim,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle),
                                child: Icon(Icons.drive_eta_rounded,
                                    size: 38, color: Colors.grey[300]),
                              ),
                              const SizedBox(height: 16),
                              Text('No drivers yet',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[500])),
                              const SizedBox(height: 6),
                              Text('Tap + Add Driver to add one',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400])),
                            ],
                          ),
                        ),
                      )
                    : _filteredDrivers.isEmpty
                        ? FadeTransition(
                            opacity: _fadeAnim,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle),
                                    child: Icon(Icons.search_off_rounded,
                                        size: 38, color: Colors.grey[300]),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('No results found',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[500])),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No driver named "${_searchController.text}"',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnim,
                            child: RefreshIndicator(
                              color: Colors.yellow[800],
                              onRefresh: _loadDrivers,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 16, 16, 100),
                                itemCount: _filteredDrivers.length,
                                itemBuilder: (context, index) =>
                                    _buildDriverCard(_filteredDrivers[index]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(dynamic driver) {
    final status = driver['status'] ?? 'offline';
    final profilePhoto = driver['profile_photo'];
    final sc = _statusColor(status);
    final sb = _statusBg(status);

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
            Row(children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellow[300]!, width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.yellow[50],
                  backgroundImage: profilePhoto != null
                      ? NetworkImage(profilePhoto)
                      : null,
                  child: profilePhoto == null
                      ? Icon(Icons.person_rounded,
                          color: Colors.yellow[800], size: 24)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.black87)),
                    Text(driver['email'] ?? '',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sb,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withOpacity(0.4)),
                ),
                child: Text(_statusLabel(status),
                    style: TextStyle(
                        color: sc,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),

            Divider(height: 18, color: Colors.grey.shade100),

            // ── Info rows ────────────────────────────────
            Row(children: [
              Icon(Icons.phone_outlined, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(driver['phone'] ?? 'N/A',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(driver['vehicle_type'] ?? 'N/A',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.yellow[800],
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.confirmation_number_outlined,
                  size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(driver['vehicle_number'] ?? 'N/A',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(width: 16),
              Icon(Icons.card_membership_outlined,
                  size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(driver['license_number'] ?? 'N/A',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ]),

            // ✅ License image button
            if (driver['license_image'] != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showLicenseImageDialog(driver),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.yellow[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 14, color: Colors.yellow[800]),
                    const SizedBox(width: 6),
                    Text('View License Photo',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.yellow[800],
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: Colors.yellow[800]),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Action buttons ───────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDriverDialog(driver),
                  icon: Icon(Icons.edit_rounded,
                      size: 15, color: Colors.yellow[800]),
                  label: Text('Edit',
                      style: TextStyle(
                          color: Colors.yellow[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: Colors.yellow[200]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteDriver(driver),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 15, color: Colors.red[400]),
                  label: Text('Delete',
                      style: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
}