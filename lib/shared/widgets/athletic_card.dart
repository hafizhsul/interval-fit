import 'package:flutter/material.dart';

import '../design/tokens.dart';

class AthleticCard extends StatefulWidget {
  const AthleticCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.leading,
    this.trailing,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final Widget? leading;
  final Widget? trailing;

  @override
  State<AthleticCard> createState() => _AthleticCardState();
}

class _AthleticCardState extends State<AthleticCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 0.98,
  ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easing));
  bool _down = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
    if (v) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _setDown(true) : null,
        onTapUp: widget.onTap != null ? (_) => _setDown(false) : null,
        onTapCancel: widget.onTap != null ? () => _setDown(false) : null,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                if (widget.accent != null)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.lg),
                        bottomLeft: Radius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                if (widget.leading != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: widget.leading!,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: widget.child,
                  ),
                ),
                if (widget.trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: widget.trailing!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
