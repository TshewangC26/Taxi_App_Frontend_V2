import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_services.dart';
import 'passenger_home_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'login_screens.dart';

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
  String? _estimatedPrice;
  bool _priceCalculated = false;

  // Driver selection
  List<dynamic> _availableDrivers = [];
  bool _loadingDrivers = false;
  Map<String, dynamic>? _selectedDriver;

  // GPS
  double? _passengerLat;
  double? _passengerLng;
  bool _locationLoading = false;
  String? _locationError;

  // Firebase stream
  StreamSubscription? _driversSubscription;

  // Scheduled
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  // Google Map
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _mapMarkers = {};

  // Bottom nav — index 1 = Book Ride (current)
  final int _currentIndex = 1;

  // Entrance animation
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RouteProvider>(context, listen: false).getRoutes();
      Provider.of<RouteProvider>(context, listen: false).getLocations();
      _getPassengerLocation();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _driversSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Bottom nav handler ────────────────────────────────────────
  void _onNavTap(int index) {
    if (index == _currentIndex) return; // already here
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const PassengerHomeScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
      return;
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const MyBookingsScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const ProfileScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
  }

  // ── Logout confirmation dialog ────────────────────────────────
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Logging Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Would you like to logout from\nEasy Ride?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: Colors.black54,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[800],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Yes, Logout',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const LoginScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    }
  }

  Future<void> _getPassengerLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError   = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError   = 'GPS is turned off. Please turn on GPS.';
          _locationLoading = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError   = 'Location permission denied.';
            _locationLoading = false;
          });
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _passengerLat    = position.latitude;
          _passengerLng    = position.longitude;
          _locationLoading = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
        _updateMapMarkers();
      }
      if (_vehicleType != null) {
        _loadNearbyDriversFromFirebase();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError   = 'Could not get location. Please try again.';
          _locationLoading = false;
        });
      }
    }
  }

  void _updateMapMarkers() {
    if (!mounted) return;
    final markers = <MarkerId, Marker>{};
    if (_passengerLat != null && _passengerLng != null) {
      const markerId = MarkerId('passenger');
      markers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(_passengerLat!, _passengerLng!),
        infoWindow: const InfoWindow(title: 'My Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }
    for (final driver in _availableDrivers) {
      final markerId = MarkerId('driver_${driver['id']}');
      markers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(
          driver['latitude'] as double,
          driver['longitude'] as double,
        ),
        infoWindow: InfoWindow(
          title: driver['name'] ?? 'Driver',
          snippet: '${driver['distance_km']?.toStringAsFixed(1)} km away',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () => setState(() => _selectedDriver = driver),
      );
    }
    setState(() {
      _mapMarkers.clear();
      _mapMarkers.addAll(markers);
    });
  }

  void _loadNearbyDriversFromFirebase() {
    if (_vehicleType == null) return;
    if (_passengerLat == null || _passengerLng == null) return;
    setState(() {
      _loadingDrivers = true;
      _selectedDriver = null;
    });
    _driversSubscription?.cancel();
    _driversSubscription =
        FirebaseService.getNearbyDriversStream().listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data == null) {
        setState(() {
          _availableDrivers = [];
          _loadingDrivers   = false;
        });
        _updateMapMarkers();
        return;
      }
      final driversMap = Map<String, dynamic>.from(data as Map);
      final List<dynamic> nearby = [];
      driversMap.forEach((key, value) {
        final driver      = Map<String, dynamic>.from(value as Map);
        final driverLat   = double.tryParse(driver['latitude'].toString()) ?? 0;
        final driverLng   = double.tryParse(driver['longitude'].toString()) ?? 0;
        final status      = driver['status'] ?? 'offline';
        final vehicleType = driver['vehicle_type'] ?? '';
        if (status != 'available') return;
        if (vehicleType != _vehicleType) return;
        final distance = Geolocator.distanceBetween(
                _passengerLat!, _passengerLng!, driverLat, driverLng) /
            1000;
        if (distance > 3) return;
        nearby.add({
          'id':             int.tryParse(key) ?? 0,
          'name':           driver['driver_name'] ?? 'Unknown',
          'vehicle_type':   vehicleType,
          'vehicle_number': driver['vehicle_number'] ?? '',
          'status':         status,
          'latitude':       driverLat,
          'longitude':      driverLng,
          'distance_km':    double.parse(distance.toStringAsFixed(2)),
        });
      });
      nearby.sort((a, b) =>
          (a['distance_km'] as double).compareTo(b['distance_km'] as double));
      setState(() {
        _availableDrivers = nearby;
        _loadingDrivers   = false;
      });
      _updateMapMarkers();
    });
  }

  void _calculatePrice() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      _showSnack('Please select pickup and dropoff locations');
      return;
    }
    if (_vehicleType == null) {
      _showSnack('Please select a vehicle type');
      return;
    }
    if (_pickupLocation == _dropoffLocation) {
      _showSnack('Pickup and dropoff cannot be the same');
      return;
    }
    final routeProvider =
        Provider.of<RouteProvider>(context, listen: false);
    final route = routeProvider.findRoute(_pickupLocation!, _dropoffLocation!);
    if (route != null) {
      setState(() {
        _estimatedPrice  = route.getPriceForVehicle(_vehicleType!);
        _priceCalculated = true;
      });
    } else {
      _showSnack('No route found for selected locations');
    }
  }

  Future<void> _bookRide() async {
    if (!_priceCalculated) {
      _showSnack('Please calculate price first');
      return;
    }
    if (_selectedDriver == null) {
      _showSnack('Please select a driver');
      return;
    }
    if (_bookingType == 'scheduled' &&
        (_scheduledDate == null || _scheduledTime == null)) {
      _showSnack('Please select scheduled date and time');
      return;
    }
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    String? scheduledDateStr;
    String? scheduledTimeStr;
    if (_bookingType == 'scheduled') {
      scheduledDateStr =
          '${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2, '0')}-${_scheduledDate!.day.toString().padLeft(2, '0')}';
      scheduledTimeStr =
          '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}';
    }
    final success = await bookingProvider.createBooking(
      pickupLocation:     _pickupLocation!,
      dropoffLocation:    _dropoffLocation!,
      vehicleType:        _vehicleType!,
      bookingType:        _bookingType,
      driverId:           _selectedDriver!['id'],
      scheduledDate:      scheduledDateStr,
      scheduledTime:      scheduledTimeStr,
      passengerLatitude:  _passengerLat,
      passengerLongitude: _passengerLng,
    );
    if (success && mounted) {
      _driversSubscription?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking created successfully!'),
          backgroundColor: Colors.yellow[800],
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const PassengerHomeScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
    } else if (mounted) {
      _showSnack('Booking failed: ${bookingProvider.errorMessage}',
          isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.grey[800] : Colors.yellow[800],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.yellow[800], size: 20),
      filled: true,
      fillColor: Colors.white,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider   = Provider.of<RouteProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final locations       = routeProvider.getAllLocations();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),

      // ── APP BAR ────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/taxi_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'Easy Ride',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _confirmLogout,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Colors.grey[600], size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BOTTOM NAVIGATION BAR ──────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_taxi_outlined),
              activeIcon: Icon(Icons.local_taxi_rounded),
              label: 'Book Ride',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),

      // ── BODY ───────────────────────────────────────────────
      body: routeProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.yellow[800]!),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ── MAP ───────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            height: 220,
                            child: _passengerLat != null
                                ? GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                          _passengerLat!, _passengerLng!),
                                      zoom: 15,
                                    ),
                                    onMapCreated: (c) => _mapController = c,
                                    mapType: MapType.hybrid,
                                    markers: Set<Marker>.of(
                                        _mapMarkers.values),
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    mapToolbarEnabled: false,
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.yellow[800]!),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Getting your location...',
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),

                        // Location error
                        if (_locationError != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_off,
                                    color: Colors.red[400], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationError!,
                                    style: TextStyle(
                                        color: Colors.red[600],
                                        fontSize: 12),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _getPassengerLocation,
                                  child: Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.yellow[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── TRIP DETAILS ──────────────────────
                        const _SectionLabel(title: 'Trip Details'),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _pickupLocation,
                          decoration: _fieldDecoration(
                              'Pickup Location',
                              Icons.my_location_rounded),
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 14),
                          dropdownColor: Colors.white,
                          items: locations
                              .map((l) => DropdownMenuItem<String>(
                                    value: l.name,
                                    child: Text(l.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _pickupLocation   = v;
                            _priceCalculated  = false;
                            _availableDrivers = [];
                            _selectedDriver   = null;
                          }),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _dropoffLocation,
                          decoration: _fieldDecoration(
                              'Dropoff Location',
                              Icons.location_on_rounded),
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 14),
                          dropdownColor: Colors.white,
                          items: locations
                              .map((l) => DropdownMenuItem<String>(
                                    value: l.name,
                                    child: Text(l.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _dropoffLocation  = v;
                            _priceCalculated  = false;
                            _availableDrivers = [];
                            _selectedDriver   = null;
                          }),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _vehicleType,
                          decoration: _fieldDecoration(
                              'Vehicle Type',
                              Icons.directions_car_rounded),
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 14),
                          dropdownColor: Colors.white,
                          hint: Text('Choose vehicle type',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 14)),
                          items: const [
                            DropdownMenuItem(
                                value: '4-seater',
                                child: Text('4-Seater')),
                            DropdownMenuItem(
                                value: '7-seater',
                                child: Text('7-Seater')),
                            DropdownMenuItem(
                                value: '8-seater',
                                child: Text('8-Seater')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _vehicleType      = v;
                              _selectedDriver   = null;
                              _priceCalculated  = false;
                              _availableDrivers = [];
                            });
                            _loadNearbyDriversFromFirebase();
                          },
                        ),

                        const SizedBox(height: 24),

                        // ── NEARBY DRIVERS ────────────────────
                        if (_vehicleType != null) ...[
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _SectionLabel(
                                  title:
                                      'Nearby Drivers ($_vehicleType)'),
                              Row(children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Live',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _loadingDrivers
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.yellow[800]!),
                                    ),
                                  ),
                                )
                              : _availableDrivers.isEmpty
                                  ? Container(
                                      padding:
                                          const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.grey.shade100),
                                      ),
                                      child: Column(children: [
                                        Icon(
                                            Icons.no_transfer_rounded,
                                            size: 44,
                                            color: Colors.grey[300]),
                                        const SizedBox(height: 10),
                                        Text(
                                          'No drivers available within 3km',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Waiting for nearby drivers...',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[400]),
                                        ),
                                      ]),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          _availableDrivers.length,
                                      itemBuilder: (context, index) {
                                        final driver =
                                            _availableDrivers[index];
                                        final isSelected =
                                            _selectedDriver != null &&
                                                _selectedDriver!['id'] ==
                                                    driver['id'];
                                        final distance =
                                            driver['distance_km'];

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() =>
                                                _selectedDriver = driver);
                                            _mapController
                                                ?.animateCamera(
                                              CameraUpdate.newLatLng(
                                                LatLng(
                                                  driver['latitude']
                                                      as double,
                                                  driver['longitude']
                                                      as double,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets
                                                .only(bottom: 10),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.yellow[50]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.yellow[700]!
                                                    : Colors.grey.shade100,
                                                width:
                                                    isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Row(children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.yellow[100]
                                                      : Colors.grey[100],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  color: isSelected
                                                      ? Colors.yellow[800]
                                                      : Colors.grey[500],
                                                  size: 26,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      driver['name'] ??
                                                          'Unknown',
                                                      style:
                                                          const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14,
                                                        color:
                                                            Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 3),
                                                    Row(children: [
                                                      Icon(
                                                          Icons
                                                              .directions_car_outlined,
                                                          size: 13,
                                                          color: Colors
                                                              .grey[400]),
                                                      const SizedBox(
                                                          width: 4),
                                                      Text(
                                                        driver['vehicle_number'] ??
                                                            '',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[500],
                                                            fontSize: 12),
                                                      ),
                                                    ]),
                                                    if (distance !=
                                                        null) ...[
                                                      const SizedBox(
                                                          height: 2),
                                                      Row(children: [
                                                        Icon(
                                                            Icons
                                                                .location_on_outlined,
                                                            size: 13,
                                                            color: Colors
                                                                .yellow[700]),
                                                        const SizedBox(
                                                            width: 3),
                                                        Text(
                                                          '${distance.toStringAsFixed(1)} km away',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .yellow[800],
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                          ),
                                                        ),
                                                      ]),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: const Color(
                                                          0xFFE8F5E9),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: Color(
                                                                0xFF4CAF50),
                                                            shape: BoxShape
                                                                .circle,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        const Text(
                                                          'Available',
                                                          style: TextStyle(
                                                            color: Color(
                                                                0xFF2E7D32),
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isSelected) ...[
                                                    const SizedBox(
                                                        height: 6),
                                                    Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: Colors
                                                            .yellow[800],
                                                        size: 20),
                                                  ],
                                                ],
                                              ),
                                            ]),
                                          ),
                                        );
                                      },
                                    ),
                          const SizedBox(height: 24),
                        ],

                        // ── BOOKING TYPE ──────────────────────
                        const _SectionLabel(title: 'Booking Type'),
                        const SizedBox(height: 12),

                        Row(children: [
                          Expanded(
                            child: _BookingTypeCard(
                              icon: Icons.flash_on_rounded,
                              label: 'Book Now',
                              selected: _bookingType == 'now',
                              onTap: () =>
                                  setState(() => _bookingType = 'now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BookingTypeCard(
                              icon: Icons.schedule_rounded,
                              label: 'Schedule Later',
                              selected: _bookingType == 'scheduled',
                              onTap: () => setState(
                                  () => _bookingType = 'scheduled'),
                            ),
                          ),
                        ]),

                        if (_bookingType == 'scheduled') ...[
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                              child: _DateTimeButton(
                                icon: Icons.calendar_today_rounded,
                                label: _scheduledDate == null
                                    ? 'Select Date'
                                    : '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 30)),
                                    builder: (ctx, child) => Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                            primary: Colors.yellow[800]!),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (date != null) {
                                    setState(() => _scheduledDate = date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateTimeButton(
                                icon: Icons.access_time_rounded,
                                label: _scheduledTime == null
                                    ? 'Select Time'
                                    : _scheduledTime!.format(context),
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder: (ctx, child) => Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                            primary: Colors.yellow[800]!),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (time != null) {
                                    setState(() => _scheduledTime = time);
                                  }
                                },
                              ),
                            ),
                          ]),
                        ],

                        const SizedBox(height: 24),

                        // ── CALCULATE PRICE ───────────────────
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _calculatePrice,
                            icon: const Icon(Icons.calculate_rounded,
                                size: 20),
                            label: const Text(
                              'Calculate Price',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C1C1E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        // ── PRICE CARD ────────────────────────
                        if (_priceCalculated &&
                            _estimatedPrice != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[50],
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                      Icons.attach_money_rounded,
                                      color: Colors.yellow[800],
                                      size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estimated Price',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12),
                                      ),
                                      Text(
                                        'Nu. $_estimatedPrice',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.yellow[800],
                                        ),
                                      ),
                                      Text(
                                        '$_pickupLocation  →  $_dropoffLocation',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── CONFIRM BUTTON ────────────────────
                        if (_priceCalculated) ...[
                          bookingProvider.isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.yellow[800]!),
                                  ),
                                )
                              : SizedBox(
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: _selectedDriver != null
                                        ? _bookRide
                                        : null,
                                    icon: Icon(
                                      _selectedDriver != null
                                          ? Icons.check_circle_rounded
                                          : Icons.person_search_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      _selectedDriver == null
                                          ? 'Select a Driver First'
                                          : 'Confirm with ${_selectedDriver!['name']}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _selectedDriver != null
                                              ? Colors.yellow[800]
                                              : Colors.grey[300],
                                      foregroundColor:
                                          _selectedDriver != null
                                              ? Colors.white
                                              : Colors.grey[500],
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────
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

// ── Booking type card ───────────────────────────────────────────
class _BookingTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BookingTypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          border: Border.all(
            color: selected ? Colors.yellow[800]! : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24,
                color: selected ? Colors.white : Colors.grey[500]),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date / time button ──────────────────────────────────────────
class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder =
        label == 'Select Date' || label == 'Select Time';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.yellow[800], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isPlaceholder ? Colors.grey[400] : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}