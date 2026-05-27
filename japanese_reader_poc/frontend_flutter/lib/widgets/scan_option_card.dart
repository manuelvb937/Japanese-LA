import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'soft_card.dart';

class ScanOptionCard extends StatelessWidget {
  const ScanOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.wide = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      color: const Color(0xFFFFFBFF),
      padding: EdgeInsets.symmetric(horizontal: wide ? 18 : 14, vertical: 18),
      child: wide
          ? _WideContent(icon: icon, title: title, subtitle: subtitle)
          : _CompactContent(icon: icon, title: title, subtitle: subtitle),
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconBadge(icon: icon),
        const SizedBox(height: 14),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.muted),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _WideContent extends StatelessWidget {
  const _WideContent(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBadge(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [AppColors.lilac, AppColors.lavender]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: AppColors.primary, size: 28),
    );
  }
}
