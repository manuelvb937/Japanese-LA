import 'package:flutter/material.dart';

import '../models/japanese_token.dart';
import '../models/ocr_result.dart';
import '../models/vocabulary_item.dart';
import '../services/vocabulary_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/soft_card.dart';
import '../widgets/tappable_japanese_text.dart';
import '../widgets/vertical_japanese_text.dart';
import '../widgets/word_detail_bottom_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.result});

  final OCRResult result;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late _ReaderView _view;

  @override
  void initState() {
    super.initState();
    _view =
        _looksVertical(widget.result) ? _ReaderView.vertical : _ReaderView.text;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isMockResult = result.ocrMode == 'MOCK_OCR' ||
        result.pages.any((page) => page.ocrMode == 'MOCK_OCR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('読み取り結果'),
        actions: [
          IconButton(
            tooltip: 'OCR mode',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(isMockResult
                      ? 'OCR mode: MOCK_OCR. Restart backend without -Mock for real scans.'
                      : 'OCR mode: ${result.ocrMode}')),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          const AppBottomNav(currentIndex: 2, allowSelectedNavigation: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: '原文',
                  selected: _view == _ReaderView.text,
                  onTap: () => setState(() => _view = _ReaderView.text),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegmentButton(
                  label: '縦書き',
                  selected: _view == _ReaderView.vertical,
                  onTap: () => setState(() => _view = _ReaderView.vertical),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegmentButton(
                  label: '単語タップ',
                  selected: _view == _ReaderView.tokens,
                  onTap: () => setState(() => _view = _ReaderView.tokens),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMockResult) ...[
            const _MockOcrWarning(),
            const SizedBox(height: 16),
          ],
          SoftCard(
            color: const Color(0xFFFFFCF8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _ReaderContent(
                key: ValueKey(_view),
                view: _view,
                result: result,
                onTapToken: _showWordDetail,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (result.pages.isNotEmpty) ...[
            _PageSummary(result: result),
            const SizedBox(height: 16),
          ],
          Text(
            _readerHint(_view),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showWordDetail(JapaneseToken token) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordDetailBottomSheet(
        token: token,
        onSave: () async {
          await VocabularyStorageService().saveVocabularyItem(
            VocabularyItem(token: token, savedAt: DateTime.now()),
          );
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to vocabulary')));
        },
      ),
    );
  }

  String _readerHint(_ReaderView view) {
    return switch (view) {
      _ReaderView.text => '行区切りを保った読み取りテキスト',
      _ReaderView.vertical => '小説・漫画などの縦書きページ用レイアウト',
      _ReaderView.tokens => '単語をタップして詳細を確認できます',
    };
  }
}

enum _ReaderView { text, vertical, tokens }

class _ReaderContent extends StatelessWidget {
  const _ReaderContent({
    super.key,
    required this.view,
    required this.result,
    required this.onTapToken,
  });

  final _ReaderView view;
  final OCRResult result;
  final ValueChanged<JapaneseToken> onTapToken;

  @override
  Widget build(BuildContext context) {
    return switch (view) {
      _ReaderView.tokens => TappableJapaneseText(
          tokens: result.tokens,
          fullText: result.fullText,
          onTap: onTapToken,
        ),
      _ReaderView.vertical => VerticalJapaneseText(
          text: result.fullText,
          tokens: result.tokens,
          onTapToken: onTapToken,
        ),
      _ReaderView.text => Text(
          result.fullText.isEmpty ? 'No text found.' : result.fullText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                height: 1.9,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w500,
              ),
        ),
    };
  }
}

bool _looksVertical(OCRResult result) {
  final boxes = result.pages
      .expand((page) => page.words)
      .map((word) => word.boundingBox)
      .where((box) => box.length >= 2);
  var measured = 0;
  var vertical = 0;

  for (final box in boxes) {
    final xs = box.map((point) => point.x);
    final ys = box.map((point) => point.y);
    final width =
        xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b);
    final height =
        ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b);
    if (width <= 0 || height <= 0) continue;
    measured++;
    if (height > width * 1.35) vertical++;
  }

  if (measured >= 8) {
    return vertical / measured > 0.45;
  }

  final lines = result.fullText
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.length < 5) return false;
  final japaneseChars = RegExp(r'[\u3040-\u30ff\u3400-\u9fff]')
      .allMatches(result.fullText)
      .length;
  final averageLineLength =
      lines.map((line) => line.trim().runes.length).reduce((a, b) => a + b) /
          lines.length;
  return japaneseChars > 20 && averageLineLength <= 24;
}

class _MockOcrWarning extends StatelessWidget {
  const _MockOcrWarning();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      color: const Color(0xFFFFF7E8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB26A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mock OCR is on: this is sample text, not your scan. Stop the backend, run .\\run_backend.ps1 without -Mock, then re-scan. Old saved mock scans stay mock.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B4300),
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageSummary extends StatelessWidget {
  const _PageSummary({required this.result});

  final OCRResult result;

  @override
  Widget build(BuildContext context) {
    final pageModes = result.pages
        .map((page) => page.ocrMode)
        .whereType<String>()
        .where((mode) => mode.isNotEmpty)
        .toSet()
        .join(', ');
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${result.pages.length} page${result.pages.length == 1 ? '' : 's'} · ${pageModes.isEmpty ? result.ocrMode : pageModes}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: selected ? AppColors.lilac : AppColors.border),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: Color(0x147C4DFF),
                      blurRadius: 14,
                      offset: Offset(0, 6))
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.primaryDark : AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
