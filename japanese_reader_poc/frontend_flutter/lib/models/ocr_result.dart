import 'japanese_token.dart';

class OCRPoint {
  const OCRPoint({required this.x, required this.y});

  final int x;
  final int y;

  factory OCRPoint.fromJson(Map<String, dynamic> json) => OCRPoint(
        x: json['x'] ?? 0,
        y: json['y'] ?? 0,
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class OCRWord {
  const OCRWord({required this.text, required this.boundingBox});

  final String text;
  final List<OCRPoint> boundingBox;

  factory OCRWord.fromJson(Map<String, dynamic> json) => OCRWord(
        text: json['text'] ?? '',
        boundingBox: (json['bounding_box'] as List<dynamic>? ?? [])
            .map((point) => OCRPoint.fromJson(point as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'bounding_box': boundingBox.map((point) => point.toJson()).toList(),
      };
}

class OCRPage {
  const OCRPage({
    required this.pageNumber,
    required this.text,
    required this.words,
    this.ocrMode,
  });

  final int pageNumber;
  final String text;
  final List<OCRWord> words;
  final String? ocrMode;

  factory OCRPage.fromJson(Map<String, dynamic> json) => OCRPage(
        pageNumber: json['page_number'] ?? 0,
        text: json['text'] ?? '',
        words: (json['words'] as List<dynamic>? ?? [])
            .map((word) => OCRWord.fromJson(word as Map<String, dynamic>))
            .toList(),
        ocrMode: json['ocr_mode'],
      );

  Map<String, dynamic> toJson() => {
        'page_number': pageNumber,
        'text': text,
        'words': words.map((word) => word.toJson()).toList(),
        if (ocrMode != null) 'ocr_mode': ocrMode,
      };
}

class OCRResult {
  const OCRResult({
    required this.sourceType,
    required this.ocrMode,
    required this.fullText,
    required this.pages,
    required this.tokens,
  });

  final String sourceType;
  final String ocrMode;
  final String fullText;
  final List<OCRPage> pages;
  final List<JapaneseToken> tokens;

  factory OCRResult.fromJson(Map<String, dynamic> json) => OCRResult(
        sourceType: json['source_type'] ?? '',
        ocrMode: json['ocr_mode'] ?? '',
        fullText: json['full_text'] ?? '',
        pages: (json['pages'] as List<dynamic>? ?? [])
            .map((page) => OCRPage.fromJson(page as Map<String, dynamic>))
            .toList(),
        tokens: (json['tokens'] as List<dynamic>? ?? [])
            .map((t) => JapaneseToken.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'source_type': sourceType,
        'ocr_mode': ocrMode,
        'full_text': fullText,
        'pages': pages.map((page) => page.toJson()).toList(),
        'tokens': tokens.map((token) => token.toJson()).toList(),
      };
}
