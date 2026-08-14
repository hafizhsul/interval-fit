import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/design/tokens.dart';
import '../../shared/theme/app_theme.dart';
import '../home/home_screen.dart';

typedef Bootstrap =
    Future<List<Override>> Function({
      void Function(double progress)? onProgress,
    });

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.bootstrap, this.appBuilder});

  /// Runs app bootstrap (DB + prefs) so the progress bar reflects real work.
  /// Null uses the real DB+prefs loader.
  final Bootstrap? bootstrap;

  /// Builds the post-bootstrap app tree (ProviderScope + MaterialApp) from the
  /// resolved overrides. Defaults to the SplashScreen's own scope.
  final Widget Function(List<Override> overrides)? appBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();

  static Future<List<Override>> _defaultBootstrap({
    void Function(double progress)? onProgress,
  }) async {
    final overrides = await bootstrapOverrides(onProgress: onProgress);
    return overrides;
  }

  static Widget _defaultAppBuilder(List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: HomeScreen()),
    );
  }
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Keeps the brand on screen long enough for the entrance animation even
  /// when bootstrap is instant.
  static const _minSplash = Duration(milliseconds: 1100);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _minSplash,
  );
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _boot();
  }

  Future<void> _boot() async {
    final start = DateTime.now();
    var overrides = <Override>[];
    try {
      overrides = await (widget.bootstrap ?? SplashScreen._defaultBootstrap)(
        onProgress: (value) => setState(() => _progress = value),
      );
    } catch (_) {
      // Bootstrap failures degrade: fall through to home with no overrides
      // (DB-dependent providers then throw on read, surfaced by the screen).
    } // Let the entrance animation play even if bootstrap was instant.
    final elapsed = DateTime.now().difference(start);
    if (elapsed < _minSplash) {
      await Future<void>.delayed(_minSplash - elapsed);
    }
    if (!mounted) return;
    final app = (widget.appBuilder ?? SplashScreen._defaultAppBuilder)(
      overrides,
    );
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => app,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(begin, end, curve: AppMotion.easing),
  );

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 1.4,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.16),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Stagger(
                  animation: _interval(0, 0.35),
                  scale: true,
                  child: Image.asset(
                    'assets/images/title-icon-splash.png',
                    width: 128,
                    height: 128,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const SizedBox(width: 128, height: 128),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Stagger(
                  animation: _interval(0.22, 0.55),
                  child: _SplashWordmark(light: light),
                ),
              ],
            ),
          ),
          Positioned(
            left: 56,
            right: 56,
            bottom: 72,
            child: _Stagger(
              animation: _interval(0.45, 0.75),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0, 1),
                      backgroundColor: AppColors.onSurfaceDim.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'LOADING YOUR WORKOUTS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceMute,
                      letterSpacing: 2.2,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fade + optional scale entrance segment.
class _Stagger extends StatelessWidget {
  const _Stagger({
    required this.animation,
    required this.child,
    this.scale = false,
  });

  final Animation<double> animation;
  final Widget child;
  final bool scale;

  @override
  Widget build(BuildContext context) {
    var child = this.child;
    if (scale) {
      child = ScaleTransition(scale: animation, child: child);
    }
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Wordmark from title-logo.png: INTERVAL in drop-black on top, FIT colored
/// for the current brightness below (mirrors the home app bar logo).
class _SplashWordmark extends StatelessWidget {
  const _SplashWordmark({required this.light});

  final bool light;

  static const _dropBlack = ColorFilter.matrix([
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    1,
    1,
    1,
    0,
    0,
  ]);

  static const _fitBlack = ColorFilter.matrix([
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0.333,
    0.333,
    0.333,
    0,
    0,
  ]);

  static const _fitWhite = ColorFilter.matrix([
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0.333,
    0.333,
    0.333,
    0,
    0,
  ]);

  Widget _part({
    required Alignment alignment,
    required double heightFactor,
    required ColorFilter filter,
  }) {
    return ClipRect(
      child: Align(
        alignment: alignment,
        heightFactor: heightFactor,
        child: ColorFiltered(
          colorFilter: filter,
          child: Image.asset(
            'assets/images/title-logo.png',
            width: 150,
            height: 60,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const SizedBox(width: 150, height: 60),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Interval Fit',
      image: true,
      child: SizedBox(
        width: 150,
        height: 60,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _part(
                alignment: Alignment.topCenter,
                heightFactor: 238 / 444,
                filter: _dropBlack,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _part(
                alignment: Alignment.bottomCenter,
                heightFactor: 206 / 444,
                filter: light ? _fitBlack : _fitWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
