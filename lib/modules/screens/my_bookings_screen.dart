import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/firebase_services.dart';
import '../services/api_service.dart';
import '../models/booking.dart';
import 'passenger_home_screen.dart';
import 'book_ride_screen.dart';
import 'profile_screen.dart';
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_us_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<int, StreamSubscription> _bookingSubscriptions = {};
  final Map<int, String> _firebaseStatuses = {};

  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _mapMarkers = {};
  final Map<PolylineId, Polyline> _polylines = {};

  double? _passengerLat;
  double? _passengerLng;
  StreamSubscription? _locationSubscription;

  double? _driverLat;
  double? _driverLng;
  StreamSubscription? _driverLocationSubscription;

  Booking? _activeBooking;

  final int _currentIndex = 2;
  final ApiService _apiService = ApiService();

  final Set<int> _ratingShownForBookings = {};
  // ✅ Track which scheduled cancellation dialogs have been shown
  final Set<int> _scheduledCancelDialogShown = {};

  static const String _apiKey = 'AIzaSyARq6dwj2ZA34rccWeY1EpynZA64YR9vY0';

  int? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      Provider.of<BookingProvider>(context, listen: false)
          .getPassengerBookings()
          .then((_) {
        _listenToBookingStatuses();
        _startPassengerLocationTracking();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _mapController?.dispose();
    for (var sub in _bookingSubscriptions.values) {
      sub.cancel();
    }
    if (_userId != null) {
      FirebaseService.removePassengerLocation(_userId!);
    }
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(context, PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const PassengerHomeScreen()),
        transitionDuration: const Duration(milliseconds: 300),
      ), (route) => false);
      return;
    }
    if (index == 1) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const BookRideScreen()),
        transitionDuration: const Duration(milliseconds: 300),
      ));
      return;
    }
    if (index == 3) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const ProfileScreen()),
        transitionDuration: const Duration(milliseconds: 300),
      ));
      return;
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
          _menuItem(icon: Icons.headset_mic_rounded, iconColor: Colors.yellow[800]!, iconBg: Colors.yellow[50]!,
            title: 'Contact Us', subtitle: 'Get in touch with our support team',
            onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen())); }),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(icon: Icons.info_outline_rounded, iconColor: Colors.blue[700]!, iconBg: Colors.blue[50]!,
            title: 'About Us', subtitle: 'Learn more about Easy Ride',
            onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())); }),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(icon: Icons.logout_rounded, iconColor: Colors.red[400]!, iconBg: Colors.red[50]!,
            title: 'Logout', subtitle: 'Sign out of your account',
            onTap: () { Navigator.pop(ctx); _confirmLogout(); }),
        ]),
      ),
    );
  }

  Widget _menuItem({required IconData icon, required Color iconColor, required Color iconBg,
      required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: Colors.black54),
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

  // ✅ Call driver
  Future<void> _callDriver(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
  } else if (mounted) {
      await _showErrorDialog('Call Failed', 'Could not open the phone dialer.\nPlease check if your phone supports calls.');
    }
  }

  // ✅ WhatsApp driver
  Future<void> _whatsappDriver(String phone) async {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleaned.startsWith('975')) cleaned = '975$cleaned';
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      await _showErrorDialog('WhatsApp Not Found', 'WhatsApp is not installed on this device.\nPlease install WhatsApp and try again.');
    }
  }

  bool _isToday(String createdAt) {
    try {
      final bookedDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      return bookedDate.day == now.day && bookedDate.month == now.month && bookedDate.year == now.year;
    } catch (e) { return false; }
  }

  bool _shouldShowDriver(Booking booking, String status) {
    if (booking.bookingType == 'scheduled') return status == 'in_progress';
    return status == 'accepted' || status == 'in_progress';
  }

  Future<void> _startPassengerLocationTracking() async {
    if (_userId == null) return;
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
        setState(() { _passengerLat = position.latitude; _passengerLng = position.longitude; });
        await FirebaseService.updatePassengerLocation(passengerId: _userId!, latitude: position.latitude, longitude: position.longitude);
        _updateMapMarkers();
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15));
      }
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((Position pos) async {
        if (!mounted) return;
        setState(() { _passengerLat = pos.latitude; _passengerLng = pos.longitude; });
        await FirebaseService.updatePassengerLocation(passengerId: _userId!, latitude: pos.latitude, longitude: pos.longitude);
        _updateMapMarkers();
        if (_driverLat != null && _driverLng != null) {
          _drawRoute(LatLng(_driverLat!, _driverLng!), LatLng(pos.latitude, pos.longitude));
        }
      });
    } catch (e) { debugPrint('Location error: $e'); }
  }

  void _startDriverTracking(int driverFirebaseId) {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = FirebaseDatabase.instance.ref('drivers/$driverFirebaseId').onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data == null) return;
      final driverData = Map<String, dynamic>.from(data as Map);
      final lat = double.tryParse(driverData['latitude']?.toString() ?? '');
      final lng = double.tryParse(driverData['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        setState(() { _driverLat = lat; _driverLng = lng; });
        _updateMapMarkers();
        if (_passengerLat != null && _passengerLng != null) {
          _drawRoute(LatLng(lat, lng), LatLng(_passengerLat!, _passengerLng!));
        }
      }
    });
  }

  void _stopDriverTracking() {
    _driverLocationSubscription?.cancel();
    setState(() { _activeBooking = null; _driverLat = null; _driverLng = null; _polylines.clear(); });
    _updateMapMarkers();
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
          polylineId: const PolylineId('route'), points: polylinePoints, color: Colors.yellow[800]!, width: 5);
      });
    } catch (e) { debugPrint('Route error: $e'); }
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

  void _updateMapMarkers() {
    if (!mounted) return;
    final markers = <MarkerId, Marker>{};
    if (_passengerLat != null && _passengerLng != null) {
      markers[const MarkerId('passenger')] = Marker(
        markerId: const MarkerId('passenger'), position: LatLng(_passengerLat!, _passengerLng!),
        infoWindow: const InfoWindow(title: 'My Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
    }
    if (_driverLat != null && _driverLng != null) {
      markers[const MarkerId('driver')] = Marker(
        markerId: const MarkerId('driver'), position: LatLng(_driverLat!, _driverLng!),
        infoWindow: const InfoWindow(title: 'Your Driver'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
    }
    setState(() { _mapMarkers.clear(); _mapMarkers.addAll(markers); });
  }

  void _listenToBookingStatuses() {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    for (final booking in bookingProvider.bookings) { _subscribeToBooking(booking); }
    for (final booking in bookingProvider.bookings) {
      final status = booking.status;
      if (_shouldShowDriver(booking, status) && _isToday(booking.createdAt)) {
        setState(() => _activeBooking = booking);
        if (booking.driverFirebaseId != null) _startDriverTracking(booking.driverFirebaseId!);
        break;
      }
    }
  }

  void _subscribeToBooking(Booking booking) {
    if (!_isToday(booking.createdAt) &&
        (booking.status == 'completed' || booking.status == 'cancelled')) return;
    _bookingSubscriptions[booking.id]?.cancel();
    _bookingSubscriptions[booking.id] =
        FirebaseService.getBookingStatusStream(booking.id).listen((DatabaseEvent event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data != null) {
        final bookingData = Map<String, dynamic>.from(data as Map);
        final newStatus = bookingData['status'] ?? '';
        if (newStatus.isNotEmpty && _firebaseStatuses[booking.id] != newStatus) {
          final isFirstLoad = _firebaseStatuses[booking.id] == null;
          setState(() => _firebaseStatuses[booking.id] = newStatus);

          if (!isFirstLoad) _showStatusChangeNotification(newStatus, booking.bookingType == 'scheduled');

          if (_shouldShowDriver(booking, newStatus) && booking.driverFirebaseId != null && _isToday(booking.createdAt)) {
            setState(() => _activeBooking = booking);
            _startDriverTracking(booking.driverFirebaseId!);
          }

          if (newStatus == 'completed' || newStatus == 'cancelled') {
            _stopDriverTracking();
            Provider.of<BookingProvider>(context, listen: false).getPassengerBookings();

            // ✅ Show rating dialog for completed NOW bookings
            if (newStatus == 'completed' &&
                !isFirstLoad &&
                booking.bookingType == 'now' &&
                _isToday(booking.createdAt) &&
                !_ratingShownForBookings.contains(booking.id)) {
              _ratingShownForBookings.add(booking.id);
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) _showRatingDialog(booking);
              });
            }

            // ✅ Show cancellation feedback dialog for CANCELLED SCHEDULED bookings
            if (newStatus == 'cancelled' &&
                !isFirstLoad &&
                booking.bookingType == 'scheduled' &&
                !_scheduledCancelDialogShown.contains(booking.id)) {
              _scheduledCancelDialogShown.add(booking.id);
              Future.delayed(const Duration(milliseconds: 800), () async {
                if (!mounted) return;
                // Fetch cancellation reason from API
                String? reason;
                try {
                  final response = await _apiService.get('/bookings/${booking.id}');
                  reason = response['booking']?['cancellation_reason']?.toString();
                } catch (_) {}
                if (mounted) _showScheduledCancellationDialog(booking, reason);
              });
            }
          }

          if (booking.bookingType == 'scheduled' && newStatus == 'accepted') {
            _stopDriverTracking();
          }
        }
      }
    });
  }

  // ✅ New dialog: shows cancellation reason + star rating for scheduled bookings
  Future<void> _showScheduledCancellationDialog(Booking booking, String? reason) async {
    int selectedRating = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // ❌ Icon
              Stack(alignment: Alignment.center, children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle)),
                Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle)),
                Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle),
                    child: const Icon(Icons.cancel_rounded, color: Colors.white, size: 24)),
              ]),

              const SizedBox(height: 16),
              const Text('Ride Cancelled', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 6),
              Text('Your scheduled ride was cancelled by the driver.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),

              // ✅ Cancellation reason box
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.info_outline_rounded, color: Colors.red[400], size: 14),
                      const SizedBox(width: 6),
                      Text('Reason for cancellation', style: TextStyle(fontSize: 11, color: Colors.red[400], fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Text(reason, style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],

              // ✅ Star rating section
              const SizedBox(height: 20),
              Text('Rate the driver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text('How was your experience before cancellation?',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        selectedRating >= starIndex ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: selectedRating >= starIndex ? Colors.yellow[800] : Colors.grey[300],
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                selectedRating == 0 ? 'Tap a star to rate (optional)'
                    : selectedRating == 1 ? 'Poor'
                    : selectedRating == 2 ? 'Fair'
                    : selectedRating == 3 ? 'Good'
                    : selectedRating == 4 ? 'Very Good'
                    : 'Excellent!',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: selectedRating == 0 ? Colors.grey[400] : Colors.yellow[800],
                ),
              ),

              const SizedBox(height: 20),
              Row(children: [
                // Skip button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('Skip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                // Submit button (only active if star selected)
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedRating == 0 ? null : () async {
                      Navigator.of(ctx).pop();
                      try {
                        await _apiService.rateDriver(bookingId: booking.id, rating: selectedRating);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Thank you for your feedback!'), backgroundColor: Colors.yellow[800]),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Could not submit rating.'), backgroundColor: Colors.grey[800]),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedRating == 0 ? Colors.grey[300] : Colors.yellow[800],
                      foregroundColor: selectedRating == 0 ? Colors.grey[500] : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showRatingDialog(Booking booking) async {
    int selectedRating = 0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(alignment: Alignment.center, children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle)),
                Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle)),
                Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 24)),
              ]),
              const SizedBox(height: 16),
              const Text('Rate Your Driver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 6),
              Text('How was your ride experience?', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        selectedRating >= starIndex ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: selectedRating >= starIndex ? Colors.yellow[800] : Colors.grey[300],
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRating == 0 ? 'Tap a star to rate'
                    : selectedRating == 1 ? 'Poor' : selectedRating == 2 ? 'Fair'
                    : selectedRating == 3 ? 'Good' : selectedRating == 4 ? 'Very Good' : 'Excellent!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: selectedRating == 0 ? Colors.grey[400] : Colors.yellow[800]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController, maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Leave a comment (optional)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true, fillColor: Colors.grey[50], contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: Colors.black54),
                  child: const Text('Skip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: selectedRating == 0 ? null : () async {
                    Navigator.of(ctx).pop();
                    try {
                      await _apiService.rateDriver(bookingId: booking.id, rating: selectedRating,
                          comment: commentController.text.trim().isEmpty ? null : commentController.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Thank you for your rating!'), backgroundColor: Colors.yellow[800]),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Could not submit rating. Try again later.'), backgroundColor: Colors.grey[800]),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: selectedRating == 0 ? Colors.grey[300] : Colors.yellow[800],
                      foregroundColor: selectedRating == 0 ? Colors.grey[500] : Colors.white,
                      elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Submit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  String _getStatus(Booking booking) {
    if (_isToday(booking.createdAt)) return _firebaseStatuses[booking.id] ?? booking.status;
    return booking.status;
  }

  void _showStatusChangeNotification(String status, bool isScheduled) {
    if (!mounted) return;
    String message = '';
    Color color = Colors.yellow[800]!;
    switch (status) {
      case 'accepted': message = 'Driver accepted your booking!'; color = const Color(0xFF2E7D32); break;
      case 'in_progress': message = 'Your ride has started!'; color = const Color(0xFF6A1B9A); break;
      case 'completed': message = 'Ride completed! Please rate your driver.'; color = const Color(0xFF2E7D32); break;
      case 'cancelled':
        message = isScheduled ? 'Your scheduled ride was cancelled by the driver.' : 'Booking was cancelled.';
        color = Colors.grey[800]!;
        break;
    }
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':     return const Color(0xFFE65100);
      case 'accepted':    return const Color(0xFF1565C0);
      case 'in_progress': return const Color(0xFF6A1B9A);
      case 'completed':   return const Color(0xFF2E7D32);
      case 'cancelled':   return const Color(0xFFB71C1C);
      default:            return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':     return Icons.hourglass_empty_rounded;
      case 'accepted':    return Icons.check_circle_rounded;
      case 'in_progress': return Icons.directions_car_rounded;
      case 'completed':   return Icons.done_all_rounded;
      case 'cancelled':   return Icons.cancel_rounded;
      default:            return Icons.info_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':     return 'Pending';
      case 'accepted':    return 'Accepted';
      case 'in_progress': return 'On the Way';
      case 'completed':   return 'Completed';
      case 'cancelled':   return 'Cancelled';
      default:            return status;
    }
  }

  Future<void> _deleteBooking(BuildContext context, int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context, barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 28)),
            const SizedBox(height: 16),
            const Text('Remove Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Remove this booking from your list?\nThis cannot be undone.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: Colors.black54),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                      elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Remove', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      try {
        await bookingProvider.deleteBooking(bookingId);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Booking removed'), backgroundColor: Colors.grey[800]));
      } catch (e) {
        if (context.mounted) await _showErrorDialog('Remove Failed', 'Could not remove this booking.\nPlease try again.');
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context, barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle)),
              Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle),
                  child: const Icon(Icons.cancel_rounded, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 20),
            const Text('Cancel Booking?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Are you sure you want to\ncancel this booking?', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), foregroundColor: Colors.black54),
                  child: const Text('No', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                      elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Yes, Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.cancelBooking(bookingId);
      if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Booking cancelled'), backgroundColor: Colors.grey[800]));
    }
  }

  Future<void> _cancelScheduledBookingWithReason(BuildContext context, int bookingId) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context, barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle)),
              Container(width: 62, height: 62, decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle)),
              Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle),
                  child: const Icon(Icons.cancel_rounded, color: Colors.white, size: 22)),
            ])),
            const SizedBox(height: 16),
            const Center(child: Text('Cancel Scheduled Ride?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87))),
            const SizedBox(height: 6),
            Center(child: Text('Please provide a reason for cancellation.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController, maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Change of plans, emergency, etc.',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true, fillColor: Colors.grey[50], contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(null),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), foregroundColor: Colors.black54),
                  child: const Text('Back', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
                    return;
                  }
                  Navigator.of(ctx).pop(reason);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Confirm Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
    if (result != null && context.mounted) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      // ✅ Find the booking before cancelling
      final cancelledBooking = bookingProvider.bookings.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => bookingProvider.bookings.first,
      );

      // ✅ Check if scheduled time has already passed (driver didn't show up)
      bool isDriverNoShow = false;
      try {
        final dateStr = cancelledBooking.scheduledDate ?? '';
        final timeStr = cancelledBooking.scheduledTime ?? '';
        if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final scheduledDateTime = DateTime.parse(dateStr).copyWith(hour: hour, minute: minute);
          isDriverNoShow = DateTime.now().isAfter(scheduledDateTime);
        }
      } catch (_) {}

      final success = await bookingProvider.cancelBooking(bookingId, reason: result);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Scheduled booking cancelled'), backgroundColor: Colors.grey[800]));

        // ✅ Show rating only if driver didn't show up (time has passed)
        if (isDriverNoShow) {
          await bookingProvider.getPassengerBookings();
          final updatedBooking = bookingProvider.bookings.firstWhere(
            (b) => b.id == bookingId,
            orElse: () => cancelledBooking,
          );
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _showScheduledCancellationDialog(updatedBooking, result);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final currentBookings = bookingProvider.bookings.where((b) => b.bookingType == 'now').toList();
    final scheduledBookings = bookingProvider.bookings.where((b) => b.bookingType == 'scheduled').toList();
    final hasActiveRide = _activeBooking != null;

    final activeCount = currentBookings.where((b) =>
        _getStatus(b) == 'pending' || _getStatus(b) == 'accepted' || _getStatus(b) == 'in_progress').length;
    final scheduledPendingCount = scheduledBookings.where((b) => _getStatus(b) == 'pending').length;

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
                    opacity: animation, child: const PassengerHomeScreen()),
                transitionDuration: const Duration(milliseconds: 300),
              ),
              (route) => false,
            );
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/taxi_logo.png', width: 36, height: 36, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('Easy Ride', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: 0.3)),
          ]),
        ),
        actions: [
          Row(children: [
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text('Live', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.yellow[800], indicatorWeight: 3,
              labelColor: Colors.yellow[800], unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.directions_car_rounded, size: 16), const SizedBox(width: 6), const Text('Current'),
                  if (activeCount > 0) ...[const SizedBox(width: 6), Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(10)),
                    child: Text('$activeCount', style: const TextStyle(color: Colors.white, fontSize: 10)))],
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_today_rounded, size: 16), const SizedBox(width: 6), const Text('Scheduled'),
                  if (scheduledPendingCount > 0) ...[const SizedBox(width: 6), Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.yellow[800], borderRadius: BorderRadius.circular(10)),
                    child: Text('$scheduledPendingCount', style: const TextStyle(color: Colors.white, fontSize: 10)))],
                ])),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex, onTap: _onNavTap,
          type: BottomNavigationBarType.fixed, backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800], unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.local_taxi_outlined), activeIcon: Icon(Icons.local_taxi_rounded), label: 'Book Ride'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      body: bookingProvider.isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
          : Column(children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                child: SizedBox(height: 190,
                  child: _passengerLat != null
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(target: LatLng(_passengerLat!, _passengerLng!), zoom: 15),
                          onMapCreated: (c) => _mapController = c, mapType: MapType.hybrid,
                          markers: Set<Marker>.of(_mapMarkers.values), polylines: Set<Polyline>.of(_polylines.values),
                          myLocationEnabled: true, myLocationButtonEnabled: false,
                          zoomControlsEnabled: false, mapToolbarEnabled: false,
                          zoomGesturesEnabled: true, scrollGesturesEnabled: true, rotateGesturesEnabled: true, tiltGesturesEnabled: true)
                      : Container(color: Colors.grey.shade200,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)),
                            const SizedBox(height: 10),
                            Text('Getting your location...', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ])),
                ),
              ),
              Container(
                color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                  const SizedBox(width: 5), Text('You', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (hasActiveRide) ...[
                    const SizedBox(width: 14),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                    const SizedBox(width: 5), Text('Driver', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 14),
                    Container(width: 18, height: 3, color: Colors.yellow[800]),
                    const SizedBox(width: 5), Text('Route', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ]),
              ),
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(context, currentBookings, 'now'),
                  _buildBookingList(context, scheduledBookings, 'scheduled'),
                ],
              )),
            ]),
    );
  }

  Widget _buildBookingList(BuildContext context, List<Booking> bookings, String type) {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    if (bookings.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(type == 'now' ? Icons.directions_car_rounded : Icons.calendar_today_rounded, size: 38, color: Colors.grey[300])),
        const SizedBox(height: 16),
        Text(type == 'now' ? 'No current rides' : 'No scheduled rides',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
        const SizedBox(height: 6),
        Text(type == 'now' ? 'Book a ride to get started!' : 'Schedule a future ride!',
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]));
    }
    return RefreshIndicator(
      color: Colors.yellow[800],
      onRefresh: () => bookingProvider.getPassengerBookings().then((_) => _listenToBookingStatuses()),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingCard(context, bookings[index]),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final status       = _getStatus(booking);
    final statusColor  = _getStatusColor(status);
    final statusLabel  = _getStatusLabel(status);
    final isCancelled  = status == 'cancelled';
    final isPending    = status == 'pending';
    final isAccepted   = status == 'accepted';
    final isInProgress = status == 'in_progress';
    final isCompleted  = status == 'completed';
    final isScheduled  = booking.bookingType == 'scheduled';
    final isRated      = booking.rating != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_getStatusIcon(status), size: 14, color: statusColor), const SizedBox(width: 5),
                Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
            Text('#${booking.id}', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
          ]),

          const SizedBox(height: 14),

          if (isScheduled && booking.scheduledDate != null && booking.scheduledTime != null) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFF5E35B1), size: 16), const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Scheduled for', style: TextStyle(color: Color(0xFF5E35B1), fontSize: 11)),
                  Text('${_formatScheduledDate(booking.scheduledDate!)}  •  ${_formatScheduledTime(booking.scheduledTime!)}',
                      style: const TextStyle(color: Color(0xFF4527A0), fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ]),
            ),
          ],

          if (isCancelled) _buildInfoBanner(color: const Color(0xFFB71C1C), icon: Icons.info_outline_rounded, message: 'This booking was cancelled.'),
          if (isAccepted && !isScheduled) _buildInfoBanner(color: const Color(0xFF1565C0), icon: Icons.check_circle_rounded, message: 'Driver accepted! They are on their way.'),
          if (isAccepted && isScheduled) _buildInfoBanner(color: const Color(0xFF1565C0), icon: Icons.check_circle_rounded, message: 'Driver accepted! They will arrive at the scheduled time.'),
          if (isInProgress) _buildInfoBanner(color: const Color(0xFF6A1B9A), icon: Icons.directions_car_rounded, message: 'Your ride has started! Driver is on the map.'),
          if (isCompleted) _buildInfoBanner(color: const Color(0xFF2E7D32), icon: Icons.done_all_rounded, message: 'Ride completed! Thank you.'),

          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(booking.pickupLocation, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
          ]),
          Padding(padding: const EdgeInsets.only(left: 3.5), child: Container(width: 1, height: 10, color: Colors.grey[300])),
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.yellow[800], shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(booking.dropoffLocation, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
          ]),

          const SizedBox(height: 14),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.directions_car_outlined, size: 14, color: Colors.grey[600]), const SizedBox(width: 5),
                Text(booking.vehicleType, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
              ]),
            ),
            Text('Nu. ${booking.finalPrice ?? booking.estimatedPrice}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.yellow[800])),
          ]),

          const SizedBox(height: 8),
          Text('Booked: ${_formatDate(booking.createdAt)}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),

          if (isPending && !isScheduled) ...[
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _cancelBooking(context, booking.id),
                icon: const Icon(Icons.cancel_outlined, size: 16), label: const Text('Cancel Booking'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red[400], side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],

          if (isScheduled && (isPending || isAccepted)) ...[
            // ✅ Driver contact card
            if (booking.driverPhone != null && booking.driverPhone!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(children: [
                  Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle),
                      child: Icon(Icons.drive_eta_rounded, color: Colors.yellow[800], size: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Your Driver', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(booking.driverPhone!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ])),
                  // ✅ Call button
                  GestureDetector(
                    onTap: () => _callDriver(booking.driverPhone!),
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.call_rounded, color: Color(0xFF2E7D32), size: 18)),
                  ),
                  const SizedBox(width: 8),
                  // ✅ WhatsApp button
                  GestureDetector(
                    onTap: () => _whatsappDriver(booking.driverPhone!),
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _cancelScheduledBookingWithReason(context, booking.id),
                icon: const Icon(Icons.cancel_outlined, size: 16), label: const Text('Cancel Scheduled Ride'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red[400], side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],

          if (isCancelled) ...[
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _onNavTap(1), icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Book Another Ride'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _deleteBooking(context, booking.id),
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey[500]),
                label: Text('Remove from list', style: TextStyle(color: Colors.grey[600])),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],

          if (isCompleted) ...[
            const SizedBox(height: 14),
            if (isRated) ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(color: Colors.yellow[50], borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.yellow[200]!)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ...List.generate(5, (i) => Icon(
                    i < (booking.rating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.yellow[800], size: 20)),
                  const SizedBox(width: 8),
                  Text('You rated ${booking.rating}/5',
                      style: TextStyle(fontSize: 12, color: Colors.yellow[800], fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 8),
            ] else ...[
              SizedBox(width: double.infinity, height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(booking),
                  icon: const Icon(Icons.star_rounded, size: 16), label: const Text('Rate Your Driver'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[800], foregroundColor: Colors.white,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(width: double.infinity, height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _deleteBooking(context, booking.id),
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey[500]),
                label: Text('Remove from list', style: TextStyle(color: Colors.grey[600])),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildInfoBanner({required Color color, required IconData icon, required String message}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 8),
        Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) { return dateStr; }
  }

  String _formatScheduledDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) { return dateStr; }
  }

  String _formatScheduledTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
      return '$displayHour:$minute $period';
    } catch (e) { return timeStr; }
  }
}