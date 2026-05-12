import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screens.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String? userName;
  const ResetPasswordScreen({super.key, required this.email, this.userName});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.resetPassword(
        email: widget.email,
        token: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
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
              builder: (context) => LoginScreen(
                prefillName: widget.userName,
              ),
            ),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  authProvider.errorMessage ?? 'Failed to reset password!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 24),

              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Reset Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                  helperText: 'Enter the 6 digit code from your email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the reset code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_open),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text(
                          'Reset Password',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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