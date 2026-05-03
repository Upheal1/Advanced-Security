import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL for the UpHeal backend.
///
/// **⚠️ FOR PHYSICAL DEVICE TESTING:**
/// 
/// 1. Find your computer's local IP address:
///    - **Windows**: Open CMD and run: `ipconfig`
///      Look for "IPv4 Address" under your WiFi adapter (e.g., 192.168.1.100)
///    - **Mac/Linux**: Open Terminal and run: `ifconfig` or `ip addr`
///      Look for "inet" address (not 127.0.0.1, e.g., 192.168.1.100)
///
/// 2. Make sure:
///    - Your phone and computer are on the **same WiFi network**
///    - Your API server is running (`python main.py` in the API folder)
///    - Windows Firewall allows connections on port 8000
///
/// 3. Update the URL below:
///    - Replace `YOUR_COMPUTER_IP` with your actual IP (e.g., `http://192.168.1.100:8000`)
///    - Or use the emulator URL if testing on emulator: `http://10.0.2.2:8000`
///
/// **Quick IP Commands:**
/// - Windows: `ipconfig | findstr IPv4`
/// - Mac/Linux: `ifconfig | grep "inet " | grep -v 127.0.0.1`
///
/// **Current Configuration:**
/// - Emulator: `http://10.0.2.2:8000` ✅ (works for Android emulator)
/// - Physical Device: `http://YOUR_COMPUTER_IP:8000` ⚠️ (UPDATE THIS!)
const String uphealBaseUrl = 'http://192.168.1.8:8000'; // ⚠️ Change to your computer's IP for physical device!

class UphealApi {
  final String baseUrl;

  const UphealApi({required this.baseUrl});

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Simple health check against `{baseUrl}/health`.
  Future<Map<String, dynamic>> health() async {
    final response = await http.get(_uri('/health'));
    if (response.statusCode != 200) {
      throw Exception(
        'Health check failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      return body;
    }
    throw Exception('Unexpected health response shape: $body');
  }

  /// Call the assessment endpoint `{baseUrl}/api/assess`.
  ///
  /// Body:
  /// ```json
  /// {
  ///   "answers": { "gad7_q1": 0, ... },
  ///   "user_id": "user_123",
  ///   "session_id": "optional"
  /// }
  /// ```
  Future<Map<String, dynamic>> assess({
    required Map<String, int> answers,
    required String userId,
    String? sessionId,
  }) async {
    final uri = _uri('/api/assess');
    final payload = <String, dynamic>{
      'answers': answers,
      'user_id': userId,
    };
    if (sessionId != null) {
      payload['session_id'] = sessionId;
    }

    // Log request for debugging
    print('[UphealApi] Request URL: $uri');
    print('[UphealApi] Request payload: ${jsonEncode(payload)}');
    print('[UphealApi] Answers count: ${answers.length}');
    print('[UphealApi] Answer types: ${answers.map((k, v) => MapEntry(k, v.runtimeType))}');

    try {
      final response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request to $uri timed out after 30 seconds');
        },
      );

      print('[UphealApi] Response status: ${response.statusCode}');
      print('[UphealApi] Response body length: ${response.body.length}');

      if (response.statusCode != 200) {
        print('[UphealApi] Error response: ${response.body}');
        throw Exception(
          'Assess failed (${response.statusCode}): ${response.body}',
        );
      }

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        print('[UphealApi] Response parsed successfully');
        return body;
      }
      throw Exception('Unexpected assess response shape: $body');
    } catch (e) {
      print('[UphealApi] Exception during API call: $e');
      rethrow;
    }
  }
}


