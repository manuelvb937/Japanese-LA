import 'package:flutter/material.dart';

import '../services/vocabulary_storage_service.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary')),
      body: FutureBuilder(
        future: VocabularyStorageService().loadVocabulary(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (items.isEmpty) return const Center(child: Text('No saved vocabulary yet.'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(items[i].token.surface),
              subtitle: Text('${items[i].token.meaning} • ${items[i].token.jlpt}'),
              trailing: Text(items[i].token.reading),
            ),
          );
        },
      ),
    );
  }
}
