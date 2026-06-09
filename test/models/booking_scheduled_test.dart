import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_app_flutter/modules/models/booking.dart';

void main() {
  group('Booking Scheduled Model Tests', () {

    test('Scheduled booking parses correctly', () {
      final json = {
        'id': 2,
        'passenger_id': 5,
        'driver_id': 3,
        'pickup_location': 'Clocktower',
        'dropoff_location': 'Paro Airport',
        'status': 'accepted',
        'booking_type': 'scheduled',
        'vehicle_type': '4-seater',
        'estimated_price': '500',
        'final_price': null,
        'created_at': '2025-06-01T10:00:00',
        'scheduled_date': '2025-06-10',
        'scheduled_time': '09:00:00',
        'driver_phone': '+975 17 768 329',
        'rating': null,
        'driver_firebase_id': 5,
        'passenger_latitude': null,
        'passenger_longitude': null,
      };

      final booking = Booking.fromJson(json);

      expect(booking.bookingType, 'scheduled');
      expect(booking.scheduledDate, '2025-06-10');
      expect(booking.scheduledTime, '09:00:00');
      expect(booking.driverPhone, '+975 17 768 329');
      expect(booking.driverId, 3);
      expect(booking.driverFirebaseId, 5);
      expect(booking.status, 'accepted');
    });

    test('Completed booking has rating', () {
      final json = {
        'id': 3,
        'passenger_id': 5,
        'driver_id': 3,
        'pickup_location': 'Clocktower',
        'dropoff_location': 'Paro Airport',
        'status': 'completed',
        'booking_type': 'now',
        'vehicle_type': '4-seater',
        'estimated_price': '500',
        'final_price': '500',
        'created_at': '2025-06-01T10:00:00',
        'scheduled_date': null,
        'scheduled_time': null,
        'driver_phone': '+975 17 768 329',
        'rating': 5,
        'driver_firebase_id': 5,
        'passenger_latitude': null,
        'passenger_longitude': null,
      };

      final booking = Booking.fromJson(json);

      expect(booking.status, 'completed');
      expect(booking.rating, 5);
      expect(booking.finalPrice, '500');
    });

    test('Cancelled booking has no driver', () {
      final json = {
        'id': 4,
        'passenger_id': 5,
        'driver_id': null,
        'pickup_location': 'Clocktower',
        'dropoff_location': 'Paro Airport',
        'status': 'cancelled',
        'booking_type': 'now',
        'vehicle_type': '7-seater',
        'estimated_price': '700',
        'final_price': null,
        'created_at': '2025-06-01T10:00:00',
        'scheduled_date': null,
        'scheduled_time': null,
        'driver_phone': null,
        'rating': null,
        'driver_firebase_id': null,
        'passenger_latitude': null,
        'passenger_longitude': null,
      };

      final booking = Booking.fromJson(json);

      expect(booking.status, 'cancelled');
      expect(booking.driverId, null);
      expect(booking.driverPhone, null);
      expect(booking.vehicleType, '7-seater');
    });

  });
}