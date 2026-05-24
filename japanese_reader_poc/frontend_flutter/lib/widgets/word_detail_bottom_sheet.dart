import 'package:flutter/material.dart';

import '../models/japanese_token.dart';

class WordDetailBottomSheet extends StatelessWidget {
  const WordDetailBottomSheet({super.key, required this.token, required this.onSave});

  final JapaneseToken token;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(token.surface, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text('Lemma: ${token.lemma}'),
        Text('Reading: ${token.reading}'),
        Text('POS: ${token.pos}'),
        Text('Meaning: ${token.meaning}'),
        Text('JLPT: ${token.jlpt}'),
        const SizedBox(height: 16),
        FilledButton(onPressed: onSave, child: const Text('Save to vocabulary')),
      ]),
    );
  }
}
