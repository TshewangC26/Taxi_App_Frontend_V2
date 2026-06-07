import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey                   = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading           = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword     = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Show error dialog
  Future<void> _showErrorDialog(String message) async {
    await showDialog(
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
                Container(width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle)),
                Container(width: 62, height: 62,
                    decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle)),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
                ),
              ]),
              const SizedBox(height: 20),
              const Text('Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Try Again',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword:     _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password changed successfully!'),
              backgroundColor: Colors.yellow[800],
            ),
          );
          Navigator.pop(context);
        } else {
          // ✅ Show error dialog instead of red snackbar
          await _showErrorDialog(
            authProvider.errorMessage ?? 'Failed to change password!',
          );
        }
      }
    }
  }

  InputDecoration _fieldDec(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.yellow[800], size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
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
            child: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Change Password',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── HEADER CARD ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    Container(width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle)),
                    Container(width: 62, height: 62,
                        decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle)),
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  const Text('Change your password',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('New password must be at least 12 characters',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ]),
              ),

              const SizedBox(height: 20),

              // ── CURRENT PASSWORD ──
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                decoration: _fieldDec('Current Password', Icons.lock_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                    )),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your current password';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── NEW PASSWORD ──
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                decoration: _fieldDec('New Password', Icons.lock_open_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                    )),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a new password';
                  // ✅ Minimum 12 characters
                  if (value.length < 12) return 'Password must be at least 12 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── CONFIRM PASSWORD ──
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                decoration: _fieldDec('Confirm New Password', Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    )),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your new password';
                  if (value != _newPasswordController.text) return 'Passwords do not match!';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── CHANGE PASSWORD BUTTON ──
              SizedBox(
                height: 56,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text('Change Password',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[800],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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