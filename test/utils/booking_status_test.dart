import 'package:flutter_test/flutter_test.dart';

String getStatusLabel(String status) {
  switch (status) {
    case 'pending':     return 'Pending';
    case 'accepted':    return 'Accepted';
    case 'in_progress': return 'On the Way';
    case 'completed':   return 'Completed';
    case 'cancelled':   return 'Cancelled';
    default:            return status;
  }
}

bool shouldShowDriver(String bookingType, String status) {
  if (bookingType == 'scheduled') return status == 'in_progress';
  return status == 'accepted' || status == 'in_progress';
}

bool isDriverNoShow(String? scheduledDate, String? scheduledTime) {
  try {
    if (scheduledDate == null || scheduledTime == null) return false;
    final parts = scheduledTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final scheduledDateTime = DateTime.parse(scheduledDate)
        .copyWith(hour: hour, minute: minute);
    return DateTime.now().isAfter(scheduledDateTime);
  } catch (_) {
    return false;
  }
}

void main() {
  group('Booking Status Tests', () {

    test('getStatusLabel returns correct label for pending', () {
      expect(getStatusLabel('pending'), 'Pending');
    });

    test('getStatusLabel returns correct label for accepted', () {
      expect(getStatusLabel('accepted'), 'Accepted');
    });

    test('getStatusLabel returns correct label for in_progress', () {
      expect(getStatusLabel('in_progress'), 'On the Way');
    });

    test('getStatusLabel returns correct label for completed', () {
      expect(getStatusLabel('completed'), 'Completed');
    });

    test('getStatusLabel returns correct label for cancelled', () {
      expect(getStatusLabel('cancelled'), 'Cancelled');
    });

    test('shouldShowDriver returns true for now booking accepted', () {
      expect(shouldShowDriver('now', 'accepted'), true);
    });

    test('shouldShowDriver returns false for scheduled booking accepted', () {
      expect(shouldShowDriver('scheduled', 'accepted'), false);
    });

    test('shouldShowDriver returns true for scheduled booking in_progress', () {
      expect(shouldShowDriver('scheduled', 'in_progress'), true);
    });

    test('isDriverNoShow returns false for future scheduled time', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      final date = future.toIso8601String().split('T')[0];
      final time = '${future.hour}:${future.minute}:00';
      expect(isDriverNoShow(date, time), false);
    });

    test('isDriverNoShow returns true for past scheduled time', () {
      final past = DateTime.now().subtract(const Duration(hours: 2));
      final date = past.toIso8601String().split('T')[0];
      final time = '${past.hour}:${past.minute}:00';
      expect(isDriverNoShow(date, time), true);
    });

  });
}