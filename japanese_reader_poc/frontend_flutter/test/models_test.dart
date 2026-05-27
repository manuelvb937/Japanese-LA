import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_reader_poc/models/japanese_token.dart';
import 'package:japanese_reader_poc/models/ocr_result.dart';
import 'package:japanese_reader_poc/models/recent_scan.dart';
import 'package:japanese_reader_poc/models/study_project.dart';

void main() {
  test('OCRResult round trips through JSON', () {
    const token = JapaneseToken(
      surface: '日本語',
      lemma: '日本語',
      reading: 'にほんご',
      pos: 'noun',
      meaning: 'Japanese language',
      jlpt: 'N5',
    );
    const result = OCRResult(
      sourceType: 'image',
      ocrMode: 'DOCUMENT_TEXT_DETECTION',
      fullText: '日本語を勉強します。',
      pages: [OCRPage(pageNumber: 1, text: '日本語を勉強します。', words: [])],
      tokens: [token],
    );

    final decoded = OCRResult.fromJson(result.toJson());

    expect(decoded.fullText, result.fullText);
    expect(decoded.pages.single.pageNumber, 1);
    expect(decoded.tokens.single.reading, 'にほんご');
  });

  test('RecentScan stores a short preview', () {
    const result = OCRResult(
      sourceType: 'pdf',
      ocrMode: 'PDF_TEXT_EXTRACTION',
      fullText: '日本語を勉強します。\n毎日読みます。',
      pages: [],
      tokens: [],
    );

    final scan = RecentScan.fromResult(
      result: result,
      title: 'sample.pdf',
      projectId: 'project-1',
      projectTitle: 'Water Magician',
      pageLabel: 'Page 3',
    );

    expect(scan.title, 'sample.pdf');
    expect(scan.preview, contains('日本語'));
    expect(scan.result.ocrMode, 'PDF_TEXT_EXTRACTION');
    expect(scan.projectTitle, 'Water Magician');
    expect(scan.pageLabel, 'Page 3');
  });

  test('StudyProject round trips and updates timestamp', () {
    final project =
        StudyProject.create(title: 'Water Magician', description: 'Volume 1');
    final decoded = StudyProject.fromJson(project.toJson());

    expect(decoded.title, 'Water Magician');
    expect(decoded.description, 'Volume 1');
    expect(
        decoded.touch().updatedAt.isAfter(decoded.createdAt) ||
            decoded.touch().updatedAt.isAtSameMomentAs(decoded.createdAt),
        isTrue);
  });
}
