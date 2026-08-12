import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../theme/app_theme.dart';

class CircleControlButton extends StatefulWidget {
  const CircleControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.haptic = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool haptic;

  @override
  State<CircleControlButton> createState() => _CircleControlButtonState();
}

class _CircleControlButtonState extends State<CircleControlButton> {
  bool _pressed = false;

  void _tap() {
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _tap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: AppMotion.fast,
            curve: AppMotion.easing,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Barlow',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceMute,
            ),
          ),
        ],
      ),
    );
  }
}
