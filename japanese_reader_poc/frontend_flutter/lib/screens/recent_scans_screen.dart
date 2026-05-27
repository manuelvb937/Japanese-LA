import 'package:flutter/material.dart';

import '../models/recent_scan.dart';
import '../services/recent_scan_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_routes.dart';
import '../widgets/soft_card.dart';
import 'reader_screen.dart';

class RecentScansScreen extends StatefulWidget {
  const RecentScansScreen({super.key});

  @override
  State<RecentScansScreen> createState() => _RecentScansScreenState();
}

class _RecentScansScreenState extends State<RecentScansScreen> {
  late Future<List<RecentScan>> _future;

  @override
  void initState() {
    super.initState();
    _future = RecentScanStorageService().loadRecentScans();
  }

  void _refresh() {
    setState(() => _future = RecentScanStorageService().loadRecentScans());
  }

  Future<void> _deleteScan(RecentScan scan) async {
    final confirmed = await _confirm(
      title: 'Delete scan?',
      message:
          'This removes "${scan.pageLabel ?? scan.title}" from recent scans and projects.',
    );
    if (!confirmed) return;
    await RecentScanStorageService().deleteScan(scan.id);
    if (!mounted) return;
    _refresh();
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirm(
      title: 'Clear recent scans?',
      message: 'This removes every saved scan from recents and project pages.',
    );
    if (!confirmed) return;
    await RecentScanStorageService().clear();
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近のスキャン'),
        actions: [
          IconButton(
            tooltip: 'Clear scans',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _clearAll,
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: FutureBuilder<List<RecentScan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final scans = snapshot.data ?? [];
          if (scans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SoftCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.history_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No recent scans yet.',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Scans you run will appear here and can be reopened.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            itemCount: scans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final scan = scans[index];
              return SoftCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_iconFor(scan), color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scan.pageLabel == null
                                ? scan.title
                                : '${scan.pageLabel} · ${scan.title}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (scan.projectTitle != null) ...[
                            Text(
                              scan.projectTitle!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                          ],
                          Text(
                            scan.preview.isEmpty ? scan.ocrMode : scan.preview,
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
                      tooltip: 'Delete scan',
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.muted),
                      onPressed: () => _deleteScan(scan),
                    ),
                    IconButton(
                      tooltip: 'Open scan',
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.muted),
                      onPressed: () => Navigator.push(
                        context,
                        appRoute(ReaderScreen(result: scan.result)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(RecentScan scan) {
    if (scan.sourceType == 'pdf') return Icons.picture_as_pdf_rounded;
    return Icons.image_rounded;
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
