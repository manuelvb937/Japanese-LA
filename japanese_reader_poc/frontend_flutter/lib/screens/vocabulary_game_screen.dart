import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocabulary_item.dart';
import '../services/vocabulary_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class VocabularyGameScreen extends StatefulWidget {
  const VocabularyGameScreen({super.key});

  @override
  State<VocabularyGameScreen> createState() => _VocabularyGameScreenState();
}

class _VocabularyGameScreenState extends State<VocabularyGameScreen> {
  final _random = Random();
  late Future<List<VocabularyItem>> _future;
  List<VocabularyItem> _deck = [];
  List<VocabularyItem> _rounds = [];
  List<String> _options = [];
  int _round = 0;
  int _score = 0;
  int _streak = 0;
  String? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _future = VocabularyStorageService().loadVocabulary();
  }

  void _start(List<VocabularyItem> items) {
    _deck = [...items]..shuffle(_random);
    _rounds = _deck.take(min(10, _deck.length)).toList();
    _round = 0;
    _score = 0;
    _streak = 0;
    _selected = null;
    _answered = false;
    _buildOptions();
  }

  void _buildOptions() {
    if (_rounds.isEmpty) return;
    final answer = _rounds[_round].token.meaning;
    final distractors = _deck
        .where((item) => item.token.meaning != answer)
        .map((item) => item.token.meaning)
        .where((meaning) => meaning.trim().isNotEmpty)
        .toSet()
        .toList()
      ..shuffle(_random);

    _options = [answer, ...distractors.take(3)]..shuffle(_random);
  }

  void _choose(String option) {
    if (_answered) return;
    final correct = option == _rounds[_round].token.meaning;
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  void _next() {
    if (_round >= _rounds.length - 1) {
      setState(() => _round = _rounds.length);
      return;
    }
    setState(() {
      _round++;
      _selected = null;
      _answered = false;
      _buildOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('単語ゲーム')),
      body: FutureBuilder<List<VocabularyItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.length < 3) {
            return _EmptyGameState(count: items.length);
          }

          if (_rounds.isEmpty || _deck.length != items.length) {
            _start(items);
          }

          if (_round >= _rounds.length) {
            return _GameComplete(
              score: _score,
              total: _rounds.length,
              onPlayAgain: () => setState(() => _start(items)),
            );
          }

          final current = _rounds[_round];
          final progress = (_round + 1) / _rounds.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: AppColors.lilac,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_round + 1}/${_rounds.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SoftCard(
                color: const Color(0xFFFFFCF8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Pill(label: 'Score $_score'),
                        _Pill(label: 'Streak $_streak'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      current.token.surface,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current.token.reading,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose the meaning',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._options.map(
                (option) {
                  final isCorrect = option == current.token.meaning;
                  final isSelected = option == _selected;
                  final revealCorrect = _answered && isCorrect;
                  final revealWrong = _answered && isSelected && !isCorrect;
                  final color = revealCorrect
                      ? const Color(0xFFE6F8EE)
                      : revealWrong
                          ? const Color(0xFFFFECEC)
                          : Colors.white;
                  final borderColor = revealCorrect
                      ? const Color(0xFF29A35A)
                      : revealWrong
                          ? const Color(0xFFE05252)
                          : AppColors.border;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _choose(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: borderColor,
                              width: revealCorrect || revealWrong ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              revealCorrect
                                  ? Icons.check_circle_rounded
                                  : revealWrong
                                      ? Icons.cancel_rounded
                                      : Icons.radio_button_unchecked_rounded,
                              color: revealCorrect
                                  ? const Color(0xFF29A35A)
                                  : revealWrong
                                      ? const Color(0xFFE05252)
                                      : AppColors.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              if (_answered)
                FilledButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                      _round >= _rounds.length - 1 ? 'Finish' : 'Next word'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppColors.primaryDark, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EmptyGameState extends StatelessWidget {
  const _EmptyGameState({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.extension_rounded,
                  color: AppColors.primary, size: 48),
              const SizedBox(height: 14),
              Text(
                'Save at least 3 words to play.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You have $count saved word${count == 1 ? '' : 's'} right now.',
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
}

class _GameComplete extends StatelessWidget {
  const _GameComplete({
    required this.score,
    required this.total,
    required this.onPlayAgain,
  });

  final int score;
  final int total;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((score / total) * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SoftCard(
          color: const Color(0xFFFFFCF8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.military_tech_rounded,
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                '$score / $total',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '$percent% accuracy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
