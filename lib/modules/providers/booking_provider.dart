import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Create a new booking
  Future<bool> createBooking({
    required String pickupLocation,
    required String dropoffLocation,
    required String vehicleType,
    required String bookingType,
    int? driverId,
    String? scheduledDate,
    String? scheduledTime,
    double? passengerLatitude,
    double? passengerLongitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'pickup_location':  pickupLocation,
        'dropoff_location': dropoffLocation,
        'vehicle_type':     vehicleType,
        'booking_type':     bookingType,
        if (driverId != null) 'driver_id': driverId,
        if (scheduledDate != null) 'scheduled_date': scheduledDate,
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        if (passengerLatitude != null)
          'passenger_latitude': passengerLatitude,
        if (passengerLongitude != null)
          'passenger_longitude': passengerLongitude,
      };

      final response = await _apiService.post('/bookings', data);
      _bookings.insert(0, Booking.fromJson(response['booking']));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get passenger's bookings
  Future<void> getPassengerBookings() async {
    _isLoading = true;
    _errorMessage = null;
    _bookings = [];
    notifyListeners();

    try {
      final response = await _apiService.get('/bookings/passenger');
      _bookings = (response['bookings'] as List)
          .map((booking) => Booking.fromJson(booking))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get available bookings (for drivers)
  Future<void> getAvailableBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/bookings/available');
      _bookings = (response['bookings'] as List)
          .map((booking) => Booking.fromJson(booking))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/bookings/$bookingId/cancel', {});
      await getPassengerBookings();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Delete a completed or cancelled booking permanently
  Future<void> deleteBooking(int bookingId) async {
    try {
      await _apiService.delete('/bookings/$bookingId');
      // Remove from local list immediately
      _bookings.removeWhere((b) => b.id == bookingId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}