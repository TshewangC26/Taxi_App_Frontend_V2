import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../services/api_service.dart';
import 'driver_home_screen.dart';
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class DriverPaymentDetailsScreen extends StatefulWidget {
  const DriverPaymentDetailsScreen({super.key});

  @override
  State<DriverPaymentDetailsScreen> createState() =>
      _DriverPaymentDetailsScreenState();
}

class _DriverPaymentDetailsScreenState
    extends State<DriverPaymentDetailsScreen> {
  final _formKey                   = GlobalKey<FormState>();
  final _accountHolderController   = TextEditingController();
  final _accountNumberController   = TextEditingController();
  final _mobileNumberController    = TextEditingController();
  final ApiService _apiService     = ApiService();

  static const List<String> _banks = [
    'Bhutan National Bank Ltd',
    'Druk PNB Ltd',
    'Bhutan Development Bank Ltd',
    'T Bank Ltd',
    'DK Bank',
    'Bank of Bhutan',
  ];

  String? _selectedBank;
  bool _isLoading     = false;
  bool _isUploadingQR = false;
  File? _qrCodeFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    driverProvider.getProfile().then((_) {
      final profile = driverProvider.driverProfile;
      if (profile != null) {
        setState(() {
          final savedBank = profile['bank_name'] ?? '';
          _selectedBank = _banks.contains(savedBank) ? savedBank : null;
        });
        _accountHolderController.text = profile['account_holder_name'] ?? '';
        _accountNumberController.text = profile['account_number'] ?? '';
        _mobileNumberController.text  = profile['mobile_payment_number'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  // ── Hamburger menu ────────────────────────────────────────────
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
            icon: Icons.headset_mic_rounded, iconColor: Colors.yellow[800]!, iconBg: Colors.yellow[50]!,
            title: 'Contact Us', subtitle: 'Get in touch with our support team',
            onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen())); },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(
            icon: Icons.info_outline_rounded, iconColor: Colors.blue[700]!, iconBg: Colors.blue[50]!,
            title: 'About Us', subtitle: 'Learn more about Easy Ride',
            onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())); },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(
            icon: Icons.logout_rounded, iconColor: Colors.red[400]!, iconBg: Colors.red[50]!,
            title: 'Logout', subtitle: 'Sign out of your account',
            onTap: () { Navigator.pop(ctx); _confirmLogout(); },
          ),
        ]),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon, required Color iconColor, required Color iconBg,
    required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
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

  // ✅ Reusable error dialog
  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog(
      context: context, barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle)),
              Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('OK', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickQRCode() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() { _qrCodeFile = File(image.path); });
    }
  }

  Future<void> _uploadQRCode() async {
    if (_qrCodeFile == null) return;
    setState(() => _isUploadingQR = true);
    try {
      final cloudinaryUrl = await _apiService.uploadImageToCloudinary(_qrCodeFile!.path);
      if (cloudinaryUrl == null) throw Exception('Cloudinary upload failed');
      final token = await _apiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/driver/upload-qr'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'qr_code_url': cloudinaryUrl}),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          await Provider.of<DriverProvider>(context, listen: false).getProfile();
          setState(() { _qrCodeFile = null; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('QR Code updated successfully!'), backgroundColor: Colors.yellow[800]));
        } else {
          await _showErrorDialog('Upload Failed', 'Could not upload your QR code.\nPlease try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        await _showErrorDialog('Upload Error', 'Something went wrong while uploading your QR code.\nPlease check your connection and try again.');
      }
    }
    if (mounted) setState(() => _isUploadingQR = false);
  }

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      final success = await driverProvider.updateBankDetails(
        bankName:            _selectedBank ?? '',
        accountHolderName:   _accountHolderController.text,
        accountNumber:       _accountNumberController.text,
        mobilePaymentNumber: _mobileNumberController.text,
      );
      if (_qrCodeFile != null && success) await _uploadQRCode();
      setState(() => _isLoading = false);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Payment details saved successfully!'), backgroundColor: Colors.yellow[800]));
          Navigator.pop(context);
        } else {
          await _showErrorDialog('Save Failed', driverProvider.errorMessage ?? 'Could not save payment details.\nPlease check your details and try again.');
        }
      }
    }
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: Colors.white, size: 15)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
    ]);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.yellow[800], size: 20),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final existingQR = driverProvider.driverProfile?['qr_code_image'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: false,
        titleSpacing: 20, automaticallyImplyLeading: false,
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
              onTap: _openMenu, borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: Icon(Icons.menu_rounded, color: Colors.grey[700], size: 22),
              ),
            ),
          ),
        ],
      ),
      body: driverProvider.isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── BANK DETAILS ──────────────────────────────
                    _sectionHeader('Bank Details', Icons.account_balance_rounded),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBank,
                        decoration: _fieldDecoration('Bank Name', Icons.account_balance_rounded),
                        hint: Text('Select Bank', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                        onChanged: (v) => setState(() => _selectedBank = v),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please select a bank' : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _accountHolderController,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: _fieldDecoration('Account Holder Name', Icons.person_outline_rounded),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: _fieldDecoration('Account Number', Icons.numbers_rounded),
                    ),
                    const SizedBox(height: 24),

                    // ── MOBILE PAYMENT ────────────────────────────
                    _sectionHeader('Mobile Payment', Icons.phone_android_rounded),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _mobileNumberController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: _fieldDecoration('Mobile Payment Number', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 24),

                    // ── QR CODE SECTION ───────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _sectionHeader('QR Code', Icons.qr_code_rounded),
                      if (existingQR != null)
                        GestureDetector(
                          onTap: _pickQRCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.yellow[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.yellow[200]!)),
                            child: Row(children: [
                              Icon(Icons.edit_rounded, size: 14, color: Colors.yellow[800]),
                              const SizedBox(width: 4),
                              Text('Update QR', style: TextStyle(fontSize: 12, color: Colors.yellow[800], fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: _pickQRCode,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _qrCodeFile != null
                            ? Stack(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_qrCodeFile!, width: double.infinity, height: 200, fit: BoxFit.contain),
                                ),
                                Positioned(top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('New — Not saved yet', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                              ])
                            : existingQR != null
                                ? Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        existingQR.contains('?') ? existingQR : '$existingQR?t=${DateTime.now().millisecondsSinceEpoch}',
                                        width: double.infinity, height: 200, fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => Icon(Icons.qr_code_rounded, size: 80, color: Colors.grey[300]),
                                      ),
                                    ),
                                    Positioned(top: 8, right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Saved ✅', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    ),
                                  ])
                                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.qr_code_rounded, size: 56, color: Colors.grey[300]),
                                    const SizedBox(height: 10),
                                    Text('Tap to upload QR code', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('Passengers will scan this to pay', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                  ]),
                      ),
                    ),

                    if (_qrCodeFile != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: _isUploadingQR
                            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
                            : ElevatedButton.icon(
                                onPressed: _uploadQRCode,
                                icon: const Icon(Icons.upload_rounded, size: 18),
                                label: const Text('Upload QR Code Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange, foregroundColor: Colors.white,
                                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── SAVE BUTTON ───────────────────────────────
                    SizedBox(
                      height: 56,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
                          : ElevatedButton.icon(
                              onPressed: _saveDetails,
                              icon: const Icon(Icons.check_circle_rounded, size: 20),
                              label: const Text('Save Payment Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}