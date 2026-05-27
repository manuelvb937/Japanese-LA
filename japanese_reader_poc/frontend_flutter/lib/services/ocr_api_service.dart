import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/ocr_result.dart';

class OCRApiException implements Exception {
  OCRApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OCRApiService {
  OCRApiService({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment('BACKEND_URL',
                defaultValue: 'http://127.0.0.1:8000');

  final String _baseUrl;

  Future<OCRResult> processImage(File file, {required String mode}) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/ocr/image'))
          ..fields['mode'] = mode
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
    return _send(request);
  }

  Future<OCRResult> processImageBytes(
    Uint8List bytes, {
    required String filename,
    required String mode,
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/ocr/image'))
      ..fields['mode'] = mode
      ..files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    return _send(request);
  }

  Future<OCRResult> processPdf(File file,
      {int maxPages = 3, String mode = 'document'}) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/ocr/pdf'))
          ..fields['mode'] = mode
          ..fields['max_pages'] = '$maxPages'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
    return _send(request);
  }

  Future<OCRResult> processPdfBytes(
    Uint8List bytes, {
    required String filename,
    int maxPages = 3,
    String mode = 'document',
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/ocr/pdf'))
      ..fields['mode'] = mode
      ..fields['max_pages'] = '$maxPages'
      ..files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    return _send(request);
  }

  Future<OCRResult> _send(http.MultipartRequest request) async {
    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode >= 400) {
        throw OCRApiException(_errorMessage(body, response.statusCode));
      }
      return OCRResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } on OCRApiException {
      rethrow;
    } on SocketException {
      throw OCRApiException(
          'Could not reach the OCR backend at $_baseUrl. Is FastAPI running?');
    } on FormatException {
      throw OCRApiException('The OCR backend returned an unexpected response.');
    }
  }

  String _errorMessage(String body, int statusCode) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // Fall back to the raw body below.
    }
    return body.isEmpty ? 'OCR request failed with HTTP $statusCode.' : body;
  }
}
