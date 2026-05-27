import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary_item.dart';

class VocabularyStorageService {
  static const _key = 'saved_vocabulary';

  Future<List<VocabularyItem>> loadVocabulary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((entry) {
          try {
            return VocabularyItem.fromJson(
                jsonDecode(entry) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<VocabularyItem>()
        .toList();
  }

  Future<void> saveVocabularyItem(VocabularyItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final items = await loadVocabulary();
    final alreadySaved = items.any((saved) =>
        saved.token.surface == item.token.surface &&
        saved.token.lemma == item.token.lemma);
    if (alreadySaved) return;

    list.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_key, list);
  }

  Future<void> deleteVocabularyItem(VocabularyItem item) async {
    final items = await loadVocabulary();
    final remaining = items.where((saved) {
      return saved.token.surface != item.token.surface ||
          saved.token.lemma != item.token.lemma;
    }).toList();
    await _saveAll(remaining);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _saveAll(List<VocabularyItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, items.map((item) => jsonEncode(item.toJson())).toList());
  }
}
