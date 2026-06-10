import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://taxiappbackendv2-kspb-production.up.railway.app/api';

  // ✅ Cloudinary credentials
  static const String _cloudinaryCloudName = 'dh0m3238u';
  static const String _cloudinaryUploadPreset = 'easy_ride';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  // ✅ Upload image to Cloudinary and return download URL
  Future<String?> uploadImageToCloudinary(String imagePath) async {
    try {
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _cloudinaryUploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imagePath),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        print('Cloudinary upload error: $responseBody');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload exception: $e');
      return null;
    }
  }

  // ✅ Updated to upload photo to Cloudinary first
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? email,
    String? imagePath,
  }) async {
    final token = await getToken();

    String? photoUrl;
    if (imagePath != null) {
      photoUrl = await uploadImageToCloudinary(imagePath);
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/update'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['name']  = name;
    request.fields['phone'] = phone;
    if (email != null && email.isNotEmpty) {
      request.fields['email'] = email;
    }
    if (photoUrl != null) {
      request.fields['profile_photo_url'] = photoUrl;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
  }) async {
    final token = await getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$endpoint'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields.addAll(fields);

    if (fileField != null && filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath(fileField, filePath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDriverPaymentDetails(int bookingId) async {
    return await get('/driver/payment-details/$bookingId');
  }

  Future<Map<String, dynamic>> createPayment({
    required int bookingId,
    required String paymentMethod,
    String? transactionId,
    String? screenshotPath,
    String? notes,
  }) async {
    final token = await getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/payments'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['booking_id']     = bookingId.toString();
    request.fields['payment_method'] = paymentMethod;
    if (transactionId != null)
      request.fields['transaction_id'] = transactionId;
    if (notes != null) request.fields['notes'] = notes;

    if (screenshotPath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('screenshot', screenshotPath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // ✅ Rate a driver after completed ride
  Future<Map<String, dynamic>> rateDriver({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    return await post('/bookings/$bookingId/rate', {
      'rating':         rating,
      'rating_comment': comment ?? '',
    });
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String friendlyMessage = 'Something went wrong. Please try again.';
      try {
        final errorBody = jsonDecode(response.body);
        final msg = errorBody['message']?.toString() ?? '';
        if (msg.isNotEmpty && !msg.contains('{')) {
          friendlyMessage = msg;
        }
      } catch (_) {}
      throw Exception(friendlyMessage);
    }
  }
}