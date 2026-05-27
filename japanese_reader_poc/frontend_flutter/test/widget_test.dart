import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_reader_poc/main.dart';

void main() {
  testWidgets('renders home screen', (tester) async {
    await tester.pumpWidget(const JapaneseReaderApp());

    expect(find.text('和リーダー'), findsOneWidget);
    expect(find.text('スキャンする'), findsOneWidget);
  });
}
