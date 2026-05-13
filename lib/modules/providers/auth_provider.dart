import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _resetUserName;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String? get resetUserName => _resetUserName;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String userType,
    required String phone,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'name':      name,
        'email':     email,
        'password':  password,
        'user_type': userType,
        'phone':     phone,
        if (vehicleType != null)   'vehicle_type':   vehicleType,
        if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
        if (licenseNumber != null) 'license_number': licenseNumber,
      };

      final response = await _apiService.post('/register', data);
      await _apiService.saveToken(response['token']);
      _user = User.fromJson(response['user']);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(
    String name,
    String password, {
    String? fcmToken,
  }) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/login', {
        'name':      name,
        'password':  password,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });

      await _apiService.saveToken(response['token']);
      _user = User.fromJson(response['user']);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/logout', {});
    } catch (e) {
      // Ignore error, logout anyway
    }
    await _apiService.removeToken();
    _user = null;
    notifyListeners();
  }

  // ✅ Updated to support email
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? email,
    String? imagePath,
  }) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        name:      name,
        phone:     phone,
        email:     email,
        imagePath: imagePath,
      );

      _user = User.fromJson(response['user']);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUserProfile() async {
    try {
      final response = await _apiService.get('/profile');
      _user = User.fromJson(response['user']);
      notifyListeners();
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/change-password', {
        'current_password': currentPassword,
        'new_password':     newPassword,
        'confirm_password': confirmPassword,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/forgot-password', {
        'email': email,
      });

      _resetUserName = response['userName'];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/reset-password', {
        'email':            email,
        'token':            token,
        'new_password':     newPassword,
        'confirm_password': confirmPassword,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }
}