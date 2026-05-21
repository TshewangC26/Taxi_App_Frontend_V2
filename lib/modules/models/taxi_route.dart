class TaxiRoute {
  final int id;
  final String pickupLocation;
  final String dropoffLocation;
  final bool isActive;
  final Map<String, double> prices; // ✅ dynamic prices

  TaxiRoute({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.isActive,
    required this.prices,
  });

  factory TaxiRoute.fromJson(Map<String, dynamic> json) {
    // ✅ Parse dynamic prices from route_prices
    final Map<String, double> parsedPrices = {};
    final rawPrices = json['prices'];
    if (rawPrices is Map) {
      rawPrices.forEach((key, value) {
        parsedPrices[key.toString()] =
            double.tryParse(value['price']?.toString() ?? '0') ?? 0;
      });
    }

    return TaxiRoute(
      id:              json['id'],
      pickupLocation:  json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      isActive:        json['is_active'] == 1 || json['is_active'] == true,
      prices:          parsedPrices,
    );
  }

  // ✅ Get price for any vehicle type dynamically
  String getPriceForVehicle(String vehicleType) {
    final price = prices[vehicleType];
    if (price == null) return '0';
    return price % 1 == 0 ? price.toInt().toString() : price.toString();
  }

  // ✅ Keep backward compatibility
  String get price4Seater => getPriceForVehicle('4-seater');
  String get price7Seater => getPriceForVehicle('7-seater');
  String get price8Seater => getPriceForVehicle('8-seater');
}