import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'admin_home_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_passengers_screen.dart';
import 'admin_edit_profile_screen.dart';
import 'login_screens.dart';

class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final int _currentIndex = 1;

  List<dynamic> _routes = [];
  List<dynamic> _vehicleTypes = [];
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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Load routes + vehicle types together ─────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.get('/admin/routes'),
        _apiService.get('/vehicle-types'),
      ]);
      setState(() {
        _routes       = results[0]['routes'] ?? [];
        _vehicleTypes = results[1]['vehicle_types'] ?? [];
        _isLoading    = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRoutes() => _loadData();

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
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: screen),
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
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Would you like to logout from\nEasy Ride?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  foregroundColor: Colors.black54,
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
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
          PageRouteBuilder(
            pageBuilder: (_, animation, __) =>
                FadeTransition(opacity: animation, child: const LoginScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    }
  }

  // ── Add / Edit route dialog ───────────────────────────────────
  void _showRouteDialog({dynamic route}) {
    final isEdit     = route != null;
    final pickupCtrl = TextEditingController(text: route?['pickup_location'] ?? '');
    final dropoffCtrl = TextEditingController(text: route?['dropoff_location'] ?? '');
    bool isActive    = route?['is_active'] ?? true;

    // ✅ Build price controllers dynamically from vehicle types
    final Map<String, TextEditingController> priceControllers = {};
    for (final vt in _vehicleTypes) {
      final name          = vt['name'].toString();
      final existingPrice = route?['prices']?[name]?['price']?.toString() ?? '';
      priceControllers[name] = TextEditingController(text: existingPrice);
    }

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
                color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle),
                    child: Icon(
                      isEdit ? Icons.edit_road_rounded : Icons.add_road_rounded,
                      color: Colors.yellow[800], size: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(isEdit ? 'Edit Route' : 'Add New Route',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 20),

                  // Pickup
                  _dialogField(
                    controller: pickupCtrl, label: 'Pickup Location',
                    hint: 'e.g. Clocktower, Thimphu',
                    icon: Icons.location_on_rounded, iconColor: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),

                  // Dropoff
                  _dialogField(
                    controller: dropoffCtrl, label: 'Dropoff Location',
                    hint: 'e.g. Paro Airport',
                    icon: Icons.flag_rounded, iconColor: Colors.yellow[800]!,
                  ),
                  const SizedBox(height: 12),

                  // ✅ Dynamic price fields for each vehicle type
                  if (_vehicleTypes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No vehicle types available. Add vehicle types first.',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          textAlign: TextAlign.center),
                    )
                  else
                    ...(_vehicleTypes.map((vt) {
                      final name        = vt['name'].toString();
                      final displayName = vt['display_name'].toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _dialogField(
                          controller: priceControllers[name]!,
                          label: '$displayName Price (Nu.)',
                          icon: Icons.directions_car_rounded,
                          iconColor: Colors.yellow[800]!,
                          keyboardType: TextInputType.number,
                        ),
                      );
                    }).toList()),

                  // Active toggle (edit only)
                  if (isEdit) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          Icon(
                            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isActive ? const Color(0xFF2E7D32) : Colors.grey, size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text('Active Route',
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: isActive ? const Color(0xFF2E7D32) : Colors.grey[600],
                              )),
                        ]),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: isActive,
                            activeColor: const Color(0xFF2E7D32),
                            activeTrackColor: const Color(0xFF2E7D32).withOpacity(0.3),
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[200],
                            onChanged: (v) => setDialogState(() => isActive = v),
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Buttons
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.black54,
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: () async {
                        if (pickupCtrl.text.trim().isEmpty || dropoffCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Please enter both locations'),
                            backgroundColor: Colors.grey[800],
                          ));
                          return;
                        }
                        if (pickupCtrl.text.trim() == dropoffCtrl.text.trim()) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Pickup and dropoff cannot be the same'),
                            backgroundColor: Colors.grey[800],
                          ));
                          return;
                        }

                        // ✅ Build dynamic prices array
                        final List<Map<String, dynamic>> prices = [];
                        for (final vt in _vehicleTypes) {
                          final name = vt['name'].toString();
                          final id   = vt['id'];
                          prices.add({
                            'vehicle_type_id': id,
                            'price': double.tryParse(priceControllers[name]?.text ?? '0') ?? 0,
                          });
                        }

                        try {
                          final data = {
                            'pickup_location':  pickupCtrl.text.trim(),
                            'dropoff_location': dropoffCtrl.text.trim(),
                            'prices':           prices,
                            if (isEdit) 'is_active': isActive,
                          };
                          if (isEdit) {
                            await _apiService.put('/admin/routes/${route['id']}', data);
                          } else {
                            await _apiService.post('/admin/routes', data);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadRoutes();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isEdit ? 'Route updated!' : 'Route added!'),
                              backgroundColor: Colors.yellow[800],
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.grey[800],
                            ));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                        elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEdit ? 'Update' : 'Add Route',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    )),
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
  Future<void> _deleteRoute(dynamic route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 28)),
            const SizedBox(height: 16),
            const Text('Delete Route',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              'Delete route from\n${route['pickup_location']} → ${route['dropoff_location']}?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: Colors.black54,
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/admin/routes/${route['id']}');
        _loadRoutes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Route deleted'),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        centerTitle: false, titleSpacing: 20, automaticallyImplyLeading: false,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Text('Easy Ride',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800,
                  fontSize: 19, letterSpacing: 0.3)),
        ]),
        actions: [
          InkWell(
            onTap: _loadRoutes, borderRadius: BorderRadius.circular(8),
            child: Padding(padding: const EdgeInsets.all(8),
                child: Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 20)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: InkWell(
              onTap: _confirmLogout, borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100], borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex, onTap: _onNavTap,
          type: BottomNavigationBarType.fixed, backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800], unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route_rounded), label: 'Routes'),
            BottomNavigationBarItem(icon: Icon(Icons.drive_eta_outlined), activeIcon: Icon(Icons.drive_eta_rounded), label: 'Drivers'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'Passengers'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRouteDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Route', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.yellow[800], foregroundColor: Colors.white, elevation: 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
          : _routes.isEmpty
              ? FadeTransition(
                  opacity: _fadeAnim,
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                        child: Icon(Icons.route_rounded, size: 38, color: Colors.grey[300])),
                    const SizedBox(height: 16),
                    Text('No routes yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    Text('Tap + Add Route to create one', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  ])),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: RefreshIndicator(
                    color: Colors.yellow[800],
                    onRefresh: _loadRoutes,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _routes.length,
                      itemBuilder: (context, index) => _buildRouteCard(_routes[index]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildRouteCard(dynamic route) {
    final isActive = route['is_active'] ?? true;
    final prices   = route['prices'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ──────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(route['pickup_location'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                    overflow: TextOverflow.ellipsis)),
              ]),
              Padding(padding: const EdgeInsets.only(left: 3.5),
                  child: Container(width: 1, height: 10, color: Colors.grey.shade300)),
              Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(route['dropoff_location'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE8F5E9) : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? const Color(0xFF4CAF50).withOpacity(0.5) : Colors.red.withOpacity(0.4),
                ),
              ),
              child: Text(isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                      color: isActive ? const Color(0xFF2E7D32) : Colors.red[400],
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),

          Divider(height: 20, color: Colors.grey.shade100),

          // ✅ Dynamic price chips from route_prices
          prices.isEmpty
              ? Text('No prices set', style: TextStyle(color: Colors.grey[400], fontSize: 12))
              : Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: prices.entries.map((entry) {
                    final vtName  = entry.key;
                    final vtPrice = entry.value['price']?.toString() ?? '0';
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(vtName,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text('Nu. $vtPrice',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.yellow[800])),
                    ]);
                  }).toList(),
                ),

          Divider(height: 20, color: Colors.grey.shade100),

          // ── Action buttons ───────────────────────────
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _showRouteDialog(route: route),
              icon: Icon(Icons.edit_rounded, size: 15, color: Colors.yellow[800]),
              label: Text('Edit', style: TextStyle(color: Colors.yellow[800], fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: Colors.yellow[200]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _deleteRoute(route),
              icon: Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red[400]),
              label: Text('Delete', style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}