import 'ocr_result.dart';

class RecentScan {
  const RecentScan({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.ocrMode,
    required this.preview,
    required this.createdAt,
    required this.result,
    this.projectId,
    this.projectTitle,
    this.pageLabel,
  });

  final String id;
  final String title;
  final String sourceType;
  final String ocrMode;
  final String preview;
  final DateTime createdAt;
  final OCRResult result;
  final String? projectId;
  final String? projectTitle;
  final String? pageLabel;

  factory RecentScan.fromResult({
    required OCRResult result,
    required String title,
    String? projectId,
    String? projectTitle,
    String? pageLabel,
  }) {
    final trimmed = result.fullText.trim().replaceAll(RegExp(r'\s+'), ' ');
    return RecentScan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      sourceType: result.sourceType,
      ocrMode: result.ocrMode,
      preview: trimmed.length > 90 ? '${trimmed.substring(0, 90)}...' : trimmed,
      createdAt: DateTime.now(),
      result: result,
      projectId: projectId,
      projectTitle: projectTitle,
      pageLabel: pageLabel,
    );
  }

  factory RecentScan.fromJson(Map<String, dynamic> json) => RecentScan(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Untitled scan',
        sourceType: json['sourceType'] ?? '',
        ocrMode: json['ocrMode'] ?? '',
        preview: json['preview'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        result: OCRResult.fromJson(json['result'] as Map<String, dynamic>),
        projectId: json['projectId'],
        projectTitle: json['projectTitle'],
        pageLabel: json['pageLabel'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceType': sourceType,
        'ocrMode': ocrMode,
        'preview': preview,
        'createdAt': createdAt.toIso8601String(),
        'result': result.toJson(),
        if (projectId != null) 'projectId': projectId,
        if (projectTitle != null) 'projectTitle': projectTitle,
        if (pageLabel != null) 'pageLabel': pageLabel,
      };
}
