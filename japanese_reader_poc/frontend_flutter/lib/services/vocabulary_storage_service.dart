import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary_item.dart';

class VocabularyStorageService {
  static const _key = 'saved_vocabulary';

  Future<List<VocabularyItem>> loadVocabulary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => VocabularyItem.fromJson(jsonDecode(e))).toList();
  }

  Future<void> saveVocabularyItem(VocabularyItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_key, list);
  }
}
