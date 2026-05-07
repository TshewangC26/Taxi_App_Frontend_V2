class TaxiRoute {
  final int id;
  final String pickupLocation;
  final String dropoffLocation;
  final String price4Seater;
  final String price7Seater;
  final String price8Seater;
  final bool isActive;

  TaxiRoute({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.price4Seater,
    required this.price7Seater,
    required this.price8Seater,
    required this.isActive,
  });

  // Create TaxiRoute from JSON
  factory TaxiRoute.fromJson(Map<String, dynamic> json) {
    return TaxiRoute(
      id: json['id'],
      pickupLocation: json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      price4Seater: json['price_4_seater'].toString(),
      price7Seater: json['price_7_seater'].toString(),
      price8Seater: json['price_8_seater'].toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  // Get price based on vehicle type
  String getPriceForVehicle(String vehicleType) {
    switch (vehicleType) {
      case '4-seater':
        return price4Seater;
      case '7-seater':
        return price7Seater;
      case '8-seater':
        return price8Seater;
      default:
        return price4Seater;
    }
  }
}