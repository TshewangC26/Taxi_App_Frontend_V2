import 'package:flutter/material.dart';
import '../models/taxi_route.dart';
import '../models/location.dart';
import '../services/api_service.dart';

class RouteProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _clean(dynamic e) {
    final msg = e.toString();
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }

  List<TaxiRoute> _routes    = [];
  List<Location>  _locations = [];
  bool _isLoading            = false;
  String? _errorMessage;

  // Getters
  List<TaxiRoute> get routes => _routes;
  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get all routes — uses public endpoint (no admin required)
  Future<void> getRoutes() async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/routes');

      _routes = (response['routes'] as List)
          .map((route) => TaxiRoute.fromJson(route))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _clean(e);
      _isLoading    = false;
      notifyListeners();
    }
  }

  // Get all locations — extracted from routes
  Future<void> getLocations() async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/routes');

      final routes = (response['routes'] as List)
          .map((route) => TaxiRoute.fromJson(route))
          .toList();

      // Extract unique location names from routes
      final Set<String> locationNames = {};
      for (final route in routes) {
        locationNames.add(route.pickupLocation);
        locationNames.add(route.dropoffLocation);
      }

      // Create Location objects with index as id
      int index = 1;
      _locations = locationNames.map((name) {
        return Location(
          id:       index++,
          name:     name,
          isActive: true,
        );
      }).toList();

      _locations.sort((a, b) => a.name.compareTo(b.name));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
    }
  }

  // Find route price between two locations
  TaxiRoute? findRoute(String pickupLocation, String dropoffLocation) {
    try {
      return _routes.firstWhere(
        (route) =>
            route.pickupLocation == pickupLocation &&
            route.dropoffLocation == dropoffLocation &&
            route.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  List<Location> getAllLocations() {
    return _locations;
  }
}