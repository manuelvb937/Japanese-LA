import 'package:flutter/material.dart';

import '../models/recent_scan.dart';
import '../models/study_project.dart';
import '../services/project_storage_service.dart';
import '../services/recent_scan_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_primary_button.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_routes.dart';
import '../widgets/soft_card.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Future<_ProjectsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProjectsData> _load() async {
    final projects = await ProjectStorageService().loadProjects();
    final scans = await RecentScanStorageService().loadRecentScans();
    return _ProjectsData(projects: projects, scans: scans);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _createProject() async {
    final result = await showDialog<_ProjectDraft>(
      context: context,
      builder: (_) => const _CreateProjectDialog(),
    );
    if (result == null || result.title.trim().isEmpty) return;
    final project = await ProjectStorageService().createProject(
      title: result.title,
      description: result.description,
    );
    if (!mounted) return;
    _refresh();
    Navigator.push(context, appRoute(ProjectDetailScreen(project: project)));
  }

  Future<void> _deleteProject(StudyProject project) async {
    final confirmed = await _confirm(
      title: 'Delete project?',
      message: 'This removes "${project.title}" and all scans saved inside it.',
    );
    if (!confirmed) return;
    await ProjectStorageService().deleteProject(project.id);
    await RecentScanStorageService().deleteProjectScans(project.id);
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プロジェクト')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: FutureBuilder<_ProjectsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              snapshot.data ?? const _ProjectsData(projects: [], scans: []);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              AnimatedPrimaryButton(
                icon: Icons.create_new_folder_rounded,
                label: '新しいプロジェクト',
                onPressed: _createProject,
              ),
              const SizedBox(height: 18),
              if (data.projects.isEmpty)
                SoftCard(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.folder_open_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Create a project for each book or course.',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Example: Water Magician, Minna no Nihongo, menu practice.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...data.projects.map((project) {
                  final count = data.scans
                      .where((scan) => scan.projectId == project.id)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppColors.lilac,
                                AppColors.lavender
                              ]),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.auto_stories_rounded,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17)),
                                const SizedBox(height: 3),
                                Text(
                                  '$count scan${count == 1 ? '' : 's'}${project.description.isEmpty ? '' : ' · ${project.description}'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.muted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete project',
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.muted),
                            onPressed: () => _deleteProject(project),
                          ),
                          IconButton(
                            tooltip: 'Open project',
                            icon: const Icon(Icons.chevron_right_rounded,
                                color: AppColors.muted),
                            onPressed: () => Navigator.push(
                                    context,
                                    appRoute(
                                        ProjectDetailScreen(project: project)))
                                .then((_) => _refresh()),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _confirm(
      {required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ProjectsData {
  const _ProjectsData({required this.projects, required this.scans});

  final List<StudyProject> projects;
  final List<RecentScan> scans;
}

class _ProjectDraft {
  const _ProjectDraft({required this.title, required this.description});

  final String title;
  final String description;
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Project name', hintText: 'Water Magician'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
                labelText: 'Description', hintText: 'Light novel, volume 1'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ProjectDraft(
              title: _titleController.text,
              description: _descriptionController.text,
            ),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
