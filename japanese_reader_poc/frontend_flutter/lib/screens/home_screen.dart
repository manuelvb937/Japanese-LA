import 'package:flutter/material.dart';

import 'recent_scans_screen.dart';
import 'scan_options_screen.dart';
import 'vocabulary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            Text('YomuScan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Scan Japanese from signs, books, and PDFs.\n日本語をスキャンして学ぼう。'),
            const SizedBox(height: 24),
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFDAE0FF), Color(0xFFEFE3FF)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: Icon(Icons.auto_stories_rounded, size: 72, color: Color(0xFF4C5BDF))),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanOptionsScreen())),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Scan Japanese'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen())),
                  child: const Text('Vocabulary'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentScansScreen())),
                  child: const Text('Recent scans'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
