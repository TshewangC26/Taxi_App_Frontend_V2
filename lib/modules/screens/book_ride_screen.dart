import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_services.dart';
import '../services/api_service.dart';
import 'passenger_home_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'login_screens.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  String? _pickupLocation;
  String? _dropoffLocation;
  String? _vehicleType;
  String _bookingType = 'now';

  List<dynamic> _availableDrivers = [];
  bool _loadingDrivers = false;
  Map<String, dynamic>? _selectedDriver;

  double? _passengerLat;
  double? _passengerLng;
  bool _locationLoading = false;
  String? _locationError;

  StreamSubscription? _driversSubscription;

  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _mapMarkers = {};

  final int _currentIndex = 1;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final ApiService _apiService = ApiService();

  // ✅ Dynamic vehicle types
  List<Map<String, String>> _vehicleTypes = [];
  bool _loadingVehicleTypes = false;

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

    // ✅ Load vehicle types from API
    _loadVehicleTypes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RouteProvider>(context, listen: false).getRoutes();
      Provider.of<RouteProvider>(context, listen: false).getLocations();
      _getPassengerLocation();
    });
  }

  // ✅ Fetch vehicle types from API
  Future<void> _loadVehicleTypes() async {
    setState(() => _loadingVehicleTypes = true);
    try {
      final response = await _apiService.get('/vehicle-types');
      final List<dynamic> types = response['vehicle_types'] ?? [];
      setState(() {
        _vehicleTypes = types.map<Map<String, String>>((t) => {
          'name': t['name'].toString(),
          'display_name': t['display_name'].toString(),
        }).toList();
        _loadingVehicleTypes = false;
      });
    } catch (_) {
      // ✅ Fallback to defaults if API fails
      setState(() {
        _vehicleTypes = [
          {'name': '4-seater', 'display_name': '4-Seater'},
          {'name': '7-seater', 'display_name': '7-Seater'},
          {'name': '8-seater', 'display_name': '8-Seater'},
        ];
        _loadingVehicleTypes = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _driversSubscription?.cancel();
    _mapController?.dispose();
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
    if (index == 2) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const MyBookingsScreen()),
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
          _menuItem(
            icon: Icons.headset_mic_rounded, iconColor: Colors.yellow[800]!, iconBg: Colors.yellow[50]!,
            title: 'Contact Us', subtitle: 'Get in touch with our support team',
            onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen())); },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(
            icon: Icons.info_outline_rounded, iconColor: Colors.blue[700]!, iconBg: Colors.blue[50]!,
            title: 'About Us', subtitle: 'Learn more about Easy Ride',
            onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())); },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _menuItem(
            icon: Icons.logout_rounded, iconColor: Colors.red[400]!, iconBg: Colors.red[50]!,
            title: 'Logout', subtitle: 'Sign out of your account',
            onTap: () { Navigator.pop(ctx); _confirmLogout(); },
          ),
        ]),
      ),
    );
  }

  Widget _menuItem({required IconData icon, required Color iconColor, required Color iconBg,
      required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
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
      context: context, barrierDismissible: true, barrierColor: Colors.black.withOpacity(0.5),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), foregroundColor: Colors.black54),
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

  Future<void> _getPassengerLocation() async {
    setState(() { _locationLoading = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationError = 'GPS is turned off. Please turn on GPS.'; _locationLoading = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationError = 'Location permission denied.'; _locationLoading = false; });
          return;
        }
      }
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && mounted) {
        setState(() { _passengerLat = lastPosition.latitude; _passengerLng = lastPosition.longitude; _locationLoading = false; });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lastPosition.latitude, lastPosition.longitude), 15));
        _updateMapMarkers();
        if (_vehicleType != null) _loadDriversBasedOnBookingType();
      }
      final LocationSettings locationSettings = Platform.isAndroid
          ? AndroidSettings(accuracy: LocationAccuracy.best, distanceFilter: 0, forceLocationManager: true)
          : AppleSettings(accuracy: LocationAccuracy.best);
      final position = await Geolocator.getPositionStream(locationSettings: locationSettings).first;
      if (mounted) {
        setState(() { _passengerLat = position.latitude; _passengerLng = position.longitude; _locationLoading = false; });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15));
        _updateMapMarkers();
        if (_vehicleType != null) _loadDriversBasedOnBookingType();
      }
    } catch (e) {
      if (mounted) setState(() { _locationError = 'Could not get location. Please try again.'; _locationLoading = false; });
    }
  }

  void _updateMapMarkers() {
    if (!mounted) return;
    final markers = <MarkerId, Marker>{};
    if (_passengerLat != null && _passengerLng != null) {
      markers[const MarkerId('passenger')] = Marker(
        markerId: const MarkerId('passenger'),
        position: LatLng(_passengerLat!, _passengerLng!),
        infoWindow: const InfoWindow(title: 'My Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }
    for (final driver in _availableDrivers) {
      final lat = driver['latitude'];
      final lng = driver['longitude'];
      if (lat != null && lng != null) {
        final markerId = MarkerId('driver_${driver['id']}');
        markers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(lat as double, lng as double),
          infoWindow: InfoWindow(
            title: driver['name'] ?? 'Driver',
            snippet: driver['distance_km'] != null ? '${driver['distance_km']?.toStringAsFixed(1)} km away' : 'Available',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => setState(() => _selectedDriver = driver),
        );
      }
    }
    setState(() { _mapMarkers.clear(); _mapMarkers.addAll(markers); });
  }

  void _loadDriversBasedOnBookingType() {
    if (_bookingType == 'scheduled') _loadAllAvailableDrivers();
    else _loadNearbyDriversFromFirebase();
  }

  void _loadNearbyDriversFromFirebase() {
    if (_vehicleType == null) return;
    if (_passengerLat == null || _passengerLng == null) return;
    setState(() { _loadingDrivers = true; _selectedDriver = null; });
    _driversSubscription?.cancel();
    _driversSubscription = FirebaseService.getNearbyDriversStream().listen((event) async {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data == null) {
        setState(() { _availableDrivers = []; _loadingDrivers = false; });
        _updateMapMarkers();
        return;
      }
      Map<String, dynamic> driversMap;
      if (data is Map) {
        driversMap = Map<String, dynamic>.from(data);
      } else if (data is List) {
        driversMap = {};
        for (int i = 0; i < (data as List).length; i++) {
          if (data[i] != null) driversMap[i.toString()] = data[i];
        }
      } else {
        driversMap = {};
      }
      Map<int, Map<String, dynamic>> apiRatings = {};
      try {
        final response = await _apiService.get('/drivers/status');
        final List<dynamic> allDrivers = response['drivers'] ?? [];
        for (final d in allDrivers) {
          final id = d['id'] as int?;
          if (id != null) {
            apiRatings[id] = {'average_rating': d['average_rating'] ?? 0, 'total_ratings': d['total_ratings'] ?? 0};
          }
        }
      } catch (_) {}
      final List<dynamic> nearby = [];
      driversMap.forEach((key, value) {
        try {
          final driver = Map<String, dynamic>.from(value as Map);
          final driverLat = double.tryParse(driver['latitude'].toString()) ?? 0;
          final driverLng = double.tryParse(driver['longitude'].toString()) ?? 0;
          final status = driver['status'] ?? 'offline';
          final vehicleType = driver['vehicle_type'] ?? '';
          if (status != 'available') return;
          if (vehicleType != _vehicleType) return;
          final distance = Geolocator.distanceBetween(_passengerLat!, _passengerLng!, driverLat, driverLng) / 1000;
          if (distance > 18) return;
          final driverId = int.tryParse(key) ?? 0;
          final ratingData = apiRatings[driverId] ?? {};
          nearby.add({
            'id': driverId, 'name': driver['driver_name'] ?? 'Unknown',
            'vehicle_type': vehicleType, 'vehicle_number': driver['vehicle_number'] ?? '',
            'status': status, 'latitude': driverLat, 'longitude': driverLng,
            'distance_km': double.parse(distance.toStringAsFixed(2)),
            'average_rating': ratingData['average_rating'] ?? 0, 'total_ratings': ratingData['total_ratings'] ?? 0,
          });
        } catch (_) {}
      });
      nearby.sort((a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));
      setState(() { _availableDrivers = nearby; _loadingDrivers = false; });
      _updateMapMarkers();
    });
  }

  Future<void> _loadAllAvailableDrivers() async {
    if (_vehicleType == null) return;
    _driversSubscription?.cancel();
    setState(() { _loadingDrivers = true; _selectedDriver = null; _availableDrivers = []; });
    try {
      final response = await _apiService.get('/drivers/status');
      final List<dynamic> allDrivers = response['drivers'] ?? [];
      final List<dynamic> filtered = [];
      for (final driver in allDrivers) {
        final status = driver['status']?.toString() ?? '';
        final vehicleType = driver['vehicle_type']?.toString() ?? '';
        if (status != 'available') continue;
        if (vehicleType != _vehicleType) continue;
        filtered.add({
          'id': driver['id'], 'name': driver['name'] ?? driver['driver_name'] ?? 'Unknown',
          'vehicle_type': vehicleType, 'vehicle_number': driver['vehicle_number'] ?? '',
          'status': status,
          'latitude': double.tryParse(driver['latitude']?.toString() ?? ''),
          'longitude': double.tryParse(driver['longitude']?.toString() ?? ''),
          'distance_km': null,
          'average_rating': driver['average_rating'] ?? 0, 'total_ratings': driver['total_ratings'] ?? 0,
        });
      }
      if (mounted) {
        setState(() { _availableDrivers = filtered; _loadingDrivers = false; });
        _updateMapMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _availableDrivers = []; _loadingDrivers = false; });
        _showSnack('Could not load drivers. Please try again.', isError: true);
      }
    }
  }

  Future<void> _bookRide() async {
    if (_pickupLocation == null || _dropoffLocation == null) { _showSnack('Please select pickup and dropoff locations'); return; }
    if (_vehicleType == null) { _showSnack('Please select a vehicle type'); return; }
    if (_selectedDriver == null) { _showSnack('Please select a driver'); return; }
    if (_bookingType == 'scheduled' && (_scheduledDate == null || _scheduledTime == null)) {
      _showSnack('Please select scheduled date and time'); return;
    }
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    String? scheduledDateStr;
    String? scheduledTimeStr;
    if (_bookingType == 'scheduled') {
      scheduledDateStr = '${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2, '0')}-${_scheduledDate!.day.toString().padLeft(2, '0')}';
      scheduledTimeStr = '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}';
    }
    final success = await bookingProvider.createBooking(
      pickupLocation: _pickupLocation!, dropoffLocation: _dropoffLocation!,
      vehicleType: _vehicleType!, bookingType: _bookingType, driverId: _selectedDriver!['id'],
      scheduledDate: scheduledDateStr, scheduledTime: scheduledTimeStr,
      passengerLatitude: _passengerLat, passengerLongitude: _passengerLng,
    );
    if (success && mounted) {
      _driversSubscription?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Booking created successfully!'), backgroundColor: Colors.yellow[800]),
      );
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const PassengerHomeScreen()),
            transitionDuration: const Duration(milliseconds: 400)), (route) => false);
    } else if (mounted) {
      _showSnack('Booking failed: ${bookingProvider.errorMessage}', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.grey[800] : Colors.yellow[800]),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.yellow[800], size: 20),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.yellow[800]!, width: 2)),
    );
  }

  Widget _buildStarRating(double rating, int totalRatings) {
    return Row(children: [
      ...List.generate(5, (i) {
        if (rating >= i + 1) return Icon(Icons.star_rounded, color: Colors.yellow[800], size: 13);
        else if (rating >= i + 0.5) return Icon(Icons.star_half_rounded, color: Colors.yellow[800], size: 13);
        else return Icon(Icons.star_outline_rounded, color: Colors.grey[300], size: 13);
      }),
      const SizedBox(width: 4),
      Text(
        totalRatings > 0 ? '${rating.toStringAsFixed(1)} ($totalRatings)' : 'No ratings yet',
        style: TextStyle(fontSize: 11, color: totalRatings > 0 ? Colors.grey[600] : Colors.grey[400], fontWeight: FontWeight.w500),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider   = Provider.of<RouteProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final locations       = routeProvider.getAllLocations();

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
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
      body: routeProvider.isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ✅ Map outside scroll view
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 200,
                          child: _passengerLat != null
                              ? GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                      target: LatLng(_passengerLat!, _passengerLng!), zoom: 15),
                                  onMapCreated: (c) => _mapController = c,
                                  mapType: MapType.hybrid,
                                  markers: Set<Marker>.of(_mapMarkers.values),
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
                    ),

                    // ✅ Everything else scrolls below the map
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              if (_locationError != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50], borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.location_off, color: Colors.red[400], size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_locationError!, style: TextStyle(color: Colors.red[600], fontSize: 12))),
                                    GestureDetector(
                                      onTap: _getPassengerLocation,
                                      child: Text('Retry', style: TextStyle(color: Colors.yellow[800], fontWeight: FontWeight.w600, fontSize: 12)),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 16),
                              ],

                              const _SectionLabel(title: 'Trip Details'),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                value: _pickupLocation,
                                decoration: _fieldDecoration('Pickup Location', Icons.my_location_rounded),
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                dropdownColor: Colors.white,
                                items: locations.map((l) => DropdownMenuItem<String>(value: l.name, child: Text(l.name))).toList(),
                                onChanged: (v) => setState(() { _pickupLocation = v; _availableDrivers = []; _selectedDriver = null; }),
                              ),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                value: _dropoffLocation,
                                decoration: _fieldDecoration('Dropoff Location', Icons.location_on_rounded),
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                dropdownColor: Colors.white,
                                items: locations.map((l) => DropdownMenuItem<String>(value: l.name, child: Text(l.name))).toList(),
                                onChanged: (v) => setState(() { _dropoffLocation = v; _availableDrivers = []; _selectedDriver = null; }),
                              ),
                              const SizedBox(height: 12),

                              // ✅ Dynamic vehicle type dropdown from API
                              _loadingVehicleTypes
                                  ? Container(
                                      height: 56,
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.grey.shade200)),
                                      child: Center(child: SizedBox(width: 20, height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))),
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: _vehicleType,
                                      decoration: _fieldDecoration('Vehicle Type', Icons.directions_car_rounded),
                                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                                      dropdownColor: Colors.white,
                                      hint: Text('Choose vehicle type', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                                      items: _vehicleTypes.map((t) => DropdownMenuItem<String>(
                                        value: t['name'],
                                        child: Text(t['display_name']!),
                                      )).toList(),
                                      onChanged: (v) {
                                        setState(() { _vehicleType = v; _selectedDriver = null; _availableDrivers = []; });
                                        if (_passengerLat != null && _passengerLng != null) {
                                          _loadDriversBasedOnBookingType();
                                        } else {
                                          Future.delayed(const Duration(seconds: 3), () {
                                            if (mounted) _loadDriversBasedOnBookingType();
                                          });
                                        }
                                      },
                                    ),

                              const SizedBox(height: 24),
                              const _SectionLabel(title: 'Booking Type'),
                              const SizedBox(height: 12),

                              Row(children: [
                                Expanded(child: _BookingTypeCard(
                                  icon: Icons.flash_on_rounded, label: 'Book Now', selected: _bookingType == 'now',
                                  onTap: () {
                                    setState(() { _bookingType = 'now'; _availableDrivers = []; _selectedDriver = null; });
                                    if (_vehicleType != null) _loadDriversBasedOnBookingType();
                                  },
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _BookingTypeCard(
                                  icon: Icons.schedule_rounded, label: 'Schedule Later', selected: _bookingType == 'scheduled',
                                  onTap: () {
                                    setState(() { _bookingType = 'scheduled'; _availableDrivers = []; _selectedDriver = null; });
                                    if (_vehicleType != null) _loadDriversBasedOnBookingType();
                                  },
                                )),
                              ]),

                              if (_bookingType == 'scheduled') ...[
                                const SizedBox(height: 14),
                                Row(children: [
                                  Expanded(child: _DateTimeButton(
                                    icon: Icons.calendar_today_rounded,
                                    label: _scheduledDate == null ? 'Select Date'
                                        : '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().add(const Duration(days: 1)),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 30)),
                                        builder: (ctx, child) => Theme(
                                          data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: Colors.yellow[800]!)),
                                          child: child!,
                                        ),
                                      );
                                      if (date != null) setState(() { _scheduledDate = date; _scheduledTime = null; });
                                    },
                                  )),
                                  const SizedBox(width: 12),
                                  Expanded(child: _DateTimeButton(
                                    icon: Icons.access_time_rounded,
                                    label: _scheduledTime == null ? 'Select Time' : _scheduledTime!.format(context),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context, initialTime: TimeOfDay.now(),
                                        builder: (ctx, child) => Theme(
                                          data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: Colors.yellow[800]!)),
                                          child: child!,
                                        ),
                                      );
                                      if (time != null) {
                                        if (_scheduledDate != null) {
                                          final now = DateTime.now();
                                          final isToday = _scheduledDate!.year == now.year &&
                                              _scheduledDate!.month == now.month && _scheduledDate!.day == now.day;
                                          if (isToday) {
                                            final pickedMinutes = time.hour * 60 + time.minute;
                                            final nowMinutes = now.hour * 60 + now.minute;
                                            if (pickedMinutes <= nowMinutes) {
                                              _showSnack('Please select a future time. Current time is ${TimeOfDay.now().format(context)}.');
                                              return;
                                            }
                                          }
                                        } else {
                                          _showSnack('Please select a date first');
                                          return;
                                        }
                                        setState(() => _scheduledTime = time);
                                      }
                                    },
                                  )),
                                ]),
                              ],

                              const SizedBox(height: 24),

                              if (_vehicleType != null) ...[
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  _SectionLabel(
                                    title: _bookingType == 'scheduled'
                                        ? 'Available Drivers ($_vehicleType)'
                                        : 'Nearby Drivers ($_vehicleType)',
                                  ),
                                  if (_bookingType == 'now')
                                    Row(children: [
                                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                                      const SizedBox(width: 5),
                                      const Text('Live', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                                    ]),
                                ]),
                                const SizedBox(height: 12),

                                _loadingDrivers
                                    ? Center(child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)),
                                      ))
                                    : _availableDrivers.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.all(28),
                                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                                            child: Column(children: [
                                              Icon(Icons.no_transfer_rounded, size: 44, color: Colors.grey[300]),
                                              const SizedBox(height: 10),
                                              Text(
                                                _bookingType == 'scheduled' ? 'No available drivers' : 'No drivers available within 18km',
                                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[500], fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _bookingType == 'scheduled' ? 'No drivers are currently available' : 'Waiting for nearby drivers...',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                              ),
                                            ]),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _availableDrivers.length,
                                            itemBuilder: (context, index) {
                                              final driver = _availableDrivers[index];
                                              final isSelected = _selectedDriver != null && _selectedDriver!['id'] == driver['id'];
                                              final distance = driver['distance_km'];
                                              final avgRating = double.tryParse(driver['average_rating']?.toString() ?? '0') ?? 0.0;
                                              final totalRatings = int.tryParse(driver['total_ratings']?.toString() ?? '0') ?? 0;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() => _selectedDriver = driver);
                                                  final lat = driver['latitude'];
                                                  final lng = driver['longitude'];
                                                  if (lat != null && lng != null) {
                                                    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat as double, lng as double)));
                                                  }
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.only(bottom: 10),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? Colors.yellow[50] : Colors.white,
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: isSelected ? Colors.yellow[700]! : Colors.grey.shade100, width: isSelected ? 2 : 1),
                                                  ),
                                                  child: Row(children: [
                                                    Container(width: 50, height: 50,
                                                        decoration: BoxDecoration(color: isSelected ? Colors.yellow[100] : Colors.grey[100], shape: BoxShape.circle),
                                                        child: Icon(Icons.person_rounded, color: isSelected ? Colors.yellow[800] : Colors.grey[500], size: 26)),
                                                    const SizedBox(width: 12),
                                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                      Text(driver['name'] ?? 'Unknown',
                                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                                                      const SizedBox(height: 3),
                                                      Row(children: [
                                                        Icon(Icons.directions_car_outlined, size: 13, color: Colors.grey[400]),
                                                        const SizedBox(width: 4),
                                                        Text(driver['vehicle_number'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                                      ]),
                                                      const SizedBox(height: 3),
                                                      _buildStarRating(avgRating, totalRatings),
                                                      if (distance != null) ...[
                                                        const SizedBox(height: 3),
                                                        Row(children: [
                                                          Icon(Icons.location_on_outlined, size: 13, color: Colors.yellow[700]),
                                                          const SizedBox(width: 3),
                                                          Text('${distance.toStringAsFixed(1)} km away',
                                                              style: TextStyle(color: Colors.yellow[800], fontSize: 12, fontWeight: FontWeight.w600)),
                                                        ]),
                                                      ],
                                                    ])),
                                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                                                          const SizedBox(width: 5),
                                                          const Text('Available', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 11)),
                                                        ]),
                                                      ),
                                                      if (isSelected) ...[
                                                        const SizedBox(height: 6),
                                                        Icon(Icons.check_circle_rounded, color: Colors.yellow[800], size: 20),
                                                      ],
                                                    ]),
                                                  ]),
                                                ),
                                              );
                                            },
                                          ),
                                const SizedBox(height: 24),
                              ],

                              bookingProvider.isLoading
                                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[800]!)))
                                  : SizedBox(
                                      height: 56,
                                      child: ElevatedButton.icon(
                                        onPressed: _selectedDriver != null ? _bookRide : null,
                                        icon: Icon(_selectedDriver != null ? Icons.check_circle_rounded : Icons.person_search_rounded, size: 20),
                                        label: Text(
                                          _selectedDriver == null ? 'Select a Driver First' : 'Confirm with ${_selectedDriver!['name']}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _selectedDriver != null ? Colors.yellow[800] : Colors.grey[300],
                                          foregroundColor: _selectedDriver != null ? Colors.white : Colors.grey[500],
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
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

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: 0.1));
  }
}

class _BookingTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BookingTypeCard({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.yellow[800] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.yellow[800]! : Colors.grey.shade200, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, size: 24, color: selected ? Colors.white : Colors.grey[500]),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey[600])),
        ]),
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DateTimeButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = label == 'Select Date' || label == 'Select Time';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Icon(icon, color: Colors.yellow[800], size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isPlaceholder ? Colors.grey[400] : Colors.black87),
              overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}