class JapaneseToken {
  const JapaneseToken({
    required this.surface,
    required this.lemma,
    required this.reading,
    required this.pos,
    required this.meaning,
    required this.jlpt,
  });

  final String surface;
  final String lemma;
  final String reading;
  final String pos;
  final String meaning;
  final String jlpt;

  factory JapaneseToken.fromJson(Map<String, dynamic> json) => JapaneseToken(
        surface: json['surface'] ?? '',
        lemma: json['lemma'] ?? '',
        reading: json['reading'] ?? '',
        pos: json['pos'] ?? '',
        meaning: json['meaning'] ?? 'Dictionary entry not found yet',
        jlpt: json['jlpt'] ?? 'unknown',
      );

  Map<String, dynamic> toJson() => {
        'surface': surface,
        'lemma': lemma,
        'reading': reading,
        'pos': pos,
        'meaning': meaning,
        'jlpt': jlpt,
      };
}
