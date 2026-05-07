import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  Uint8List? _webImage;
  String? _imagePath;

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

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImage       = bytes;
          _imagePath      = image.path;
          _selectedImage  = null;
        });
      } else {
        setState(() {
          _selectedImage = File(image.path);
          _imagePath     = image.path;
          _webImage      = null;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.updateProfile(
        name:      _nameController.text,
        phone:     _phoneController.text,
        imagePath: _imagePath,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: Colors.yellow[800],
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  authProvider.errorMessage ?? 'Update failed!'),
              backgroundColor: Colors.grey[800],
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileImage(dynamic user) {
    if (_webImage != null) {
      return ClipOval(
        child: Image.memory(_webImage!,
            width: 88, height: 88, fit: BoxFit.cover),
      );
    } else if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(_selectedImage!,
            width: 88, height: 88, fit: BoxFit.cover),
      );
    } else if (user?.profilePhoto != null) {
      return ClipOval(
        child: Image.network(
          user!.profilePhoto!,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, size: 44, color: Colors.white),
        ),
      );
    } else {
      return const Icon(Icons.person, size: 44, color: Colors.white);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon,
      {String? helper, bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      labelStyle: TextStyle(
          color: enabled ? Colors.grey[600] : Colors.grey[400],
          fontSize: 14),
      prefixIcon: Icon(icon,
          color: enabled ? Colors.yellow[800] : Colors.grey[400], size: 20),
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

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
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── BODY ─────────────────────────────────────────────
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

                  // ── AVATAR CARD ───────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            // Avatar with yellow ring
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.yellow[700]!, width: 2.5),
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.yellow[800],
                                child: _buildProfileImage(user),
                              ),
                            ),
                            // Camera button
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[800],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap the icon to change photo',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── FIELDS SECTION ────────────────────────
                  const _SectionLabel(title: 'Personal Information'),
                  const SizedBox(height: 12),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 15),
                    decoration: _fieldDecoration(
                        'Full Name', Icons.badge_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 15),
                    decoration: _fieldDecoration(
                        'Phone Number', Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email (read-only)
                  TextFormField(
                    initialValue: user?.email ?? '',
                    enabled: false,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 15),
                    decoration: _fieldDecoration(
                      'Email',
                      Icons.mail_outline_rounded,
                      helper: 'Email cannot be changed',
                      enabled: false,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── SAVE BUTTON ───────────────────────────
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
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
                                  fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[800],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
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

// ── Section label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 0.1,
      ),
    );
  }
}