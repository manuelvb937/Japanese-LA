import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animated_primary_button.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_routes.dart';
import '../widgets/soft_card.dart';
import 'projects_screen.dart';
import 'recent_scans_screen.dart';
import 'scan_options_screen.dart';
import 'vocabulary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text('和',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '和リーダー',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan, read, and grow your Japanese.',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _HeroScene(),
            const SizedBox(height: 24),
            AnimatedPrimaryButton(
              icon: Icons.camera_alt_rounded,
              label: 'スキャンする',
              onPressed: () =>
                  Navigator.push(context, appRoute(const ScanOptionsScreen())),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                _QuickAction(
                  icon: Icons.folder_rounded,
                  label: 'プロジェクト',
                  caption: 'Projects',
                  onTap: () =>
                      Navigator.push(context, appRoute(const ProjectsScreen())),
                ),
                _QuickAction(
                  icon: Icons.menu_book_rounded,
                  label: '単語帳',
                  caption: 'Vocabulary',
                  onTap: () => Navigator.push(
                      context, appRoute(const VocabularyScreen())),
                ),
                _QuickAction(
                  icon: Icons.schedule_rounded,
                  label: '最近',
                  caption: 'Recent',
                  onTap: () => Navigator.push(
                      context, appRoute(const RecentScansScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SoftCard(
              color: const Color(0xFFFFFCF6),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_stories_rounded,
                        color: Color(0xFF24A878)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '今日の一文: 手打ちうどんは、だしの香りをお楽しみください。',
                      style: textTheme.bodyMedium
                          ?.copyWith(height: 1.55, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(caption,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _HeroScene extends StatelessWidget {
  const _HeroScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8FC), Color(0xFFEAE4FF)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 28, offset: Offset(0, 16)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CustomPaint(
          painter: _ScenePainter(),
          child: Stack(
            children: [
              Positioned(
                left: 24,
                top: 22,
                child: Text(
                  'スキャンして、読む。\n語彙を増やそう。',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
              ),
              Positioned(
                right: 22,
                top: 24,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('あ',
                      style: TextStyle(
                          fontSize: 28,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFE9D6FF);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), 40, paint);
    paint.color = const Color(0xFFFFC8DB);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.56), 46, paint);

    final mountain = Path()
      ..moveTo(size.width * 0.30, size.height * 0.72)
      ..lineTo(size.width * 0.52, size.height * 0.36)
      ..lineTo(size.width * 0.76, size.height * 0.72)
      ..close();
    paint.color = const Color(0xFFC9D6FF);
    canvas.drawPath(mountain, paint);

    final snow = Path()
      ..moveTo(size.width * 0.47, size.height * 0.45)
      ..lineTo(size.width * 0.52, size.height * 0.36)
      ..lineTo(size.width * 0.58, size.height * 0.46)
      ..lineTo(size.width * 0.53, size.height * 0.43)
      ..close();
    paint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawPath(snow, paint);

    paint.color = const Color(0xFFFF9AB8);
    final gateTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          size.width * 0.35, size.height * 0.62, size.width * 0.30, 10),
      const Radius.circular(4),
    );
    canvas.drawRRect(gateTop, paint);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.40, size.height * 0.66, 10, 48), paint);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.66, 10, 48), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * 0.38, size.height * 0.75, size.width * 0.24, 8),
        const Radius.circular(4),
      ),
      paint,
    );

    paint.color = Colors.white.withValues(alpha: 0.72);
    canvas.drawOval(
        Rect.fromLTWH(-20, size.height * 0.82, size.width + 40, 74), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
