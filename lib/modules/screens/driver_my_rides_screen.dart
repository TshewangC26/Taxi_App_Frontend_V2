import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../services/api_service.dart';
import 'driver_home_screen.dart';
import 'driver_available_rides_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_profile_screen.dart';
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class DriverMyRidesScreen extends StatefulWidget {
  const DriverMyRidesScreen({super.key});

  @override
  State<DriverMyRidesScreen> createState() => _DriverMyRidesScreenState();
}

class _DriverMyRidesScreenState extends State<DriverMyRidesScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final int _currentIndex = 2;
  final ApiService _apiService = ApiService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRides());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() => _refreshRides();

  @override
  void didPush() => _refreshRides();

  Future<void> _refreshRides() async {
    if (!mounted) return;
    final dp = Provider.of<DriverProvider>(context, listen: false);
    await Future.wait([dp.getMyRides(), dp.getAvailableBookings()]);
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

  Future<void> _callPassenger(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      await _showErrorDialog('Call Failed', 'Could not open the phone dialer.\nPlease check if your phone supports calls.');
    }
  }

  Future<void> _whatsappPassenger(String phone) async {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleaned.startsWith('975')) {
      cleaned = '975$cleaned';
    }
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      await _showErrorDialog('WhatsApp Not Found', 'WhatsApp is not installed on this device.\nPlease install WhatsApp and try again.');
    }
  }

  List<dynamic> _sortedRides(List<dynamic> rides) {
    final scheduled = rides.where((r) => r['booking_type'] == 'scheduled').toList();
    final active = scheduled.where((r) => r['status'] == 'accepted' || r['status'] == 'in_progress').toList();
    final completed = scheduled.where((r) => r['status'] == 'completed').toList();
    return [...active, ...completed];
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverHomeScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ), (r) => false);
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverAvailableRidesScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        break;
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverEarningsScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        break;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverProfileScreen()),
          transitionDuration: const Duration(milliseconds: 300),
        ));
        break;
    }
  }

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
            icon: Icons.headset_mic_rounded,
            iconColor: Colors.yellow[800]!,
            iconBg: Colors.yellow[50]!,
            title: 'Contact Us',
            subtitle: 'Get in touch with our support team',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()));
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.blue[700]!,
            iconBg: Colors.blue[50]!,
            title: 'About Us',
            subtitle: 'Learn more about Easy Ride',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen()));
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(
            icon: Icons.logout_rounded,
            iconColor: Colors.red[400]!,
            iconBg: Colors.red[50]!,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () {
              Navigator.pop(ctx);
              _confirmLogout();
            },
          ),
        ]),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
          ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle)),
              Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 20),
            const Text('Logging Out?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Would you like to logout from\nEasy Ride?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: Colors.black54,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Yes, Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
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
          PageRouteBuilder(
            pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const LoginScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (r) => false,
        );
      }
    }
  }

  bool _isTimeToStart(dynamic booking) {
    try {
      final dateStr = booking['scheduled_date'] ?? '';
      final timeStr = booking['scheduled_time'] ?? '';
      if (dateStr.isEmpty || timeStr.isEmpty) return true;
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(':')[0]);
      final scheduledDateTime = DateTime.parse(dateStr).copyWith(hour: hour, minute: minute);
      return DateTime.now().isAfter(scheduledDateTime);
    } catch (_) { return true; }
  }

  String _formatScheduledDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) { return dateStr; }
  }

  String _formatScheduledTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1].split(':')[0].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) { return timeStr; }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':    return const Color(0xFF1565C0);
      case 'in_progress': return const Color(0xFFE65100);
      case 'completed':   return const Color(0xFF2E7D32);
      default:            return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':    return Icons.check_circle_rounded;
      case 'in_progress': return Icons.directions_car_rounded;
      case 'completed':   return Icons.done_all_rounded;
      default:            return Icons.info_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':    return 'Accepted';
      case 'in_progress': return 'On the Way';
      case 'completed':   return 'Completed';
      default:            return status;
    }
  }

  Future<void> _cancelScheduledWithReason(BuildContext context, dynamic booking, DriverProvider dp) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Stack(alignment: Alignment.center, children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle)),
                Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle)),
                Container(width: 46, height: 46,
                    decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle),
                    child: const Icon(Icons.cancel_rounded, color: Colors.white, size: 22)),
              ]),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Cancel Scheduled Ride?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87))),
            const SizedBox(height: 6),
            Center(child: Text('Please provide a reason for cancellation.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Family emergency, vehicle breakdown, etc.',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true, fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: Colors.black54,
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
                      return;
                    }
                    Navigator.of(ctx).pop(reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Confirm Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (result != null && context.mounted) {
      try {
        await _apiService.post('/bookings/${booking['id']}/cancel', {'cancellation_reason': result});
        await _refreshRides();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Scheduled ride cancelled'), backgroundColor: Colors.grey[800]),
          );
        }
      } catch (e) {
        if (context.mounted) {
          await _showErrorDialog('Cancellation Failed', 'Could not cancel the ride.\nPlease check your connection and try again.');
        }
      }
    }
  }

  void _showPaymentDialog(BuildContext context, dynamic booking, DriverProvider dp) {
    final amount = booking['estimated_price'] ?? '0';
    final profile = dp.driverProfile;
    final accountNumber = profile?['account_number'] ?? '';
    final mobileNumber = profile?['mobile_payment_number'] ?? '';
    final qrCodeUrl = profile?['qr_code_image'];

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle),
                child: Icon(Icons.payment_rounded, color: Colors.yellow[800], size: 26)),
            const SizedBox(height: 14),
            const Text('Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('Nu. $amount', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.yellow[800])),
            const SizedBox(height: 6),
            Text('How did the passenger pay?', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showCashConfirmation(context, amount); },
                  icon: const Icon(Icons.money_rounded, size: 18),
                  label: const Text('Cash'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showOnlinePaymentDetails(context, amount, accountNumber, mobileNumber, qrCodeUrl); },
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: const Text('Online'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showCashConfirmation(BuildContext context, String amount) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.money_rounded, color: Color(0xFF2E7D32), size: 26)),
            const SizedBox(height: 14),
            const Text('Cash Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('Collect from passenger:', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 4),
            Text('Nu. $amount', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showOnlinePaymentDetails(BuildContext context, String amount,
      String accountNumber, String mobileNumber, String? qrCodeUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                  child: Icon(Icons.qr_code_rounded, color: Colors.blue[700], size: 26)),
              const SizedBox(height: 14),
              const Text('Online Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('Amount to receive:', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              Text('Nu. $amount', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.yellow[800])),
              const SizedBox(height: 16),
              if (qrCodeUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(qrCodeUrl, width: 180, height: 180, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.qr_code_rounded, size: 80, color: Colors.grey[300])),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Icon(Icons.qr_code_rounded, size: 80, color: Colors.grey[300]),
                Text('No QR code uploaded', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 16),
              ],
              if (accountNumber.isNotEmpty || mobileNumber.isNotEmpty) ...[
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(children: [
                    if (accountNumber.isNotEmpty)
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Account No', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        Text(accountNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                      ]),
                    if (accountNumber.isNotEmpty && mobileNumber.isNotEmpty)
                      Divider(height: 16, color: Colors.grey.shade200),
                    if (mobileNumber.isNotEmpty)
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Mobile No', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        Text(mobileNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                      ]),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRide(BuildContext context, dynamic booking, DriverProvider dp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 28)),
            const SizedBox(height: 16),
            const Text('Delete Ride', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Remove this completed ride\nfrom your list?',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.black54,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await dp.deleteRide(booking['id']);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Ride removed'), backgroundColor: Colors.grey[800]),
          );
        }
      } catch (e) {
        if (context.mounted) {
          await _showErrorDialog('Delete Failed', 'Could not remove this ride.\nPlease try again.');
        }
      }
    }
  }

  Future<void> _showCompleteConfirmation(BuildContext context, dynamic booking, DriverProvider dp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.done_all_rounded, color: Color(0xFF2E7D32), size: 26)),
            const SizedBox(height: 14),
            const Text('Complete Ride?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Are you sure you want to\ncomplete this ride?',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.black54,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Complete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await dp.completeRide(booking['id']);
      if (success && context.mounted) _showPaymentDialog(context, booking, dp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DriverProvider>(context);
    final sortedRides = _sortedRides(dp.myRides);
    final totalPending = dp.nowBookings.length + dp.scheduledBookings.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
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
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: InkWell(
              onTap: _openMenu,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(Icons.menu_rounded, color: Colors.grey[700], size: 22),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.list_alt_outlined),
                if (totalPending > 0)
                  Positioned(top: -4, right: -6,
                    child: Container(width: 14, height: 14,
                        decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                        child: Center(child: Text('$totalPending',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))))),
              ]),
              activeIcon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.list_alt_rounded),
                if (totalPending > 0)
                  Positioned(top: -4, right: -6,
                    child: Container(width: 14, height: 14,
                        decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                        child: Center(child: Text('$totalPending',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))))),
              ]),
              label: 'Rides',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'My Rides'),
            const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Earnings'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      body: dp.isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
          : sortedRides.isEmpty
              ? FadeTransition(
                  opacity: _fadeAnim,
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 80, height: 80,
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: Icon(Icons.history_rounded, size: 38, color: Colors.grey[300])),
                      const SizedBox(height: 16),
                      Text('No scheduled rides yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                      const SizedBox(height: 6),
                      Text('Accepted scheduled rides will appear here',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _refreshRides,
                        icon: Icon(Icons.refresh_rounded, color: Colors.yellow[800], size: 18),
                        label: Text('Refresh', style: TextStyle(color: Colors.yellow[800], fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.yellow[200]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ]),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: RefreshIndicator(
                    color: Colors.yellow[800],
                    onRefresh: _refreshRides,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: sortedRides.length,
                      itemBuilder: (context, index) => _buildRideCard(context, sortedRides[index], dp),
                    ),
                  ),
                ),
    );
  }

  Widget _buildRideCard(BuildContext context, dynamic booking, DriverProvider dp) {
    final status = booking['status'] ?? '';
    final timeArrived = _isTimeToStart(booking);
    final sc = _statusColor(status);

    final passenger = booking['passenger'];
    final passengerName = passenger?['name'] ?? booking['passenger_name'] ?? 'Passenger';
    final passengerPhone = passenger?['phone'] ?? passenger?['mobile'] ?? booking['passenger_phone'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sc.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_statusIcon(status), size: 14, color: sc),
                const SizedBox(width: 5),
                Text(_statusLabel(status), style: TextStyle(color: sc, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
            Text('#${booking['id']}', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
          ]),

          const SizedBox(height: 14),

          if (booking['scheduled_date'] != null && booking['scheduled_time'] != null)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: timeArrived ? const Color(0xFFE8F5E9) : const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(
                  timeArrived ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                  color: timeArrived ? const Color(0xFF2E7D32) : const Color(0xFF5E35B1), size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(timeArrived ? 'Time to start the ride!' : 'Scheduled for',
                      style: TextStyle(color: timeArrived ? const Color(0xFF2E7D32) : const Color(0xFF5E35B1), fontSize: 11)),
                  Text(
                    '${_formatScheduledDate(booking['scheduled_date'])}  •  ${_formatScheduledTime(booking['scheduled_time'])}',
                    style: TextStyle(
                      color: timeArrived ? const Color(0xFF1B5E20) : const Color(0xFF4527A0),
                      fontWeight: FontWeight.w700, fontSize: 13,
                    ),
                  ),
                ])),
              ]),
            ),

          // ── Passenger info with call + WhatsApp ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle),
                  child: Icon(Icons.person_rounded, color: Colors.yellow[800], size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(passengerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
                if (passengerPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(passengerPhone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ] else
                  Text('No phone available', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ])),
              if (passengerPhone.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  // ✅ Call button
                  GestureDetector(
                    onTap: () => _callPassenger(passengerPhone),
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.call_rounded, color: Color(0xFF2E7D32), size: 18)),
                  ),
                  const SizedBox(width: 8),
                  // ✅ WhatsApp button
                  GestureDetector(
                    onTap: () => _whatsappPassenger(passengerPhone),
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18)),
                  ),
                ]),
            ]),
          ),

          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(booking['pickup_location'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
          ]),
          Padding(padding: const EdgeInsets.only(left: 3.5), child: Container(width: 1, height: 10, color: Colors.grey.shade300)),
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(booking['dropoff_location'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
          ]),

          const SizedBox(height: 14),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.directions_car_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(booking['vehicle_type'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
              ]),
            ),
            Text('Nu. ${booking['final_price'] ?? booking['estimated_price'] ?? '0'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.yellow[800])),
          ]),

          const SizedBox(height: 16),

          if (status == 'accepted') ...[
            if (timeArrived)
              SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final success = await dp.startRide(booking['id']);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Ride started!'), backgroundColor: Colors.yellow[800]),
                      );
                      _refreshRides();
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start Ride', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.access_time_rounded, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 8),
                  Text('Start button appears at ride time', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelScheduledWithReason(context, booking, dp),
                  icon: Icon(Icons.cancel_outlined, color: Colors.red[400], size: 18),
                  label: Text('Cancel Scheduled Ride', style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w600, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],

          if (status == 'in_progress')
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showCompleteConfirmation(context, booking, dp),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Complete Ride', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          if (status == 'completed') ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.done_all_rounded, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Text('Ride Completed', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _deleteRide(context, booking, dp),
                icon: const Icon(Icons.delete_rounded, size: 17),
                label: const Text('Delete Ride', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}