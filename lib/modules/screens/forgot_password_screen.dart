import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _iconScaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    _iconScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Email not found dialog ────────────────────────────────────
  void _showEmailNotFoundDialog() {
    showDialog(
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
              // Icon
              Stack(alignment: Alignment.center, children: [
                Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                        color: Colors.red[50], shape: BoxShape.circle)),
                Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                        color: Colors.red[100], shape: BoxShape.circle)),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: Colors.red[400], shape: BoxShape.circle),
                  child: const Icon(Icons.email_outlined,
                      color: Colors.white, size: 22),
                ),
              ]),
              const SizedBox(height: 20),
              const Text('Email Not Found',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              const SizedBox(height: 10),
              Text(
                'No registered account was found\nwith this email address.\n\nPlease check your email and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Try Again',
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

  Future<void> _sendResetCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.forgotPassword(
        email: _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reset code sent to your email!'),
              backgroundColor: Colors.yellow[800],
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: _emailController.text.trim(),
                userName: authProvider.resetUserName,
              ),
            ),
          );
        } else {
          // Show styled dialog for unregistered email
          _showEmailNotFoundDialog();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.yellow[200]!),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                color: Colors.yellow[800], size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero icon card ──────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _iconScaleAnim,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Enter your email and we\'ll send you a reset code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Step label ──────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.yellow[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mail_outline,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Email field ─────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(
                          color: Colors.grey[600], fontSize: 14),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Colors.yellow[800], size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.yellow[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.yellow[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.yellow[800]!, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Colors.redAccent, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── Info hint ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.yellow[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.yellow[800], size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A 6-digit reset code will be sent to this email address.',
                            style: TextStyle(
                              color: Colors.yellow[900],
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Send button ─────────────────────────────
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.yellow[800]!),
                          ),
                        )
                      : Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.yellow[800],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _sendResetCode,
                            icon: const Icon(Icons.send_rounded,
                                size: 20),
                            label: const Text(
                              'Send Reset Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[800],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 24),

                  // ── Footer ──────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_taxi,
                            size: 13, color: Colors.yellow[800]),
                        const SizedBox(width: 5),
                        Text(
                          'Online Taxi Service',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
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