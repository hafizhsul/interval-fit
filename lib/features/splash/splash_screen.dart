import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    _fadeCtrl.forward();
    _goHome();
  }

  Future<void> _goHome() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _fade,
            child: Image.asset(
              'assets/images/splashscreen.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 48,
            right: 48,
            bottom: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  backgroundColor: AppColors.onSurfaceDim.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
