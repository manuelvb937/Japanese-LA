import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/ocr_result.dart';

class OCRApiService {
  OCRApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? const String.fromEnvironment('BACKEND_URL', defaultValue: 'http://127.0.0.1:8000');

  final String _baseUrl;

  Future<OCRResult> processImage(File file, {required String mode}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/ocr/image'))
      ..fields['mode'] = mode
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 400) throw Exception(body);
    return OCRResult.fromJson(jsonDecode(body));
  }

  Future<OCRResult> processPdf(File file, {int maxPages = 3}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/ocr/pdf'))
      ..fields['mode'] = 'document'
      ..fields['max_pages'] = '$maxPages'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 400) throw Exception(body);
    return OCRResult.fromJson(jsonDecode(body));
  }
}
