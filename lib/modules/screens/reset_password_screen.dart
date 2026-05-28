import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screens.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String? userName;
  final String userType;
  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.userName,
    required this.userType,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey                   = GlobalKey<FormState>();
  final _codeController            = TextEditingController();
  final _newPasswordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading           = false;
  bool _isResending         = false; // ✅ resend loading
  bool _showNewPassword     = false;
  bool _showConfirmPassword = false;

  // ✅ Countdown timer
  late Timer _timer;
  int _secondsLeft = 300; // 5 minutes
  bool _codeExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _codeExpired = true;
          _timer.cancel();
        }
      });
    });
  }

  // ✅ Resend code — stays on same screen and resets timer
  Future<void> _resendCode() async {
    setState(() => _isResending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.forgotPassword(
      email: widget.email,
      userType: widget.userType,
    );

    setState(() => _isResending = false);

    if (!mounted) return;

    if (success) {
      // ✅ Reset timer and clear old code
      _timer.cancel();
      _codeController.clear();
      setState(() {
        _secondsLeft = 300;
        _codeExpired = false;
      });
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New reset code sent to your email!'),
          backgroundColor: Colors.yellow[800],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String get _timerText {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color get _timerColor {
    if (_secondsLeft > 120) return Colors.green;
    if (_secondsLeft > 60) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
              const Text('Reset Failed',
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

  // ✅ Show expired dialog — resends code directly, no navigation
  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                    decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle)),
                Container(width: 62, height: 62,
                    decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle)),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.orange[700], shape: BoxShape.circle),
                  child: const Icon(Icons.timer_off_rounded, color: Colors.white, size: 24),
                ),
              ]),
              const SizedBox(height: 20),
              const Text('Code Expired',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                'Your reset code has expired.\nTap below to get a new one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop(); // close dialog
                    await _resendCode();     // ✅ resend code & reset timer
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Send New Code',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_codeExpired) {
      _showExpiredDialog();
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.resetPassword(
        email:           widget.email,
        token:           _codeController.text.trim(),
        newPassword:     _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginScreen(prefillName: widget.userName),
            ),
            (route) => false,
          );
        } else {
          await _showErrorDialog('Invalid or expired code! Please check your email and try again.');
        }
      }
    }
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
        title: const Text('Reset Password',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // ── INFO BANNER ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A reset code was sent to ${widget.email}',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Countdown Timer Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _codeExpired ? Colors.red[50] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _codeExpired ? Colors.red.shade200 : _timerColor.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _codeExpired ? Icons.timer_off_rounded : Icons.timer_rounded,
                          color: _codeExpired ? Colors.red : _timerColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _codeExpired ? 'Code Expired!' : 'Code expires in:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _codeExpired ? Colors.red : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    if (!_codeExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _timerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _timerText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _timerColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    if (_codeExpired)
                      _isResending
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!),
                              ),
                            )
                          : TextButton(
                              onPressed: _resendCode, // ✅ resend directly
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── RESET CODE ──
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !_codeExpired,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Reset Code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: _codeExpired ? Colors.grey[100] : Colors.white,
                  prefixIcon: Icon(Icons.pin, color: Colors.yellow[800]),
                  helperText: 'Enter the 6 digit code from your email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the reset code';
                  if (value.length != 6) return 'Code must be 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── NEW PASSWORD ──
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                enabled: !_codeExpired,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: _codeExpired ? Colors.grey[100] : Colors.white,
                  prefixIcon: Icon(Icons.lock_open, color: Colors.yellow[800]),
                  helperText: 'Minimum 12 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a new password';
                  if (value.length < 12) return 'Password must be at least 12 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── CONFIRM PASSWORD ──
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                enabled: !_codeExpired,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: _codeExpired ? Colors.grey[100] : Colors.white,
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.yellow[800]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _newPasswordController.text) return 'Passwords do not match!';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── RESET BUTTON ──
              SizedBox(
                height: 56,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _codeExpired ? _showExpiredDialog : _resetPassword,
                        icon: Icon(_codeExpired ? Icons.timer_off_rounded : Icons.lock_reset),
                        label: Text(
                          _codeExpired ? 'Code Expired' : 'Reset Password',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _codeExpired ? Colors.grey : Colors.yellow[800],
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