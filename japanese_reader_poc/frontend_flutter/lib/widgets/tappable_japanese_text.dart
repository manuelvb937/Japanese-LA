import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/japanese_token.dart';
import '../theme/app_theme.dart';

class TappableJapaneseText extends StatefulWidget {
  const TappableJapaneseText({
    super.key,
    required this.tokens,
    required this.onTap,
    this.fullText,
  });

  final List<JapaneseToken> tokens;
  final ValueChanged<JapaneseToken> onTap;
  final String? fullText;

  @override
  State<TappableJapaneseText> createState() => _TappableJapaneseTextState();
}

class _TappableJapaneseTextState extends State<TappableJapaneseText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tokens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No tokens returned yet.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.muted),
        ),
      );
    }

    final fullText = widget.fullText;
    if (fullText == null || fullText.isEmpty) {
      return _TokenWrap(tokens: widget.tokens, onTap: widget.onTap);
    }

    return SelectableText.rich(
      TextSpan(
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              height: 1.9,
              fontWeight: FontWeight.w500,
            ),
        children: _buildSpans(context, fullText),
      ),
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context, String fullText) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final token in widget.tokens) {
      if (token.surface.isEmpty) continue;
      final index = fullText.indexOf(token.surface, cursor);
      if (index < 0) continue;

      if (index > cursor) {
        spans.add(TextSpan(text: fullText.substring(cursor, index)));
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onTap(token);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: token.surface,
          recognizer: recognizer,
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary.withValues(alpha: 0.62),
            decorationStyle: TextDecorationStyle.solid,
            decorationThickness: 1.8,
          ),
        ),
      );
      cursor = index + token.surface.length;
    }

    if (cursor < fullText.length) {
      spans.add(TextSpan(text: fullText.substring(cursor)));
    }
    return spans;
  }
}

class _TokenWrap extends StatelessWidget {
  const _TokenWrap({required this.tokens, required this.onTap});

  final List<JapaneseToken> tokens;
  final ValueChanged<JapaneseToken> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: tokens
          .map(
            (token) => InkWell(
              onTap: () => onTap(token),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lilac),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 12,
                        offset: Offset(0, 6))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      token.surface,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    if (token.reading.isNotEmpty &&
                        token.reading != token.surface) ...[
                      const SizedBox(height: 2),
                      Text(
                        token.reading,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
