import 'package:flutter/material.dart';

import '../design/tokens.dart';

class ExerciseHero extends StatefulWidget {
  const ExerciseHero({
    super.key,
    required this.exerciseType,
    required this.color,
  });

  final String exerciseType;
  final Color color;

  @override
  State<ExerciseHero> createState() => _ExerciseHeroState();
}

class _ExerciseHeroState extends State<ExerciseHero> {
  double _parallaxY = 0;

  @override
  void didUpdateWidget(ExerciseHero old) {
    super.didUpdateWidget(old);
    if (old.color != widget.color) {
      setState(() => _parallaxY = -4);
      Future.delayed(AppMotion.normal, () {
        if (mounted) setState(() => _parallaxY = 0);
      });
    }
  }

  String get _assetPath {
    switch (widget.exerciseType) {
      case 'skipping':
        return 'assets/images/skipping.png';
      case 'walk':
        return 'assets/images/walk.png';
      case 'run':
        return 'assets/images/run.png';
      default:
        return 'assets/images/custom.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.easing,
      transform: Matrix4.translationValues(0, _parallaxY, 0),
      child: Image.asset(
        _assetPath,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}
