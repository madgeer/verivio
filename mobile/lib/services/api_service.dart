import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import '../models/verification_models.dart';

class ApiService {
  String get baseUrl {
    // Check if a backend URL was injected at build time via --dart-define
    const String injectedUrl = String.fromEnvironment('BACKEND_URL');
    if (injectedUrl.isNotEmpty) {
      return injectedUrl;
    }

    if (kIsWeb) {
      final baseUri = Uri.base;
      // If we are developing locally on a different port than the backend (5000), target local backend
      if (baseUri.host == 'localhost' || baseUri.host == '127.0.0.1') {
        if (baseUri.port != 5000) {
          return 'http://localhost:5000/api/v1';
        }
      }
      // Production or unified port deployment: target current host dynamically
      return '${baseUri.scheme}://${baseUri.authority}/api/v1';
    } else {
      // Default to the live Japan West Azure production server so it works out-of-the-box on physical devices
      return 'https://verivio-backend-japan-rizki.azurewebsites.net/api/v1';
    }
  }

  Future<VerificationData> verifyAnswer(String answer) async {
    final url = Uri.parse('$baseUrl/verify');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'answer': answer}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return VerificationData.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Verification failed on server');
        }
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? 'Server error (status code: ${response.statusCode})');
      }
    } catch (e) {
      // Return a friendly error
      throw Exception('Tidak dapat terhubung ke server backend Verivio di $baseUrl. Pastikan backend server Anda sudah menyala (jalankan "npm run dev" di folder backend). Detail error: $e');
    }
  }

  Future<String> getAiResponse(String prompt) async {
    final url = Uri.parse('$baseUrl/chat');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return responseData['answer'] ?? '';
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get chat response from server');
        }
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? 'Server error (status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi chat API: $e');
    }
  }
}
