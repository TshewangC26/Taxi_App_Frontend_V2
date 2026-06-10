import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as location_pkg;
import '../services/api_service.dart';
import '../services/firebase_services.dart';

class DriverProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _clean(dynamic e) {
    final msg = e.toString();
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }

  bool _isAvailable = false;
  String _driverStatus = 'offline';
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _driverProfile;
  List<dynamic> _availableBookings = [];
  List<dynamic> _nowBookings = [];
  List<dynamic> _scheduledBookings = [];
  List<dynamic> _myActiveBookings = [];
  List<dynamic> _myRides = [];
  Map<String, dynamic>? _earnings;

  // GPS
  Timer? _locationTimer;
  double? _currentLat;
  double? _currentLng;

  // Getters
  bool get isAvailable => _isAvailable;
  String get driverStatus => _driverStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get driverProfile => _driverProfile;
  List<dynamic> get availableBookings => _availableBookings;
  List<dynamic> get nowBookings => _nowBookings;
  List<dynamic> get scheduledBookings => _scheduledBookings;
  List<dynamic> get myActiveBookings => _myActiveBookings;
  List<dynamic> get myRides => _myRides;
  Map<String, dynamic>? get earnings => _earnings;
  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;

  // ── Get driver profile ────────────────────────────────────────
  Future<void> getProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/driver/profile');
      _driverProfile = response['driver'];
      _isAvailable   = response['driver']['is_available'] ?? false;
      _driverStatus  = response['driver']['status'] ?? 'offline';
      _isLoading     = false;

      if (_driverStatus == 'available' || _driverStatus == 'booked') {
        startLocationTracking();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _clean(e);
      _isLoading    = false;
      notifyListeners();
    }
  }

  // ── Update driver profile (vehicle info + payment + QR) ───────
  Future<bool> updateDriverProfile({
    required String vehicleNumber,
    required String licenseNumber,
    required String vehicleType,
    String? accountNumber,
    String? mobilePaymentNumber,
    String? qrImagePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fields = <String, String>{
        'vehicle_number':        vehicleNumber,
        'license_number':        licenseNumber,
        'vehicle_type':          vehicleType,
        'account_number':        accountNumber ?? '',
        'mobile_payment_number': mobilePaymentNumber ?? '',
      };

      dynamic response;

      if (qrImagePath != null) {
        final shouldUpload = kIsWeb || await File(qrImagePath).exists();

        if (shouldUpload) {
          response = await _apiService.postMultipart(
            '/driver/profile/update',
            fields:    fields,
            fileField: 'qr_code_image',
            filePath:  qrImagePath,
          );
        } else {
          response = await _apiService.postMultipart(
            '/driver/profile/update',
            fields: fields,
          );
        }
      } else {
        response = await _apiService.postMultipart(
          '/driver/profile/update',
          fields: fields,
        );
      }

      if (response['success'] == true ||
          (response['message']?.toString().toLowerCase().contains('updated') ?? false)) {
        await getProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ??
            'Failed to update driver profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ── Toggle availability ───────────────────────────────────────
  Future<bool> toggleAvailability() async {
    try {
      final response =
          await _apiService.post('/driver/toggle-availability', {});
      _isAvailable  = response['is_available'] ?? false;
      _driverStatus = response['status'] ?? 'offline';
      notifyListeners();

      if (_driverStatus == 'available') {
        startLocationTracking();
      } else {
        stopLocationTracking();
        final driverId = _driverProfile?['id'];
        if (driverId != null) {
          await FirebaseService.removeDriverLocation(driverId);
        }
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── GPS location tracking ─────────────────────────────────────
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  void startLocationTracking() async {
    if (_locationTimer != null && _locationTimer!.isActive) return;

    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return;

    await _sendLocationToFirebase();

    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _sendLocationToFirebase();
    });
  }

  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _sendLocationToFirebase() async {
    if (_driverProfile == null) return;

    try {
      final loc = location_pkg.Location();
      await loc.changeSettings(
        accuracy: location_pkg.LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 0,
      );

      final locationData = await loc.getLocation();

      _currentLat = locationData.latitude;
      _currentLng = locationData.longitude;

      final driverId    = _driverProfile?['id'];
      final driverName  = _driverProfile?['name'] ?? 'Unknown';
      final vehicleType = _driverProfile?['vehicle_type'] ?? '';

      if (driverId != null && _currentLat != null && _currentLng != null) {
        await FirebaseService.updateDriverLocation(
          driverId:    driverId,
          latitude:    _currentLat!,
          longitude:   _currentLng!,
          status:      _driverStatus,
          vehicleType: vehicleType,
          driverName:  driverName,
        );

        try {
          await _apiService.post('/driver/update-location', {
            'latitude':  _currentLat,
            'longitude': _currentLng,
          });
        } catch (_) {}
      }

      notifyListeners();
    } catch (e) {
      // Silent
    }
  }

  // ── Get available bookings ────────────────────────────────────
  Future<void> getAvailableBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/bookings/available');

      _nowBookings       = response['now_bookings'] ?? [];
      _scheduledBookings = response['scheduled_bookings'] ?? [];
      _myActiveBookings  = response['my_active_bookings'] ?? [];
      _availableBookings = [
        ..._nowBookings,
        ..._scheduledBookings,
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
    }
  }

  // ── Accept NOW booking ────────────────────────────────────────
  Future<bool> acceptBooking(int bookingId) async {
    try {
      await _apiService.post('/bookings/$bookingId/accept', {});
      _driverStatus = 'booked';
      _isAvailable  = false;

      final driverId = _driverProfile?['id'];
      if (driverId != null && _currentLat != null && _currentLng != null) {
        await FirebaseService.updateDriverLocation(
          driverId:    driverId,
          latitude:    _currentLat!,
          longitude:   _currentLng!,
          status:      'booked',
          vehicleType: _driverProfile?['vehicle_type'] ?? '',
          driverName:  _driverProfile?['name'] ?? '',
        );
      }

      await FirebaseService.updateBookingStatus(
        bookingId:   bookingId,
        status:      'accepted',
        passengerId: 0,
      );

      await getAvailableBookings();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Accept SCHEDULED booking ──────────────────────────────────
  Future<bool> acceptScheduledBooking(int bookingId) async {
    try {
      await _apiService.post('/bookings/$bookingId/accept', {});

      await FirebaseService.updateBookingStatus(
        bookingId:   bookingId,
        status:      'accepted',
        passengerId: 0,
      );

      await getAvailableBookings();
      await getMyRides();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Cancel booking ────────────────────────────────────────────
  Future<bool> cancelBooking(int bookingId) async {
    try {
      await _apiService.post('/bookings/$bookingId/cancel', {});
      _driverStatus = 'available';
      _isAvailable  = true;

      final driverId = _driverProfile?['id'];
      if (driverId != null && _currentLat != null && _currentLng != null) {
        await FirebaseService.updateDriverLocation(
          driverId:    driverId,
          latitude:    _currentLat!,
          longitude:   _currentLng!,
          status:      'available',
          vehicleType: _driverProfile?['vehicle_type'] ?? '',
          driverName:  _driverProfile?['name'] ?? '',
        );
      }

      await getAvailableBookings();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Start ride ────────────────────────────────────────────────
  Future<bool> startRide(int bookingId) async {
    try {
      await _apiService.post('/bookings/$bookingId/start', {});
      _driverStatus = 'booked';
      _isAvailable  = false;

      final driverId = _driverProfile?['id'];
      if (driverId != null && _currentLat != null && _currentLng != null) {
        await FirebaseService.updateDriverLocation(
          driverId:    driverId,
          latitude:    _currentLat!,
          longitude:   _currentLng!,
          status:      'booked',
          vehicleType: _driverProfile?['vehicle_type'] ?? '',
          driverName:  _driverProfile?['name'] ?? '',
        );
      }

      await FirebaseService.updateBookingStatus(
        bookingId:   bookingId,
        status:      'in_progress',
        passengerId: 0,
      );

      await getAvailableBookings();
      await getMyRides();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Complete ride ─────────────────────────────────────────────
  Future<bool> completeRide(int bookingId) async {
    try {
      await _apiService.post('/bookings/$bookingId/complete', {});
      _driverStatus = 'available';
      _isAvailable  = true;

      final driverId = _driverProfile?['id'];
      if (driverId != null && _currentLat != null && _currentLng != null) {
        await FirebaseService.updateDriverLocation(
          driverId:    driverId,
          latitude:    _currentLat!,
          longitude:   _currentLng!,
          status:      'available',
          vehicleType: _driverProfile?['vehicle_type'] ?? '',
          driverName:  _driverProfile?['name'] ?? '',
        );
      }

      await FirebaseService.updateBookingStatus(
        bookingId:   bookingId,
        status:      'completed',
        passengerId: 0,
      );

      startLocationTracking();
      await getMyRides();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Delete completed ride from list ───────────────────────────
  Future<void> deleteRide(int bookingId) async {
    try {
      await _apiService.delete('/driver/my-rides/$bookingId');
      _myRides.removeWhere((r) => r['id'] == bookingId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Get my rides ──────────────────────────────────────────────
  Future<void> getMyRides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/driver/my-rides');
      _myRides   = response['bookings'] ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
    }
  }

  // ── Get earnings ──────────────────────────────────────────────
  Future<void> getEarnings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/driver/earnings');
      _earnings  = response['earnings'];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
    }
  }

  // ── Update bank details ───────────────────────────────────────
  Future<bool> updateBankDetails({
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? mobilePaymentNumber,
  }) async {
    try {
      await _apiService.put('/driver/bank-details', {
        if (bankName != null) 'bank_name': bankName,
        if (accountHolderName != null)
          'account_holder_name': accountHolderName,
        if (accountNumber != null) 'account_number': accountNumber,
        if (mobilePaymentNumber != null)
          'mobile_payment_number': mobilePaymentNumber,
      });
      await getProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}