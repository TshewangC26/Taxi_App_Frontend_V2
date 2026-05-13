import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_home_screen.dart';
import 'admin_routes_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_passengers_screen.dart';

class AdminEditProfileScreen extends StatefulWidget {
  const AdminEditProfileScreen({super.key});

  @override
  State<AdminEditProfileScreen> createState() => _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // ✅ Added

  File?      _selectedImage;
  Uint8List? _webImage;
  String?    _imagePath;

  bool _isLoading = false;
  final int _currentIndex = 4;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        _nameController.text  = user.name;
        _phoneController.text = user.phone ?? '';
        _emailController.text = user.email ?? ''; // ✅ Added
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose(); // ✅ Added
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    Widget screen;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(context,
            PageRouteBuilder(pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const AdminHomeScreen()), transitionDuration: const Duration(milliseconds: 300)),
            (r) => false);
        return;
      case 1: screen = const AdminRoutesScreen(); break;
      case 2: screen = const AdminDriversScreen(); break;
      case 3: screen = const AdminPassengersScreen(); break;
      default: return;
    }
    Navigator.pushReplacement(context,
        PageRouteBuilder(pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: screen), transitionDuration: const Duration(milliseconds: 300)));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() { _webImage = bytes; _imagePath = image.path; _selectedImage = null; });
    } else {
      setState(() { _selectedImage = File(image.path); _imagePath = image.path; _webImage = null; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name:      _nameController.text.trim(),
      phone:     _phoneController.text.trim(),
      email:     _emailController.text.trim(), // ✅ Added
      imagePath: _imagePath,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Profile updated successfully!'), backgroundColor: Colors.yellow[800]));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to update profile'), backgroundColor: Colors.grey[800]));
    }
  }

  Widget _buildAvatar(dynamic user) {
    if (_webImage != null) return ClipOval(child: Image.memory(_webImage!, width: 88, height: 88, fit: BoxFit.cover));
    if (_selectedImage != null) return ClipOval(child: Image.file(_selectedImage!, width: 88, height: 88, fit: BoxFit.cover));
    if (user?.profilePhoto != null) {
      return ClipOval(child: Image.network('${user!.profilePhoto!}?t=${DateTime.now().millisecondsSinceEpoch}', width: 88, height: 88, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.admin_panel_settings_rounded, size: 44, color: Colors.white)));
    }
    return const Icon(Icons.admin_panel_settings_rounded, size: 44, color: Colors.white);
  }

  InputDecoration _fieldDec(String label, IconData icon, {String? helper, bool enabled = true}) {
    return InputDecoration(
      labelText: label, helperText: helper,
      labelStyle: TextStyle(color: enabled ? Colors.grey[600] : Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, color: enabled ? Colors.yellow[800] : Colors.grey[400], size: 20),
      filled: true, fillColor: enabled ? Colors.white : Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: Colors.white, size: 15)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: 0.1)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: IconButton(
          icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
              child: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 16)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.2)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1))),
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                    child: Column(children: [
                      Stack(children: [
                        Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.yellow[700]!, width: 2.5)),
                            child: CircleAvatar(radius: 44, backgroundColor: Colors.yellow[800], child: _buildAvatar(user))),
                        Positioned(bottom: 2, right: 2,
                            child: GestureDetector(onTap: _pickImage,
                                child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                    child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 16)))),
                      ]),
                      const SizedBox(height: 12),
                      Text('Tap the icon to change photo', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ]),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Personal Information', Icons.person_outline_rounded),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                    decoration: _fieldDec('Full Name', Icons.badge_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                    decoration: _fieldDec('Phone Number', Icons.phone_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                  ),
                  const SizedBox(height: 12),

                  // ✅ Email now editable
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                    decoration: _fieldDec('Email', Icons.mail_outline_rounded),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your email';
                      if (!v.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  _isLoading
                      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
                      : SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.check_circle_rounded, size: 20),
                            label: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[800], foregroundColor: Colors.white, elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}