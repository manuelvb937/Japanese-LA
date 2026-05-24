import 'package:flutter/material.dart';

import '../models/japanese_token.dart';

class TappableJapaneseText extends StatelessWidget {
  const TappableJapaneseText({super.key, required this.tokens, required this.onTap});

  final List<JapaneseToken> tokens;
  final ValueChanged<JapaneseToken> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: tokens
          .map((t) => InkWell(
                onTap: () => onTap(t),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Text(t.surface),
                ),
              ))
          .toList(),
    );
  }
}
