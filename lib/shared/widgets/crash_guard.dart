import 'package:flutter/widgets.dart';

/// Renders [child]; if [child]'s subtree throws during build, swaps to
/// [fallback] on the next frame instead of showing the framework's error UI.
///
/// Mechanism: build errors go through [ErrorWidget.builder]. The guard
/// overrides it, remembers the failure, restores the original builder, and
/// schedules a rebuild that swaps the failed subtree out. It catches at most
/// ONE error — after recovery the original builder is back, so a second
/// failure (e.g. the fallback itself breaking) surfaces through the normal
/// framework error path instead of looping.
class CrashGuard extends StatefulWidget {
  const CrashGuard({super.key, required this.child, required this.fallback});

  final Widget child;
  final Widget fallback;

  @override
  State<CrashGuard> createState() => _CrashGuardState();
}

class _CrashGuardState extends State<CrashGuard> {
  Widget Function(FlutterErrorDetails)? _originalBuilder;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _originalBuilder = ErrorWidget.builder;
    ErrorWidget.builder = _guardedBuilder;
  }

  @override
  void dispose() {
    ErrorWidget.builder = _originalBuilder ?? ErrorWidget.builder;
    super.dispose();
  }

  Widget _guardedBuilder(FlutterErrorDetails details) {
    if (!_failed) {
      _failed = true;
      // Stop intercepting so any later error (incl. from [fallback] itself)
      // behaves normally — prevents a recover→rethrow loop.
      ErrorWidget.builder = _originalBuilder ?? ErrorWidget.builder;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    return (_originalBuilder ?? ErrorWidget.builder)(details);
  }

  @override
  Widget build(BuildContext context) {
    return _failed ? widget.fallback : widget.child;
  }
}
