import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';

class DriverUpdateProfileScreen extends StatefulWidget {
  const DriverUpdateProfileScreen({super.key});

  @override
  State<DriverUpdateProfileScreen> createState() =>
      _DriverUpdateProfileScreenState();
}

class _DriverUpdateProfileScreenState
    extends State<DriverUpdateProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Basic info controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Driver-specific controllers
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _mobilePaymentController = TextEditingController();

  String _vehicleType = '4-seater';

  // Profile photo
  File? _selectedImage;
  Uint8List? _webImage;
  String? _imagePath;

  // QR code image
  File? _selectedQrImage;
  Uint8List? _webQrImage;
  String? _qrImagePath;

  bool _isLoading = false;

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
      _prefillFields();
    });
  }

  void _prefillFields() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final dp = Provider.of<DriverProvider>(context, listen: false);

    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }

    final profile = dp.driverProfile;
    if (profile != null) {
      _vehicleNumberController.text =
          profile['vehicle_number']?.toString() ?? '';
      _licenseNumberController.text =
          profile['license_number']?.toString() ?? '';
      _accountNumberController.text =
          profile['account_number']?.toString() ?? '';
      _mobilePaymentController.text =
          profile['mobile_payment_number']?.toString() ?? '';
      final vt = profile['vehicle_type']?.toString() ?? '4-seater';
      setState(() {
        _vehicleType =
            ['4-seater', '7-seater', '8-seater'].contains(vt)
                ? vt
                : '4-seater';
      });
    } else {
      dp.getProfile().then((_) => _prefillFields());
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    _accountNumberController.dispose();
    _mobilePaymentController.dispose();
    super.dispose();
  }

  // ── Pick profile photo ────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
        _imagePath = image.path;
        _selectedImage = null;
      });
    } else {
      setState(() {
        _selectedImage = File(image.path);
        _imagePath = image.path;
        _webImage = null;
      });
    }
  }

  // ── Pick QR code image ────────────────────────────────────────
  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90);
    if (image == null) return;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webQrImage = bytes;
        _qrImagePath = image.path;
        _selectedQrImage = null;
      });
    } else {
      setState(() {
        _selectedQrImage = File(image.path);
        _qrImagePath = image.path;
        _webQrImage = null;
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final dp = Provider.of<DriverProvider>(context, listen: false);

    // Update basic user info
    final basicSuccess = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      imagePath: _imagePath,
    );

    // Update driver-specific info
    final driverSuccess = await dp.updateDriverProfile(
      vehicleNumber: _vehicleNumberController.text.trim(),
      licenseNumber: _licenseNumberController.text.trim(),
      vehicleType: _vehicleType,
      accountNumber: _accountNumberController.text.trim(),
      mobilePaymentNumber: _mobilePaymentController.text.trim(),
      qrImagePath: _qrImagePath,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (basicSuccess && driverSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Colors.yellow[800],
        ),
      );
      Navigator.pop(context);
    } else {
      final error = !basicSuccess
          ? (authProvider.errorMessage ?? 'Failed to update profile')
          : (dp.errorMessage ?? 'Failed to update driver info');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error), backgroundColor: Colors.grey[800]),
      );
    }
  }

  // ── Profile image widget ──────────────────────────────────────
  Widget _buildProfileImage(dynamic user) {
    if (_webImage != null) {
      return ClipOval(
          child: Image.memory(_webImage!,
              width: 88, height: 88, fit: BoxFit.cover));
    } else if (_selectedImage != null) {
      return ClipOval(
          child: Image.file(_selectedImage!,
              width: 88, height: 88, fit: BoxFit.cover));
    } else if (user?.profilePhoto != null) {
      return ClipOval(
        child: Image.network(
          '${user!.profilePhoto!}?t=${DateTime.now().millisecondsSinceEpoch}',
          width: 88, height: 88, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, size: 44, color: Colors.white),
        ),
      );
    }
    return const Icon(Icons.person, size: 44, color: Colors.white);
  }

  // ── QR preview widget ─────────────────────────────────────────
  Widget _buildQrPreview(dynamic profile) {
    if (_webQrImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(_webQrImage!,
            width: 150, height: 150, fit: BoxFit.cover),
      );
    } else if (_selectedQrImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(_selectedQrImage!,
            width: 150, height: 150, fit: BoxFit.cover),
      );
    } else if (profile?['qr_code_image'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          profile!['qr_code_image'],
          width: 150, height: 150, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _qrPlaceholder(),
        ),
      );
    }
    return _qrPlaceholder();
  }

  Widget _qrPlaceholder() => Container(
        width: 150, height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_rounded, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 6),
            Text('No QR uploaded',
                style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
      );

  // ── Field decoration ──────────────────────────────────────────
  InputDecoration _fieldDec(String label, IconData icon,
      {String? helper, bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      labelStyle: TextStyle(
          color: enabled ? Colors.grey[600] : Colors.grey[400],
          fontSize: 14),
      prefixIcon: Icon(icon,
          color: enabled ? Colors.yellow[800] : Colors.grey[400],
          size: 20),
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey[50],
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: Colors.yellow[800],
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.1)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final dp = Provider.of<DriverProvider>(context);
    final profile = dp.driverProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),

      // ── APP BAR ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                color: Colors.grey[700], size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Update Profile',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.2)),
      ),

      // ── BODY ─────────────────────────────────────────────
      body: dp.isLoading && profile == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.yellow[800]!),
              ),
            )
          : FadeTransition(
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

                        // ── AVATAR CARD ───────────────────────
                        Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.grey.shade100),
                          ),
                          child: Column(children: [
                            Stack(children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.yellow[700]!,
                                      width: 2.5),
                                ),
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.yellow[800],
                                  child: _buildProfileImage(user),
                                ),
                              ),
                              Positioned(
                                bottom: 2, right: 2,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[800],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white,
                                          width: 2),
                                    ),
                                    child: const Icon(
                                        Icons.photo_library_outlined,
                                        color: Colors.white,
                                        size: 16),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Text('Tap the icon to change photo',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12)),
                          ]),
                        ),

                        const SizedBox(height: 20),

                        // ── PERSONAL INFO ─────────────────────
                        _sectionLabel('Personal Information',
                            Icons.person_outline_rounded),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration:
                              _fieldDec('Full Name', Icons.badge_outlined),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter your name'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration: _fieldDec(
                              'Phone Number', Icons.phone_outlined),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter your phone number'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        // Email read-only
                        TextFormField(
                          initialValue: user?.email ?? '',
                          enabled: false,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 15),
                          decoration: _fieldDec(
                            'Email',
                            Icons.mail_outline_rounded,
                            helper: 'Email cannot be changed',
                            enabled: false,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── VEHICLE INFO ──────────────────────
                        _sectionLabel('Vehicle Information',
                            Icons.directions_car_outlined),
                        const SizedBox(height: 12),

                        // Vehicle type chip selector
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.directions_car_rounded,
                                    color: Colors.yellow[800], size: 18),
                                const SizedBox(width: 8),
                                Text('Vehicle Type',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ]),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  '4-seater',
                                  '7-seater',
                                  '8-seater'
                                ].map((type) {
                                  final selected = _vehicleType == type;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _vehicleType = type),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 180),
                                        margin:
                                            const EdgeInsets.symmetric(
                                                horizontal: 4),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? Colors.yellow[800]
                                              : Colors.yellow[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: selected
                                                ? Colors.yellow[800]!
                                                : Colors.yellow[200]!,
                                          ),
                                        ),
                                        child: Text(type,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? Colors.white
                                                  : Colors.yellow[800],
                                            )),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _vehicleNumberController,
                          textCapitalization:
                              TextCapitalization.characters,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration: _fieldDec(
                            'Vehicle Number',
                            Icons.confirmation_number_outlined,
                            helper: 'Example: BT-1234',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter vehicle number'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _licenseNumberController,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration: _fieldDec(
                            'License Number',
                            Icons.card_membership_outlined,
                            helper: 'Your driver license ID',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter license number'
                                  : null,
                        ),

                        const SizedBox(height: 24),

                        // ── PAYMENT DETAILS ───────────────────
                        _sectionLabel(
                            'Payment Details', Icons.payment_rounded),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _accountNumberController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration: _fieldDec(
                            'Bank Account Number',
                            Icons.account_balance_outlined,
                            helper: 'Optional — for online payments',
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _mobilePaymentController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration: _fieldDec(
                            'Mobile Payment Number',
                            Icons.phone_android_outlined,
                            helper: 'Optional — mBoB / BoB number',
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── QR CODE ───────────────────────────
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.qr_code_rounded,
                                    color: Colors.yellow[800], size: 18),
                                const SizedBox(width: 8),
                                Text('Payment QR Code',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                'Passengers can scan this to pay you online.',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                  child: _buildQrPreview(profile)),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: _pickQrImage,
                                  icon: Icon(
                                      Icons.upload_file_rounded,
                                      color: Colors.yellow[800],
                                      size: 18),
                                  label: Text(
                                    (profile?['qr_code_image'] !=
                                                null ||
                                            _qrImagePath != null)
                                        ? 'Change QR Code'
                                        : 'Upload QR Code',
                                    style: TextStyle(
                                        color: Colors.yellow[800],
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.yellow[200]!),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              // Show new QR selected indicator
                              if (_qrImagePath != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Row(children: [
                                    const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF2E7D32),
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text('New QR code selected',
                                        style: TextStyle(
                                            color:
                                                const Color(0xFF2E7D32),
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── SAVE BUTTON ───────────────────────
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.yellow[800]!),
                                ),
                              )
                            : SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _saveProfile,
                                  icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 20),
                                  label: const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.yellow[800],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
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