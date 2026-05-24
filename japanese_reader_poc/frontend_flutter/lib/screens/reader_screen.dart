import 'package:flutter/material.dart';

import '../models/ocr_result.dart';
import '../models/vocabulary_item.dart';
import '../services/vocabulary_storage_service.dart';
import '../widgets/tappable_japanese_text.dart';
import '../widgets/word_detail_bottom_sheet.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key, required this.result});
  final OCRResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reader')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('OCR Mode: ${result.ocrMode}'),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(result.fullText))),
          const SizedBox(height: 16),
          Text('Tap a word', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TappableJapaneseText(
            tokens: result.tokens,
            onTap: (token) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => WordDetailBottomSheet(
                  token: token,
                  onSave: () async {
                    await VocabularyStorageService().saveVocabularyItem(
                      VocabularyItem(token: token, savedAt: DateTime.now()),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to vocabulary')));
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
