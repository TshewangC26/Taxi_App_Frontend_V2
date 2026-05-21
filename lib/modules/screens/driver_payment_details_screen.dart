import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/driver_provider.dart';
import '../services/api_service.dart';

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

  // ✅ Hardcoded bank list
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
    final driverProvider =
        Provider.of<DriverProvider>(context, listen: false);
    driverProvider.getProfile().then((_) {
      final profile = driverProvider.driverProfile;
      if (profile != null) {
        setState(() {
          final savedBank = profile['bank_name'] ?? '';
          _selectedBank = _banks.contains(savedBank) ? savedBank : null;
        });
        _accountHolderController.text =
            profile['account_holder_name'] ?? '';
        _accountNumberController.text =
            profile['account_number'] ?? '';
        _mobileNumberController.text =
            profile['mobile_payment_number'] ?? '';
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

  Future<void> _pickQRCode() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _qrCodeFile = File(image.path);
      });
    }
  }

  // ✅ Upload QR code to Cloudinary first, then send URL to Laravel
  Future<void> _uploadQRCode() async {
    if (_qrCodeFile == null) return;
    setState(() => _isUploadingQR = true);
    try {
      // ✅ Step 1: Upload to Cloudinary
      final cloudinaryUrl = await _apiService.uploadImageToCloudinary(
        _qrCodeFile!.path,
      );

      if (cloudinaryUrl == null) throw Exception('Cloudinary upload failed');

      // ✅ Step 2: Send Cloudinary URL to Laravel
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
            const SnackBar(
              content: Text('QR Code updated successfully! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code upload failed!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code upload error!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isUploadingQR = false);
  }

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final driverProvider =
          Provider.of<DriverProvider>(context, listen: false);

      final success = await driverProvider.updateBankDetails(
        bankName:            _selectedBank ?? '',
        accountHolderName:   _accountHolderController.text,
        accountNumber:       _accountNumberController.text,
        mobilePaymentNumber: _mobileNumberController.text,
      );

      if (_qrCodeFile != null && success) {
        await _uploadQRCode();
      }

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment details saved successfully! ✅'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(driverProvider.errorMessage ?? 'Update failed!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final existingQR = driverProvider.driverProfile?['qr_code_image'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: driverProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── BANK DETAILS ──
                    const Text('Bank Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: InputDecoration(
                        labelText: 'Bank Name',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.account_balance),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      hint: const Text('Select Bank'),
                      items: _banks.map((bank) => DropdownMenuItem(
                        value: bank,
                        child: Text(bank),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedBank = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select a bank' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _accountHolderController,
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    // ── MOBILE PAYMENT ──
                    const Text('Mobile Payment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _mobileNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Payment Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // ── QR CODE SECTION ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('QR Code',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (existingQR != null)
                          TextButton.icon(
                            onPressed: _pickQRCode,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Update QR'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: _pickQRCode,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: _qrCodeFile != null
                            ? Stack(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _qrCodeFile!,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'New — Not saved yet',
                                      style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ),
                              ])
                            : existingQR != null
                                ? Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        // ✅ Cache bust for Cloudinary URLs too
                                        existingQR.contains('?')
                                            ? existingQR
                                            : '$existingQR?t=${DateTime.now().millisecondsSinceEpoch}',
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.qr_code,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8, right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Saved ✅',
                                          style: TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ])
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code, size: 56, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Tap to upload QR code',
                                          style: TextStyle(color: Colors.grey)),
                                      SizedBox(height: 4),
                                      Text('Passengers will scan this to pay',
                                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                      ),
                    ),

                    if (_qrCodeFile != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 45,
                        child: _isUploadingQR
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                onPressed: _uploadQRCode,
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload QR Code Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── SAVE BUTTON ──
                    SizedBox(
                      height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _saveDetails,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                'Save Payment Details',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
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