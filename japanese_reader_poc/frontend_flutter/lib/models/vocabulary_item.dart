import 'japanese_token.dart';

class VocabularyItem {
  const VocabularyItem({required this.token, required this.savedAt});

  final JapaneseToken token;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'token': token.toJson(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory VocabularyItem.fromJson(Map<String, dynamic> json) => VocabularyItem(
        token: JapaneseToken.fromJson(json['token'] as Map<String, dynamic>),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}
