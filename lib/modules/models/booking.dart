class Booking {
  final int id;
  final int passengerId;
  final int? driverId;
  final int? driverFirebaseId;
  final String pickupLocation;
  final String dropoffLocation;
  final String vehicleType;
  final String estimatedPrice;
  final String? finalPrice;
  final String status;
  final String bookingType;
  final String? scheduledDate;
  final String? scheduledTime;
  final String createdAt;
  final double? passengerLatitude;
  final double? passengerLongitude;
  // ✅ Rating field
  final int? rating;
  // ✅ Driver phone for contact
  final String? driverPhone;

  Booking({
    required this.id,
    required this.passengerId,
    this.driverId,
    this.driverFirebaseId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicleType,
    required this.estimatedPrice,
    this.finalPrice,
    required this.status,
    required this.bookingType,
    this.scheduledDate,
    this.scheduledTime,
    required this.createdAt,
    this.passengerLatitude,
    this.passengerLongitude,
    this.rating,
    this.driverPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id:                json['id'],
      passengerId:       json['passenger_id'],
      driverId:          json['driver_id'],
      driverFirebaseId:  json['driver_firebase_id'],
      pickupLocation:    json['pickup_location'],
      dropoffLocation:   json['dropoff_location'],
      vehicleType:       json['vehicle_type'],
      estimatedPrice:    json['estimated_price'].toString(),
      finalPrice:        json['final_price']?.toString(),
      status:            json['status'],
      bookingType:       json['booking_type'],
      scheduledDate:     json['scheduled_date'],
      scheduledTime:     json['scheduled_time'],
      createdAt:         json['created_at'],
      passengerLatitude: json['passenger_latitude'] != null
          ? double.tryParse(json['passenger_latitude'].toString())
          : null,
      passengerLongitude: json['passenger_longitude'] != null
          ? double.tryParse(json['passenger_longitude'].toString())
          : null,
      // ✅ Parse rating from API response
      rating: json['rating'] != null
          ? int.tryParse(json['rating'].toString())
          : null,
      // ✅ Parse driver phone from API response
      driverPhone: json['driver_phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':                  id,
      'passenger_id':        passengerId,
      'driver_id':           driverId,
      'driver_firebase_id':  driverFirebaseId,
      'pickup_location':     pickupLocation,
      'dropoff_location':    dropoffLocation,
      'vehicle_type':        vehicleType,
      'estimated_price':     estimatedPrice,
      'final_price':         finalPrice,
      'status':              status,
      'booking_type':        bookingType,
      'scheduled_date':      scheduledDate,
      'scheduled_time':      scheduledTime,
      'created_at':          createdAt,
      'passenger_latitude':  passengerLatitude,
      'passenger_longitude': passengerLongitude,
      'rating':              rating,
      'driver_phone':        driverPhone,
    };
  }
}