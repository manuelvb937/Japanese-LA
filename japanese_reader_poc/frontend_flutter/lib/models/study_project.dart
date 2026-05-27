class StudyProject {
  const StudyProject({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StudyProject.create(
      {required String title, String description = ''}) {
    final now = DateTime.now();
    return StudyProject(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory StudyProject.fromJson(Map<String, dynamic> json) => StudyProject(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Untitled project',
        description: json['description'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  StudyProject touch() => StudyProject(
        id: id,
        title: title,
        description: description,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
