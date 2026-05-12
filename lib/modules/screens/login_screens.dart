import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'passenger_home_screen.dart';
import 'driver_home_screen.dart';
import 'admin_home_screen.dart';
import 'forgot_password_screen.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillName;
  const LoginScreen({super.key, this.prefillName});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillName != null) {
      _nameController.text = widget.prefillName!;
    }
    _loadPrefillName();
  }

  Future<void> _loadPrefillName() async {
    final prefs = await SharedPreferences.getInstance();

    final prefillName = prefs.getString('prefill_name');
    if (prefillName != null && mounted && _nameController.text.isEmpty) {
      setState(() {
        _nameController.text = prefillName;
      });
      await prefs.remove('prefill_name');
      await prefs.setString('last_login_name', prefillName);
      return;
    }

    final lastLoginName = prefs.getString('last_login_name');
    if (lastLoginName != null &&
        mounted &&
        _nameController.text.isEmpty) {
      setState(() {
        _nameController.text = lastLoginName;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Info menu (Contact Us / About Us) ─────────────────────────
  void _showInfoMenu() {
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
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('More Info',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 16),
            _infoTile(
              icon: Icons.headset_mic_rounded,
              iconBg: Colors.yellow[50]!,
              iconColor: Colors.yellow[800]!,
              label: 'Contact Us',
              subtitle: 'Get in touch with our support team',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => FadeTransition(
                        opacity: a, child: const ContactUsScreen()),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _infoTile(
              icon: Icons.info_outline_rounded,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
              label: 'About Us',
              subtitle: 'Learn more about Easy Ride',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => FadeTransition(
                        opacity: a, child: const AboutUsScreen()),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey[300], size: 22),
        ]),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      String? fcmToken;
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
            alert: true, badge: true, sound: true);
        fcmToken = await messaging.getToken();
      } catch (e) {
        print('FCM token error: $e');
      }

      final success = await authProvider.login(
        _nameController.text.trim(),
        _passwordController.text,
        fcmToken: fcmToken,
      );

      if (success && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'last_login_name', _nameController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
            backgroundColor: Colors.yellow[800],
          ),
        );

        final userType = authProvider.user?.userType;

        if (userType == 'passenger') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PassengerHomeScreen()),
          );
        } else if (userType == 'driver') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const DriverHomeScreen()),
          );
        } else if (userType == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminHomeScreen()),
          );
        }
      } else if (mounted) {
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
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                        color: Colors.red[50], shape: BoxShape.circle),
                    child: Icon(Icons.error_outline_rounded,
                        color: Colors.red[400], size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text('Login Failed',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(
                    'Invalid username or password.\nPlease check your credentials and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        actions: [
          // ── Info icon → Contact Us / About Us ──────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _showInfoMenu,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(Icons.info_outline_rounded,
                    color: Colors.yellow[800], size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Easy Ride',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          letterSpacing: 2.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/taxi_logo.png',
                        width: 200, height: 200,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.yellow[800]!, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person_outline,
                        color: Colors.yellow[800]),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.yellow[800]!, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock_outline,
                        color: Colors.yellow[800]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.yellow[800],
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                authProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.yellow[800]!),
                        ),
                      )
                    : SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_filled,
                                  size: 20),
                              SizedBox(width: 10),
                              Text('Login',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RegisterScreen()),
                      );
                      if (mounted) {
                        await _loadPrefillName();
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(
                              text: "Don't have an account? "),
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(
                              color: Colors.yellow[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                          color: Colors.yellow[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_taxi,
                          size: 14, color: Colors.yellow[800]),
                      const SizedBox(width: 6),
                      Text('Online Taxi Service',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}