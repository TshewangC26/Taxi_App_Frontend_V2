import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../services/api_service.dart';
import 'driver_home_screen.dart';
import 'driver_my_rides_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_profile_screen.dart';
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class DriverAvailableRidesScreen extends StatefulWidget {
  const DriverAvailableRidesScreen({super.key});

  @override
  State<DriverAvailableRidesScreen> createState() =>
      _DriverAvailableRidesScreenState();
}

class _DriverAvailableRidesScreenState
    extends State<DriverAvailableRidesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final int _currentIndex = 1;

  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};

  double? _driverLat;
  double? _driverLng;
  StreamSubscription? _driverLocationSubscription;

  double? _passengerLat;
  double? _passengerLng;
  StreamSubscription? _passengerLocationSubscription;

  int? _activePassengerId;
  bool _nearPassenger = false;

  static const String _apiKey = 'AIzaSyARq6dwj2ZA34rccWeY1EpynZA64YR9vY0';

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false)
          .getAvailableBookings()
          .then((_) {
        final dp = Provider.of<DriverProvider>(context, listen: false);
        for (final booking in dp.myActiveBookings) {
          final passengerId = booking['passenger_id'];
          final status = booking['status'] ?? '';
          if (passengerId != null &&
              (status == 'accepted' || status == 'in_progress')) {
            _startPassengerTracking(passengerId);
            final pLat = double.tryParse(booking['passenger_latitude']?.toString() ?? '');
            final pLng = double.tryParse(booking['passenger_longitude']?.toString() ?? '');
            if (pLat != null && pLng != null) {
              _updateMarkers(staticPassengerLat: pLat, staticPassengerLng: pLng);
            }
            break;
          }
        }
      });
      _startDriverLocationTracking();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _driverLocationSubscription?.cancel();
    _passengerLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _callPassenger(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverHomeScreen()),
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (r) => false,
        );
        break;
      case 2:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverMyRidesScreen()),
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

  void _goToMyRides() {
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const DriverMyRidesScreen()),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  // ✅ Hamburger menu
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

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData iconData,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80,
                  decoration: BoxDecoration(color: confirmColor.withOpacity(0.07), shape: BoxShape.circle)),
              Container(width: 62, height: 62,
                  decoration: BoxDecoration(color: confirmColor.withOpacity(0.12), shape: BoxShape.circle)),
              Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: confirmColor, shape: BoxShape.circle),
                  child: Icon(iconData, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
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
                  child: const Text('No', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor, foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(confirmText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
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
        await dp.getAvailableBookings();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Scheduled ride cancelled'), backgroundColor: Colors.grey[800]),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.grey[800]),
          );
        }
      }
    }
  }

  Future<void> _startDriverLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() { _driverLat = position.latitude; _driverLng = position.longitude; });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15));
        _updateMarkers();
      }
      _driverLocationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((Position pos) {
        if (!mounted) return;
        setState(() { _driverLat = pos.latitude; _driverLng = pos.longitude; });
        _updateMarkers();
        if (_passengerLat != null && _passengerLng != null) {
          _drawRoute(LatLng(pos.latitude, pos.longitude), LatLng(_passengerLat!, _passengerLng!));
          final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, _passengerLat!, _passengerLng!);
          setState(() => _nearPassenger = distance <= 500);
        }
      });
    } catch (e) {
      debugPrint('Driver location error: $e');
    }
  }

  void _startPassengerTracking(int passengerId) {
    _passengerLocationSubscription?.cancel();
    _activePassengerId = passengerId;
    _passengerLocationSubscription = FirebaseDatabase.instance
        .ref('passengers/$passengerId')
        .onValue
        .listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data == null) return;
      final d = Map<String, dynamic>.from(data as Map);
      final lat = double.tryParse(d['latitude']?.toString() ?? '');
      final lng = double.tryParse(d['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        setState(() { _passengerLat = lat; _passengerLng = lng; });
        _updateMarkers();
        if (_driverLat != null && _driverLng != null) {
          _drawRoute(LatLng(_driverLat!, _driverLng!), LatLng(lat, lng));
          final distance = Geolocator.distanceBetween(_driverLat!, _driverLng!, lat, lng);
          setState(() => _nearPassenger = distance <= 500);
        }
      }
    });
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      if (data['routes'].isEmpty) return;
      final points = data['routes'][0]['overview_polyline']['points'];
      final polylinePoints = _decodePolyline(points);
      if (!mounted) return;
      setState(() {
        _polylines.clear();
        _polylines[const PolylineId('route')] = Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.yellow[800]!,
          width: 5,
        );
      });
      if (polylinePoints.isNotEmpty) {
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(_getBounds(origin, destination), 80));
      }
    } catch (e) {
      debugPrint('Route error: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  LatLngBounds _getBounds(LatLng o, LatLng d) => LatLngBounds(
    southwest: LatLng(o.latitude < d.latitude ? o.latitude : d.latitude,
        o.longitude < d.longitude ? o.longitude : d.longitude),
    northeast: LatLng(o.latitude > d.latitude ? o.latitude : d.latitude,
        o.longitude > d.longitude ? o.longitude : d.longitude),
  );

  void _updateMarkers({double? staticPassengerLat, double? staticPassengerLng}) {
    if (!mounted) return;
    final markers = <MarkerId, Marker>{};
    if (_driverLat != null && _driverLng != null) {
      markers[const MarkerId('driver')] = Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(_driverLat!, _driverLng!),
        infoWindow: const InfoWindow(title: 'My Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }
    final pLat = _passengerLat ?? staticPassengerLat;
    final pLng = _passengerLng ?? staticPassengerLng;
    if (pLat != null && pLng != null) {
      markers[const MarkerId('passenger')] = Marker(
        markerId: const MarkerId('passenger'),
        position: LatLng(pLat, pLng),
        infoWindow: const InfoWindow(title: 'Passenger Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }
    setState(() { _markers.clear(); _markers.addAll(markers); });
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) { return dateStr; }
  }

  String _formatScheduledDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) { return dateStr; }
  }

  String _formatScheduledTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) { return timeStr; }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DriverProvider>(context);
    final totalPending = dp.nowBookings.length + dp.scheduledBookings.length;
    final currentCount = dp.nowBookings.length + dp.myActiveBookings.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Text('Easy Ride',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: 0.3)),
        ]),
        actions: [
          InkWell(
            onTap: () { dp.getAvailableBookings(); _startDriverLocationTracking(); },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 20),
            ),
          ),
          // ✅ Hamburger menu replaces logout button
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.yellow[800],
              indicatorWeight: 3,
              labelColor: Colors.yellow[800],
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.directions_car_rounded, size: 16),
                    const SizedBox(width: 6),
                    const Text('Current'),
                    if (currentCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(10)),
                        child: Text('$currentCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ]),
                ),
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.calendar_today_rounded, size: 16),
                    const SizedBox(width: 6),
                    const Text('Scheduled'),
                    if (dp.scheduledBookings.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(10)),
                        child: Text('${dp.scheduledBookings.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ]),
                ),
              ],
            ),
          ),
        ),
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
      body: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
          child: SizedBox(
            height: 200,
            child: _driverLat != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(_driverLat!, _driverLng!), zoom: 15),
                    onMapCreated: (c) => _mapController = c,
                    mapType: MapType.hybrid,
                    markers: Set<Marker>.of(_markers.values),
                    polylines: Set<Polyline>.of(_polylines.values),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)),
                      const SizedBox(height: 10),
                      Text('Getting your location...', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ]),
                  ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('You', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(width: 14),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Passenger', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(width: 14),
            Container(width: 18, height: 3, color: Colors.yellow[800]),
            const SizedBox(width: 5),
            Text('Route', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
        ),
        Expanded(
          child: dp.isLoading
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentTab(context, dp),
                    _buildScheduledTab(context, dp),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _buildCurrentTab(BuildContext context, DriverProvider dp) {
    final hasAnything = dp.nowBookings.isNotEmpty || dp.myActiveBookings.isNotEmpty;
    if (!hasAnything) {
      return _buildEmptyState(icon: Icons.directions_car_rounded, message: 'No current rides', hint: 'Make sure you are online to see rides');
    }
    return RefreshIndicator(
      color: Colors.yellow[800],
      onRefresh: () => dp.getAvailableBookings(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (dp.myActiveBookings.isNotEmpty) ...[
            _buildSectionHeader('My Active Ride', const Color(0xFFE65100), dp.myActiveBookings.length),
            const SizedBox(height: 10),
            ...dp.myActiveBookings.map((b) => _buildBookingCard(context, b, dp, cardType: 'active')),
            const SizedBox(height: 20),
          ],
          if (dp.nowBookings.isNotEmpty) ...[
            _buildSectionHeader('Pending Bookings', const Color(0xFF1565C0), dp.nowBookings.length),
            const SizedBox(height: 10),
            ...dp.nowBookings.map((b) => _buildBookingCard(context, b, dp, cardType: 'pending')),
          ],
        ]),
      ),
    );
  }

  Widget _buildScheduledTab(BuildContext context, DriverProvider dp) {
    if (dp.scheduledBookings.isEmpty) {
      return _buildEmptyState(icon: Icons.calendar_today_rounded, message: 'No scheduled rides', hint: 'Scheduled rides will appear here');
    }
    return RefreshIndicator(
      color: Colors.yellow[800],
      onRefresh: () => dp.getAvailableBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        itemCount: dp.scheduledBookings.length,
        itemBuilder: (context, index) => _buildBookingCard(context, dp.scheduledBookings[index], dp, cardType: 'scheduled'),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message, required String hint}) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(icon, size: 38, color: Colors.grey[300])),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
        const SizedBox(height: 6),
        Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey[400]), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Row(children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
        child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    ]);
  }

  Widget _buildBookingCard(BuildContext context, dynamic booking, DriverProvider dp, {required String cardType}) {
    final status = booking['status'] ?? '';
    final isScheduled = booking['booking_type'] == 'scheduled';

    Color statusColor = const Color(0xFF1565C0);
    if (status == 'accepted') statusColor = const Color(0xFFE65100);
    if (status == 'in_progress') statusColor = const Color(0xFF2E7D32);

    final passengerLat = double.tryParse(booking['passenger_latitude']?.toString() ?? '');
    final passengerLng = double.tryParse(booking['passenger_longitude']?.toString() ?? '');
    final passengerId = booking['passenger_id'];
    final passengerPhone =
        booking['passenger']?['phone']?.toString() ??
        booking['passenger']?['phone_number']?.toString() ??
        booking['passenger']?['mobile']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Text(status.isEmpty ? 'Pending' : _capitalize(status),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            Text('#${booking['id']}', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
          ]),

          const SizedBox(height: 14),

          if (isScheduled && booking['scheduled_date'] != null && booking['scheduled_time'] != null) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFF5E35B1), size: 16),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Scheduled for', style: TextStyle(color: Color(0xFF5E35B1), fontSize: 11)),
                  Text(
                    '${_formatScheduledDate(booking['scheduled_date'])}  •  ${_formatScheduledTime(booking['scheduled_time'])}',
                    style: const TextStyle(color: Color(0xFF4527A0), fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ])),
              ]),
            ),
          ],

          Row(children: [
            Container(width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, size: 18, color: Colors.grey[500])),
            const SizedBox(width: 10),
            Text(booking['passenger']?['name'] ?? 'Unknown Passenger',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          ]),

          const SizedBox(height: 12),

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
            Text('Nu. ${booking['estimated_price'] ?? '0'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.yellow[800])),
          ]),

          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text('Booked: ${_formatDate(booking['created_at'] ?? '')}',
                style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ]),

          const SizedBox(height: 16),

          if (cardType == 'active' && _nearPassenger) ...[
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (passengerPhone.isNotEmpty) {
                    _callPassenger(passengerPhone);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passenger phone number not available')));
                  }
                },
                icon: const Icon(Icons.call_rounded, size: 20),
                label: const Text('Call Passenger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600], foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (cardType == 'pending')
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await _confirmDialog(context,
                        title: 'Cancel Booking', message: 'Are you sure you want to cancel this booking?',
                        confirmText: 'Yes, Cancel', confirmColor: Colors.red[400]!, iconData: Icons.cancel_rounded);
                    if (confirmed == true && context.mounted) await dp.cancelBooking(booking['id']);
                  },
                  icon: Icon(Icons.close_rounded, color: Colors.red[400], size: 16),
                  label: Text('Cancel', style: TextStyle(color: Colors.red[400])),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _confirmDialog(context,
                        title: 'Accept Booking', message: 'Accept this booking? You will be navigated to My Rides.',
                        confirmText: 'Yes, Accept', confirmColor: const Color(0xFF2E7D32), iconData: Icons.check_circle_rounded);
                    if (confirmed == true && context.mounted) {
                      final success = await dp.acceptBooking(booking['id']);
                      if (success && context.mounted) {
                        if (passengerLat != null && passengerLng != null) {
                          _updateMarkers(staticPassengerLat: passengerLat, staticPassengerLng: passengerLng);
                          if (_driverLat != null) _drawRoute(LatLng(_driverLat!, _driverLng!), LatLng(passengerLat, passengerLng));
                        }
                        if (passengerId != null) _startPassengerTracking(passengerId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Booking accepted!'), backgroundColor: Colors.yellow[800]),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),

          if (cardType == 'scheduled' && (booking['status'] == 'pending'))
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelScheduledWithReason(context, booking, dp),
                  icon: Icon(Icons.close_rounded, color: Colors.red[400], size: 16),
                  label: Text('Cancel', style: TextStyle(color: Colors.red[400])),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _confirmDialog(context,
                        title: 'Accept Scheduled Ride', message: 'Your status stays Available until the ride starts.',
                        confirmText: 'Yes, Accept', confirmColor: const Color(0xFF5E35B1), iconData: Icons.calendar_today_rounded);
                    if (confirmed == true && context.mounted) {
                      final success = await dp.acceptScheduledBooking(booking['id']);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Scheduled ride accepted! Check My Rides.'), backgroundColor: Colors.yellow[800]),
                        );
                        _goToMyRides();
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E35B1), foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),

          if (cardType == 'scheduled' && booking['status'] == 'accepted')
            SizedBox(width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _cancelScheduledWithReason(context, booking, dp),
                icon: Icon(Icons.cancel_outlined, color: Colors.red[400], size: 18),
                label: Text('Cancel Scheduled Ride', style: TextStyle(color: Colors.red[400])),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          if (cardType == 'active' && status == 'accepted')
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await dp.startRide(booking['id']);
                  if (success && context.mounted) {
                    if (passengerLat != null && passengerLng != null) {
                      _updateMarkers(staticPassengerLat: passengerLat, staticPassengerLng: passengerLng);
                      if (_driverLat != null) _drawRoute(LatLng(_driverLat!, _driverLng!), LatLng(passengerLat, passengerLng));
                    }
                    if (passengerId != null) _startPassengerTracking(passengerId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Ride started!'), backgroundColor: Colors.yellow[800]),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Start Ride', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          if (cardType == 'active' && status == 'in_progress')
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmDialog(context,
                      title: 'Complete Ride', message: 'Are you sure you want to complete this ride?',
                      confirmText: 'Complete', confirmColor: const Color(0xFF2E7D32), iconData: Icons.done_all_rounded);
                  if (confirmed == true && context.mounted) {
                    final success = await dp.completeRide(booking['id']);
                    if (success && context.mounted) {
                      _passengerLocationSubscription?.cancel();
                      setState(() { _passengerLat = null; _passengerLng = null; _polylines.clear(); _nearPassenger = false; });
                      _updateMarkers();
                      await dp.getAvailableBookings();
                      if (context.mounted) _showPaymentDialog(context, booking, dp);
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Complete Ride', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}