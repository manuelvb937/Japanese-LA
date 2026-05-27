import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_project.dart';

class ProjectStorageService {
  static const _key = 'study_projects';

  Future<List<StudyProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((entry) {
          try {
            return StudyProject.fromJson(
                jsonDecode(entry) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<StudyProject>()
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<StudyProject> createProject(
      {required String title, String description = ''}) async {
    final project = StudyProject.create(title: title, description: description);
    final projects = await loadProjects();
    projects.insert(0, project);
    await _saveAll(projects);
    return project;
  }

  Future<void> touchProject(String projectId) async {
    final projects = await loadProjects();
    final updated = projects
        .map((project) => project.id == projectId ? project.touch() : project)
        .toList();
    await _saveAll(updated);
  }

  Future<void> deleteProject(String projectId) async {
    final projects = await loadProjects();
    await _saveAll(
        projects.where((project) => project.id != projectId).toList());
  }

  Future<void> _saveAll(List<StudyProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, projects.map((project) => jsonEncode(project.toJson())).toList());
  }
}
