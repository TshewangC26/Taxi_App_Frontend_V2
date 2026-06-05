import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'passenger_home_screen.dart';
import 'driver_home_screen.dart';

// ✅ Auto-formatter for License Number: G-13947
class LicenseNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String raw = newValue.text.replaceAll('-', '').toUpperCase();
    String formatted = '';
    for (int i = 0; i < raw.length; i++) {
      if (i == 1 && raw.length > 1) {
        formatted += '-';
      }
      formatted += raw[i];
    }
    if (formatted.length > 7) {
      formatted = formatted.substring(0, 7);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ✅ Auto-formatter for Vehicle Number: BP-1-B6884
class VehicleNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String raw = newValue.text.replaceAll('-', '').toUpperCase();
    String formatted = '';
    for (int i = 0; i < raw.length; i++) {
      if (i == 2 && raw.length > 2) {
        formatted += '-';
      } else if (i == 3 && raw.length > 3) {
        formatted += '-';
      }
      formatted += raw[i];
    }
    if (formatted.length > 10) {
      formatted = formatted.substring(0, 10);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ✅ Auto-formatter for Bhutan Phone: +975 17 123 456
class BhutanPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    // If user is deleting and text is just '+975' or less, allow empty
    if (newValue.text.isEmpty || newValue.text == '+' ||
        newValue.text == '+9' || newValue.text == '+97' ||
        newValue.text == '+975' || newValue.text == '+975 ') {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Strip everything except digits
    String raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Remove leading 975 if user typed it
    if (raw.startsWith('975')) {
      raw = raw.substring(3);
    }

    // If nothing left after stripping, return empty
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Limit to 8 digits
    if (raw.length > 8) {
      raw = raw.substring(0, 8);
    }

   // Build formatted string
    String formatted = '+975';
    if (raw.length >= 1) {
      formatted += ' ';
      formatted += raw.substring(0, raw.length >= 2 ? 2 : raw.length);
    }
    if (raw.length >= 3) {
      formatted += ' ';
      formatted += raw.substring(2, raw.length >= 5 ? 5 : raw.length);
    }
    if (raw.length >= 6) {
      formatted += ' ';
      formatted += raw.substring(5, raw.length >= 8 ? 8 : raw.length);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  String _userType = 'passenger';
  String? _vehicleType;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // ✅ License image
  File? _licenseImage;
  final ImagePicker _imagePicker = ImagePicker();

  // ✅ Dynamic vehicle types
  List<Map<String, String>> _vehicleTypes = [];
  bool _loadingVehicleTypes = false;
  final ApiService _apiService = ApiService();

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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    setState(() => _loadingVehicleTypes = true);
    try {
      final response = await _apiService.get('/vehicle-types');
      final List<dynamic> types = response['vehicle_types'] ?? [];
      setState(() {
        _vehicleTypes = types.map<Map<String, String>>((t) => {
          'name': t['name'].toString(),
          'display_name': t['display_name'].toString(),
        }).toList();
        if (_vehicleTypes.isNotEmpty) {
          _vehicleType = _vehicleTypes.first['name'];
        }
        _loadingVehicleTypes = false;
      });
    } catch (e) {
      print('Vehicle types error: $e');
      setState(() {
        _vehicleTypes = [
          {'name': '4-seater', 'display_name': '4-Seater'},
          {'name': '7-seater', 'display_name': '7-Seater'},
          {'name': '8-seater', 'display_name': '8-Seater'},
        ];
        _vehicleType = '4-seater';
        _loadingVehicleTypes = false;
      });
    }
  }

  Future<void> _pickLicenseImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _licenseImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Upload License Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _pickLicenseImage(ImageSource.camera);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.yellow[50], borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.yellow[800], size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Take Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Use camera to capture license', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _pickLicenseImage(ImageSource.gallery);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.yellow[50], borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.photo_library_rounded, color: Colors.yellow[800], size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Choose from Gallery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Pick from your photo library', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  void _showEmailTakenDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle)),
              Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.orange[700], shape: BoxShape.circle),
                  child: const Icon(Icons.email_outlined, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 20),
            const Text('Email Already Used',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 10),
            Text(
              'An account with this email address already exists.\n\nPlease use a different email or login to your existing account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Try Different Email', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 28)),
            const SizedBox(height: 16),
            const Text('Registration Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Try Again', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_userType == 'driver' && _licenseImage == null) {
        _showErrorDialog('Please upload a photo of your license.');
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userType: _userType,
        phone: _phoneController.text.trim(),
        vehicleType: _userType == 'driver' ? _vehicleType : null,
        vehicleNumber: _userType == 'driver' ? _vehicleNumberController.text.trim() : null,
        licenseNumber: _userType == 'driver' ? _licenseNumberController.text.trim() : null,
        licenseImagePath: _userType == 'driver' ? _licenseImage?.path : null,
      );

      if (success && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('prefill_name', _nameController.text.trim());

        if (_userType == 'passenger') {
          Navigator.pushAndRemoveUntil(context, PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const PassengerHomeScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ), (route) => false);
        } else if (_userType == 'driver') {
          Navigator.pushAndRemoveUntil(context, PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const DriverHomeScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ), (route) => false);
        }
      } else if (mounted) {
        final error = (authProvider.errorMessage ?? '').toLowerCase();
        if (error.contains('email') &&
            (error.contains('already') || error.contains('taken') ||
                error.contains('exists') || error.contains('registered') ||
                error.contains('duplicate') || error.contains('unique'))) {
          _showEmailTakenDialog();
        } else {
          _showErrorDialog(authProvider.errorMessage ?? 'Registration failed. Please try again.');
        }
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.yellow[800], size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.yellow[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.yellow[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
      validator: validator,
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 0.3)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.yellow[50], borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow[200]!)),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.yellow[800], size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 0.3)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Container(width: 52, height: 52,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 26)),
                      const SizedBox(width: 16),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Join Easy Ride', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                        SizedBox(height: 3),
                        Text('Fill in your details below to get started', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ])),
                    ]),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('Personal Information', Icons.person_outline),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _nameController, label: 'Full Name', icon: Icons.badge_outlined,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _emailController, label: 'Email', icon: Icons.mail_outline,
                    hint: 'Use a valid email for login', keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter your email' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _passwordController, label: 'Password', icon: Icons.lock_outline,
                    hint: 'Minimum 12 characters', obscure: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.yellow[800], size: 20),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your password';
                      if (value.length < 12) return 'Password must be at least 12 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock_outline,
                    hint: 'Re-enter your password', obscure: !_showConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.yellow[800], size: 20),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm your password';
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ✅ Phone — Bhutan format for driver, free for passenger
                  _buildField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    hint: _userType == 'driver' ? 'e.g. +975 17 123 456' : null,
                    keyboardType: TextInputType.phone,
                    inputFormatters: _userType == 'driver' ? [BhutanPhoneFormatter()] : null,
                   validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your phone number';
                      if (_userType == 'driver') {
                        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                        // After stripping +975, should have 8 digits
                        final localDigits = digits.startsWith('975') ? digits.substring(3) : digits;
                        if (localDigits.length != 8) {
                          return 'Enter a valid Bhutan number e.g. +975 17 123 456';
                        }
                        // ✅ Must start with 16, 17, or 77
                        if (!localDigits.startsWith('16') &&
                            !localDigits.startsWith('17') &&
                            !localDigits.startsWith('77')) {
                          return 'Number must start with 16, 17, or 77';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader('Account Type', Icons.switch_account_outlined),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: _TypeCard(
                      label: 'Passenger', icon: Icons.airline_seat_recline_normal,
                      selected: _userType == 'passenger',
                      onTap: () {
                        setState(() {
                          _userType = 'passenger';
                          _phoneController.clear();
                        });
                      },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _TypeCard(
                      label: 'Driver', icon: Icons.drive_eta_outlined,
                      selected: _userType == 'driver',
                      onTap: () {
                        setState(() {
                          _userType = 'driver';
                          _phoneController.clear();
                        });
                      },
                    )),
                  ]),

                  if (_userType == 'driver') ...[
                    const SizedBox(height: 24),
                    _sectionHeader('Driver Information', Icons.directions_car_outlined),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.yellow[200]!),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.directions_car, color: Colors.yellow[800], size: 18),
                          const SizedBox(width: 8),
                          Text('Vehicle Type', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 12),
                        _loadingVehicleTypes
                            ? Center(child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!), strokeWidth: 2),
                              ))
                            : _vehicleTypes.isEmpty
                                ? Text('No vehicle types available', style: TextStyle(color: Colors.grey[400], fontSize: 13))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _vehicleTypes.map((type) {
                                      final selected = _vehicleType == type['name'];
                                      return GestureDetector(
                                        onTap: () => setState(() => _vehicleType = type['name']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: selected ? Colors.yellow[800] : Colors.yellow[50],
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: selected ? Colors.yellow[800]! : Colors.yellow[200]!),
                                          ),
                                          child: Text(
                                            type['display_name']!,
                                            style: TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600,
                                              color: selected ? Colors.white : Colors.yellow[800],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _vehicleNumberController,
                      label: 'Vehicle Number',
                      icon: Icons.confirmation_number_outlined,
                      hint: 'e.g. BT1B6884 → BT-1-B6884',
                      keyboardType: TextInputType.text,
                      inputFormatters: [VehicleNumberFormatter()],
                      validator: (value) => (_userType == 'driver' && (value == null || value.isEmpty))
                          ? 'Please enter vehicle number' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _licenseNumberController,
                      label: 'License Number',
                      icon: Icons.card_membership_outlined,
                      hint: 'e.g. G13947 → G-13947',
                      keyboardType: TextInputType.text,
                      inputFormatters: [LicenseNumberFormatter()],
                      validator: (value) => (_userType == 'driver' && (value == null || value.isEmpty))
                          ? 'Please enter license number' : null,
                    ),
                    const SizedBox(height: 14),

                    // ✅ License Image Upload
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _licenseImage != null ? Colors.yellow[800]! : Colors.yellow[200]!,
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.photo_camera_outlined, color: Colors.yellow[800], size: 18),
                          const SizedBox(width: 8),
                          Text('License Photo',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          if (_licenseImage != null)
                            GestureDetector(
                              onTap: () => setState(() => _licenseImage = null),
                              child: Icon(Icons.close_rounded, color: Colors.red[400], size: 18),
                            ),
                        ]),
                        const SizedBox(height: 12),
                        if (_licenseImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _licenseImage!,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.yellow[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.yellow[200]!, style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_rounded, color: Colors.yellow[800], size: 32),
                                  const SizedBox(height: 8),
                                  Text('Tap to upload license photo',
                                      style: TextStyle(color: Colors.yellow[800], fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Camera or Gallery',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        if (_licenseImage != null) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, color: Colors.yellow[800], size: 16),
                                const SizedBox(width: 6),
                                Text('Change Photo',
                                    style: TextStyle(color: Colors.yellow[800], fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ],

                  const SizedBox(height: 32),

                  authProvider.isLoading
                      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
                      : Container(
                          height: 56,
                          decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(16)),
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 10),
                              Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                            ]),
                          ),
                        ),

                  const SizedBox(height: 20),

                  Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.local_taxi, size: 13, color: Colors.yellow[800]),
                    const SizedBox(width: 5),
                    Text('Online Taxi Service', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? Colors.yellow[800] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.yellow[800]! : Colors.yellow[200]!, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, size: 28, color: selected ? Colors.white : Colors.yellow[800]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.yellow[800], letterSpacing: 0.2)),
        ]),
      ),
    );
  }
}