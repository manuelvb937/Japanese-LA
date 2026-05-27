import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OCRLoadingScreen extends StatelessWidget {
  const OCRLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x177C4DFF),
                          blurRadius: 30,
                          spreadRadius: 10)
                    ],
                    border: Border.all(color: AppColors.lavender, width: 10),
                  ),
                  child: const Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark]),
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Center(
                          child: Text('あ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  '読み取り中...',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  '日本語のテキストを認識しています',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                const SizedBox(
                  width: 210,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
