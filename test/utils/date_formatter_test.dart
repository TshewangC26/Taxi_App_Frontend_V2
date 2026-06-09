import 'package:flutter_test/flutter_test.dart';

String formatScheduledTime(String timeStr) {
  try {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1].padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  } catch (_) {
    return timeStr;
  }
}

String formatScheduledDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return dateStr;
  }
}

void main() {
  group('Date Time Formatter Tests', () {

    test('formatScheduledTime converts 09:00 to 9:00 AM', () {
      expect(formatScheduledTime('09:00:00'), '9:00 AM');
    });

    test('formatScheduledTime converts 14:30 to 2:30 PM', () {
      expect(formatScheduledTime('14:30:00'), '2:30 PM');
    });

    test('formatScheduledTime converts 00:00 to 12:00 AM', () {
      expect(formatScheduledTime('00:00:00'), '12:00 AM');
    });

    test('formatScheduledTime converts 12:00 to 12:00 PM', () {
      expect(formatScheduledTime('12:00:00'), '12:00 PM');
    });

    test('formatScheduledDate formats date correctly', () {
      expect(formatScheduledDate('2025-06-09'), 'Monday, 9 Jun 2025');
    });

    test('formatScheduledDate returns original string on invalid date', () {
      expect(formatScheduledDate('invalid-date'), 'invalid-date');
    });

  });
}