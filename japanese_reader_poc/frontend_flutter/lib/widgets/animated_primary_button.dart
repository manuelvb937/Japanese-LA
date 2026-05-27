import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnimatedPrimaryButton extends StatefulWidget {
  const AnimatedPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.97 : (_hovered && enabled ? 1.02 : 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? [
                        _hovered ? const Color(0xFF8C62FF) : AppColors.primary,
                        AppColors.primaryDark,
                      ]
                    : [AppColors.muted, AppColors.muted],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (_hovered ? AppColors.primary : AppColors.primaryDark)
                      .withValues(alpha: enabled ? 0.32 : 0),
                  blurRadius: _hovered ? 28 : 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
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
