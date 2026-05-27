import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SoftCard extends StatefulWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color = AppColors.surface,
    this.hoverColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  final Color? hoverColor;

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final color = interactive && _hovered
        ? widget.hoverColor ?? AppColors.lavender
        : widget.color;
    final content = AnimatedScale(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.975 : (_hovered && interactive ? 1.015 : 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color:
                  _hovered && interactive ? AppColors.lilac : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: _hovered && interactive
                  ? const Color(0x247C4DFF)
                  : const Color(0x12000000),
              blurRadius: _hovered && interactive ? 26 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onTap,
            splashColor: AppColors.lilac.withValues(alpha: 0.5),
            highlightColor: AppColors.lavender.withValues(alpha: 0.55),
            child: content,
          ),
        ),
      ),
    );
  }
}
