import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/constants.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class AuthService {
  static final String _apiKey = dotenv.env['API_KEY'] ?? '';

  static Future<Map<String, dynamic>?> login(String username, String password, String ssaid) async {
    try {
      // Define the data as a simple Map
      final Map<String, String> bodyData = {
        "api_key": _apiKey,
        "username": username,
        "password": password,
      };

      final response = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: {
          // This header tells PHP to populate the $_POST array
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
        },
        // IMPORTANT: Pass bodyData directly. Flutter will handle the encoding.
        body: bodyData,
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: Sending Key: $_apiKey"); // Verify key isn't empty in logs
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "Server error ${response.statusCode}"};
      }
    } catch (e) {
      print("DEBUG CONNECTION ERROR: $e");
      return {"status": "error", "message": "Connection error"};
    }
  }
}