import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://taxiappbackendv2-kspb-production.up.railway.app/api';

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

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? imagePath,
  }) async {
    final token = await getToken();

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

    if (imagePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_photo', imagePath),
      );
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

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.body}');
    }
  }
}