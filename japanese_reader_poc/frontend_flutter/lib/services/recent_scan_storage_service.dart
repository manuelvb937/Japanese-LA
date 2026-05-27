import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ocr_result.dart';
import '../models/recent_scan.dart';

class RecentScanStorageService {
  static const _key = 'recent_scans';
  static const _maxItems = 20;

  Future<List<RecentScan>> loadRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((entry) {
          try {
            return RecentScan.fromJson(
                jsonDecode(entry) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentScan>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<RecentScan> saveResult(
    OCRResult result, {
    required String title,
    String? projectId,
    String? projectTitle,
    String? pageLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final scans = await loadRecentScans();
    final scan = RecentScan.fromResult(
      result: result,
      title: title,
      projectId: projectId,
      projectTitle: projectTitle,
      pageLabel: pageLabel,
    );
    scans.insert(0, scan);
    final unique = <String, RecentScan>{};
    for (final scan in scans) {
      unique.putIfAbsent(scan.id, () => scan);
    }
    final encoded = unique.values
        .take(_maxItems)
        .map((scan) => jsonEncode(scan.toJson()))
        .toList();
    await prefs.setStringList(_key, encoded);
    return scan;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> deleteScan(String scanId) async {
    final scans = await loadRecentScans();
    await _saveAll(scans.where((scan) => scan.id != scanId).toList());
  }

  Future<void> deleteProjectScans(String projectId) async {
    final scans = await loadRecentScans();
    await _saveAll(scans.where((scan) => scan.projectId != projectId).toList());
  }

  Future<void> _saveAll(List<RecentScan> scans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, scans.map((scan) => jsonEncode(scan.toJson())).toList());
  }
}
