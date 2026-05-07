import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ── DRIVER LOCATION ──

  // Driver sends location to Firebase
  static Future<void> updateDriverLocation({
    required int driverId,
    required double latitude,
    required double longitude,
    required String status,
    required String vehicleType,
    required String driverName,
    String? vehicleNumber,
  }) async {
    await _database.ref('drivers/$driverId').set({
      'latitude':       latitude,
      'longitude':      longitude,
      'status':         status,
      'vehicle_type':   vehicleType,
      'driver_name':    driverName,
      'vehicle_number': vehicleNumber ?? '',
      'updated_at':     DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Driver goes offline - remove from Firebase
  static Future<void> removeDriverLocation(int driverId) async {
    await _database.ref('drivers/$driverId').remove();
  }

  // Get all nearby drivers in real time (passenger uses this)
  static Stream<DatabaseEvent> getNearbyDriversStream() {
    return _database.ref('drivers').onValue;
  }

  // ── PASSENGER LOCATION ──

  // Passenger sends live location to Firebase
  // Driver uses this to see passenger moving in real time
  static Future<void> updatePassengerLocation({
    required int passengerId,
    required double latitude,
    required double longitude,
  }) async {
    await _database.ref('passengers/$passengerId').set({
      'latitude':   latitude,
      'longitude':  longitude,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Remove passenger location when ride is done
  static Future<void> removePassengerLocation(
      int passengerId) async {
    await _database.ref('passengers/$passengerId').remove();
  }

  // Get passenger live location stream (driver uses this)
  static Stream<DatabaseEvent> getPassengerLocationStream(
      int passengerId) {
    return _database.ref('passengers/$passengerId').onValue;
  }

  // ── BOOKING STATUS ──

  // Update booking status in Firebase (real time)
  static Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
    required int passengerId,
  }) async {
    await _database.ref('bookings/$bookingId').set({
      'status':       status,
      'passenger_id': passengerId,
      'updated_at':   DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Listen to booking status changes (passenger uses this)
  static Stream<DatabaseEvent> getBookingStatusStream(
      int bookingId) {
    return _database.ref('bookings/$bookingId').onValue;
  }

  // ── NOTIFICATIONS ──

  // Send notification data to Firebase
  static Future<void> sendNotification({
    required int userId,
    required String title,
    required String message,
    required String type,
  }) async {
    await _database.ref('notifications/$userId').push().set({
      'title':      title,
      'message':    message,
      'type':       type,
      'is_read':    false,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Listen to notifications for a user
  static Stream<DatabaseEvent> getNotificationsStream(
      int userId) {
    return _database.ref('notifications/$userId').onValue;
  }
}