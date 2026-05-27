import 'package:flutter/material.dart';

import '../models/vocabulary_item.dart';
import '../services/vocabulary_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_routes.dart';
import '../widgets/soft_card.dart';
import 'vocabulary_game_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  late Future<List<VocabularyItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = VocabularyStorageService().loadVocabulary();
  }

  void _refresh() {
    setState(() => _future = VocabularyStorageService().loadVocabulary());
  }

  Future<void> _deleteItem(VocabularyItem item) async {
    await VocabularyStorageService().deleteVocabularyItem(item);
    if (!mounted) return;
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${item.token.surface}')),
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirm(
      title: 'Clear vocabulary?',
      message: 'This removes every saved word from the vocabulary list.',
    );
    if (!confirmed) return;
    await VocabularyStorageService().clear();
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('単語帳'),
        actions: [
          IconButton(
            tooltip: 'Vocabulary game',
            icon: const Icon(Icons.extension_rounded),
            onPressed: () =>
                Navigator.push(context, appRoute(const VocabularyGameScreen())),
          ),
          IconButton(
            tooltip: 'Clear vocabulary',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _clearAll,
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: FutureBuilder<List<VocabularyItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SoftCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No saved vocabulary yet.',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap a word in the reader and save it here.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              if (index == 0) {
                return SoftCard(
                  color: const Color(0xFFFFFCF8),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.extension_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meaning Sprint',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 17)),
                            const SizedBox(height: 3),
                            Text(
                              'Practice your saved words with a fast quiz.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.push(
                            context, appRoute(const VocabularyGameScreen())),
                        child: const Text('Play'),
                      ),
                    ],
                  ),
                );
              }

              final item = items[index - 1];
              return SoftCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.volume_up_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.token.surface,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 17)),
                          const SizedBox(height: 3),
                          Text(
                            '${item.token.reading} · ${item.token.meaning}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.muted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.token.jlpt,
                      style: const TextStyle(
                          color: Color(0xFF29A35A),
                          fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      tooltip: 'Delete word',
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.muted),
                      onPressed: () => _deleteItem(item),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirm(
      {required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    return result ?? false;
  }
}
