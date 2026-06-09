import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_app_flutter/modules/models/booking.dart';

void main() {
  group('Booking Model Tests', () {

    test('Booking parses from JSON correctly', () {
      final json = {
        'id': 1,
        'passenger_id': 5,
        'driver_id': null,
        'pickup_location': 'Clocktower',
        'dropoff_location': 'Paro Airport',
        'status': 'pending',
        'booking_type': 'now',
        'vehicle_type': '4-seater',
        'estimated_price': '500',
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

      expect(booking.id, 1);
      expect(booking.passengerId, 5);
      expect(booking.pickupLocation, 'Clocktower');
      expect(booking.dropoffLocation, 'Paro Airport');
      expect(booking.status, 'pending');
      expect(booking.bookingType, 'now');
      expect(booking.vehicleType, '4-seater');
      expect(booking.estimatedPrice, '500');
      expect(booking.finalPrice, null);
      expect(booking.driverId, null);
      expect(booking.rating, null);
    });

  });
}