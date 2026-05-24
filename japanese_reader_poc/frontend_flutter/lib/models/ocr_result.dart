import 'japanese_token.dart';

class OCRResult {
  const OCRResult({
    required this.sourceType,
    required this.ocrMode,
    required this.fullText,
    required this.tokens,
  });

  final String sourceType;
  final String ocrMode;
  final String fullText;
  final List<JapaneseToken> tokens;

  factory OCRResult.fromJson(Map<String, dynamic> json) => OCRResult(
        sourceType: json['source_type'] ?? '',
        ocrMode: json['ocr_mode'] ?? '',
        fullText: json['full_text'] ?? '',
        tokens: (json['tokens'] as List<dynamic>? ?? [])
            .map((t) => JapaneseToken.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
