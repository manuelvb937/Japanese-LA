import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/japanese_token.dart';
import '../theme/app_theme.dart';

class VerticalJapaneseText extends StatefulWidget {
  const VerticalJapaneseText({
    super.key,
    required this.text,
    required this.tokens,
    required this.onTapToken,
  });

  final String text;
  final List<JapaneseToken> tokens;
  final ValueChanged<JapaneseToken> onTapToken;

  @override
  State<VerticalJapaneseText> createState() => _VerticalJapaneseTextState();
}

class _VerticalJapaneseTextState extends State<VerticalJapaneseText> {
  static const _charHeight = 30.0;
  static const _columnExtent = 64.0;

  int _page = 0;
  String? _hoveredTokenKey;
  String? _pendingHoveredTokenKey;
  bool _hoverUpdateScheduled = false;

  @override
  void didUpdateWidget(covariant VerticalJapaneseText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.tokens != widget.tokens) {
      _page = 0;
      _hoveredTokenKey = null;
      _pendingHoveredTokenKey = null;
      _hoverUpdateScheduled = false;
    }
  }

  void _queueHover(String? tokenKey) {
    _pendingHoveredTokenKey = tokenKey;
    if (_hoverUpdateScheduled) return;

    _hoverUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hoverUpdateScheduled = false;
      final next = _pendingHoveredTokenKey;
      if (_hoveredTokenKey == next) return;
      setState(() => _hoveredTokenKey = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = widget.text.trim();
    if (cleanText.isEmpty) {
      return Text(
        'No text found.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.muted),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaHeight = MediaQuery.sizeOf(context).height;
        final readerHeight =
            math.min(620.0, math.max(260.0, mediaHeight - 360.0));
        final maxCharsPerColumn =
            math.max(6, ((readerHeight - 24) / _charHeight).floor());
        final columns = _buildColumns(cleanText, maxCharsPerColumn);
        final columnsPerPage =
            math.max(1, ((constraints.maxWidth - 36) / _columnExtent).floor());
        final pageCount = math.max(1, (columns.length / columnsPerPage).ceil());
        final safePage = _page.clamp(0, pageCount - 1);

        if (safePage != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _page = safePage);
          });
        }

        final start = safePage * columnsPerPage;
        final end = math.min(start + columnsPerPage, columns.length);
        final visibleColumns = columns.sublist(start, end);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: readerHeight,
              width: double.infinity,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          visibleColumns.reversed.map(_buildColumn).toList(),
                    ),
                  ),
                ),
              ),
            ),
            if (pageCount > 1) ...[
              const SizedBox(height: 14),
              _PageControls(
                currentPage: safePage + 1,
                pageCount: pageCount,
                onPrevious: safePage == 0
                    ? null
                    : () => setState(() => _page = safePage - 1),
                onNext: safePage >= pageCount - 1
                    ? null
                    : () => setState(() => _page = safePage + 1),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildColumn(List<_VerticalPiece> column) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        padding: const EdgeInsets.only(right: 7),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFFEFE9FF), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: column.map(_buildPiece).toList(),
        ),
      ),
    );
  }

  Widget _buildPiece(_VerticalPiece piece) {
    final token = piece.token;
    final isHovered =
        piece.tokenKey != null && piece.tokenKey == _hoveredTokenKey;
    final chars = piece.text.runes
        .map((rune) => _verticalGlyph(String.fromCharCode(rune)))
        .toList();
    final markerColor = isHovered
        ? AppColors.primaryDark
        : AppColors.primary.withValues(alpha: 0.7);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isHovered ? const Color(0x107C4DFF) : Colors.transparent,
        border: token == null
            ? null
            : Border(
                right: BorderSide(
                    color: markerColor, width: isHovered ? 2.4 : 1.6),
              ),
        borderRadius: isHovered ? BorderRadius.circular(8) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: chars
            .map(
              (char) => SizedBox(
                height: _charHeight,
                width: 30,
                child: Center(
                  child: Text(
                    char,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (token == null) return content;

    return Tooltip(
      message: token.surface,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _queueHover(piece.tokenKey),
        onExit: (_) {
          if (_hoveredTokenKey == piece.tokenKey) {
            _queueHover(null);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _queueHover(piece.tokenKey),
          onTapCancel: () => _queueHover(null),
          onTap: () => widget.onTapToken(token),
          child: content,
        ),
      ),
    );
  }

  List<List<_VerticalPiece>> _buildColumns(
      String rawText, int maxCharsPerColumn) {
    final segments = _buildSegments(rawText);
    final columns = <List<_VerticalPiece>>[];
    var current = <_VerticalPiece>[];
    var usedChars = 0;

    void flush() {
      if (current.isNotEmpty) {
        columns.add(current);
        current = <_VerticalPiece>[];
        usedChars = 0;
      }
    }

    void addText(String text, JapaneseToken? token, String? tokenKey) {
      var remaining = text;
      while (remaining.isNotEmpty) {
        final available = maxCharsPerColumn - usedChars;
        if (available <= 0) {
          flush();
          continue;
        }

        final runes = remaining.runes.toList();
        final take = math.min(available, runes.length);
        final chunk = String.fromCharCodes(runes.take(take));
        current.add(_VerticalPiece(chunk, token, tokenKey));
        usedChars += take;
        remaining = String.fromCharCodes(runes.skip(take));

        if (usedChars >= maxCharsPerColumn) {
          flush();
        }
      }
    }

    for (final segment in segments) {
      final lines = segment.text
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].isNotEmpty) {
          addText(lines[i], segment.token, segment.tokenKey);
        }
        if (i < lines.length - 1) {
          flush();
        }
      }
    }

    flush();
    if (columns.isEmpty) {
      return [
        const [_VerticalPiece(' ', null, null)],
      ];
    }
    return columns;
  }

  List<_TextSegment> _buildSegments(String fullText) {
    final segments = <_TextSegment>[];
    var cursor = 0;
    var tokenIndex = 0;

    for (final token in widget.tokens) {
      if (token.surface.isEmpty) continue;
      final index = fullText.indexOf(token.surface, cursor);
      if (index < 0) continue;

      if (index > cursor) {
        segments.add(_TextSegment(fullText.substring(cursor, index), null));
      }

      segments.add(
        _TextSegment(
          fullText.substring(index, index + token.surface.length),
          token,
          'token-$tokenIndex',
        ),
      );
      tokenIndex++;
      cursor = index + token.surface.length;
    }

    if (cursor < fullText.length) {
      segments.add(_TextSegment(fullText.substring(cursor), null));
    }

    return segments;
  }

  String _verticalGlyph(String char) {
    return switch (char) {
      ' ' => '　',
      '-' => '｜',
      'ー' => '｜',
      '「' => '﹁',
      '」' => '﹂',
      '『' => '﹃',
      '』' => '﹄',
      '（' => '︵',
      '）' => '︶',
      '(' => '︵',
      ')' => '︶',
      '…' => '︙',
      _ => char,
    };
  }
}

class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          tooltip: 'Previous page',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '$currentPage / $pageCount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Next page',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _TextSegment {
  const _TextSegment(this.text, this.token, [this.tokenKey]);

  final String text;
  final JapaneseToken? token;
  final String? tokenKey;
}

class _VerticalPiece {
  const _VerticalPiece(this.text, this.token, this.tokenKey);

  final String text;
  final JapaneseToken? token;
  final String? tokenKey;
}
