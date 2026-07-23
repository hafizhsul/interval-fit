import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  String get _asset {
    switch (widget.exerciseType) {
      case 'skipping':
        return 'assets/svg/skipping.svg';
      case 'walk':
        return 'assets/svg/walk.svg';
      case 'run':
        return 'assets/svg/run.svg';
      default:
        return 'assets/svg/custom.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.easing,
      transform: Matrix4.translationValues(0, _parallaxY, 0),
      child: SvgPicture.asset(
        _asset,
        width: 120,
        height: 120,
        colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
      ),
    );
  }
}