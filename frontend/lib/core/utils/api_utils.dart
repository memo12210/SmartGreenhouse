import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiUtils {
  static String handleException(dynamic e) {
    if (e is SocketException || e.toString().contains('SocketException')) {
      return 'Cannot connect to server. Please check your internet connection or if the backend is running.';
    } else if (e is TimeoutException) {
      return 'Connection timed out. The server might be busy.';
    } else if (e is FormatException) {
      return 'Received unexpected data from the server.';
    } else if (e is HttpException) {
      return 'HTTP error occurred while communicating with the server.';
    } else {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('ClientException')) {
        return 'Network error occurred while connecting to the server.';
      }
      return msg;
    }
  }

  static String handleResponseError(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('detail')) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) return detail.first['msg'] ?? 'Unknown error';
      }
    } catch (_) {}
    
    switch (response.statusCode) {
      case 400: return 'Bad request. Please check your input.';
      case 401: return 'Unauthorized. Please log in again.';
      case 403: return 'Permission denied.';
      case 404: return 'Resource not found.';
      case 500: return 'Internal server error. Please try again later or check the database connection.';
      default: return 'An unexpected error occurred (Status: ${response.statusCode}).';
    }
  }
}
