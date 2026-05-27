import 'package:flutter/material.dart';

import '../models/recent_scan.dart';
import '../models/study_project.dart';
import '../services/recent_scan_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_primary_button.dart';
import '../widgets/app_routes.dart';
import '../widgets/soft_card.dart';
import 'reader_screen.dart';
import 'scan_options_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.project});

  final StudyProject project;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<List<RecentScan>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadScans();
  }

  Future<List<RecentScan>> _loadScans() async {
    final scans = await RecentScanStorageService().loadRecentScans();
    return scans.where((scan) => scan.projectId == widget.project.id).toList();
  }

  void _addPage(List<RecentScan> scans) {
    Navigator.push(
      context,
      appRoute(
        ScanOptionsScreen(
          projectId: widget.project.id,
          projectTitle: widget.project.title,
          pageLabel: 'Page ${scans.length + 1}',
        ),
      ),
    ).then((_) => setState(() => _future = _loadScans()));
  }

  Future<void> _deleteScan(RecentScan scan) async {
    final confirmed = await _confirm(
      title: 'Delete page?',
      message:
          'This removes "${scan.pageLabel ?? scan.title}" from this project.',
    );
    if (!confirmed) return;
    await RecentScanStorageService().deleteScan(scan.id);
    if (!mounted) return;
    setState(() => _future = _loadScans());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.title)),
      body: FutureBuilder<List<RecentScan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final scans = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              SoftCard(
                color: const Color(0xFFFFFCF8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.project.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    if (widget.project.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(widget.project.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.muted)),
                    ],
                    const SizedBox(height: 14),
                    Text(
                        '${scans.length} saved page${scans.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedPrimaryButton(
                icon: Icons.document_scanner_rounded,
                label: 'ページを追加',
                onPressed: () => _addPage(scans),
              ),
              const SizedBox(height: 18),
              if (scans.isEmpty)
                SoftCard(
                  child: Text(
                    'Scan page 3, 5, 7, 8, or any later chapter into this project. They will stay grouped here.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.muted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...scans.map((scan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.lavender,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.menu_book_rounded,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scan.pageLabel ?? scan.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    scan.preview.isEmpty
                                        ? scan.ocrMode
                                        : scan.preview,
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
                              tooltip: 'Delete page',
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.muted),
                              onPressed: () => _deleteScan(scan),
                            ),
                            IconButton(
                              tooltip: 'Open page',
                              icon: const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.muted),
                              onPressed: () => Navigator.push(context,
                                  appRoute(ReaderScreen(result: scan.result))),
                            ),
                          ],
                        ),
                      ),
                    )),
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
