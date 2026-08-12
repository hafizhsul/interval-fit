import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/workout_template.dart';
import '../../shared/design/tokens.dart';
import '../../shared/theme/app_theme.dart';

const _exerciseTypes = ['skipping', 'walk', 'run', 'custom'];

class TemplateBuilderScreen extends ConsumerStatefulWidget {
  const TemplateBuilderScreen({super.key, this.existing});

  final WorkoutTemplate? existing;

  @override
  ConsumerState<TemplateBuilderScreen> createState() =>
      _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends ConsumerState<TemplateBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sets;
  late String _exerciseType;

  late final _DurationField _work;
  late final _DurationField _rest;
  late final _DurationField _warmup;
  late final _DurationField _cooldown;

  String _totalText = '';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _sets = TextEditingController(text: (e?.sets ?? 1).toString());
    _exerciseType = e?.exerciseType ?? 'skipping';
    if (!_exerciseTypes.contains(_exerciseType)) _exerciseType = 'custom';
    _work = _DurationField.fromSeconds(e?.workSeconds ?? 30);
    _rest = _DurationField.fromSeconds(e?.restSeconds ?? 15);
    _warmup = _DurationField.fromSeconds(e?.warmupSeconds ?? 0);
    _cooldown = _DurationField.fromSeconds(e?.cooldownSeconds ?? 0);

    _name.addListener(_recalc);
    _sets.addListener(_recalc);
    _work.controller.addListener(_recalc);
    _rest.controller.addListener(_recalc);
    _warmup.controller.addListener(_recalc);
    _cooldown.controller.addListener(_recalc);
    _recalc();
  }

  void _recalc() {
    final sets = int.tryParse(_sets.text) ?? 0;
    final total =
        _warmup.seconds +
        _cooldown.seconds +
        sets * (_work.seconds + _rest.seconds);
    final m = total ~/ 60;
    final s = total % 60;
    final text = m > 0 ? '$m min $s sec' : '$s sec';
    if (text != _totalText) {
      _totalText = text;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _name.removeListener(_recalc);
    _sets.removeListener(_recalc);
    _work.controller.removeListener(_recalc);
    _rest.controller.removeListener(_recalc);
    _warmup.controller.removeListener(_recalc);
    _cooldown.controller.removeListener(_recalc);
    _name.dispose();
    _sets.dispose();
    _work.dispose();
    _rest.dispose();
    _warmup.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    final now = DateTime.now().millisecondsSinceEpoch;
    final template = WorkoutTemplate(
      id: existing?.id,
      name: _name.text.trim(),
      exerciseType: _exerciseType,
      sets: int.parse(_sets.text),
      workSeconds: _work.seconds,
      restSeconds: _rest.seconds,
      warmupSeconds: _warmup.seconds,
      cooldownSeconds: _cooldown.seconds,
      isDefault: existing?.isDefault ?? false,
      createdAt: existing?.createdAt ?? now,
    );
    final repo = ref.read(templateRepositoryProvider);
    if (existing == null) {
      await repo.create(template);
    } else {
      await repo.update(template);
    }
    ref.invalidate(templateListProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Color _accentFor(String type) {
    switch (type) {
      case 'run':
        return AppColors.work;
      case 'walk':
        return AppColors.cooldown;
      case 'skipping':
        return AppColors.primary;
      default:
        return AppColors.rest;
    }
  }

  void _adjustSets(int delta) {
    final next = (int.tryParse(_sets.text) ?? 1) + delta;
    if (next >= 1) _sets.text = next.toString();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(_exerciseType);
    final isEditing = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _BuilderHeader(
                title: isEditing ? 'Edit session' : 'New session',
                subtitle: isEditing
                    ? 'Tune the rhythm of this workout'
                    : 'Build a session that fits your pace',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      _SessionPreview(
                        accent: accent,
                        name: _name.text.trim().isEmpty
                            ? 'Untitled session'
                            : _name.text.trim(),
                        type: _exerciseType,
                        total: _totalText,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel(
                        eyebrow: '01 / IDENTITY',
                        title: 'Name your session',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _BuilderCard(
                        icon: Icons.edit_note_rounded,
                        iconColor: accent,
                        child: TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Morning intervals',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel(
                        eyebrow: '02 / MOVEMENT',
                        title: 'Choose your movement',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MovementPicker(
                        selected: _exerciseType,
                        onChanged: (value) =>
                            setState(() => _exerciseType = value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel(
                        eyebrow: '03 / RHYTHM',
                        title: 'Set the interval',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _BuilderCard(
                        icon: Icons.layers_rounded,
                        iconColor: accent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rounds',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _sets.text.isEmpty ? '1' : _sets.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: AppColors.onSurface),
                                  ),
                                ],
                              ),
                            ),
                            _RoundButton(
                              icon: Icons.remove,
                              onTap: () => _adjustSets(-1),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _RoundButton(
                              icon: Icons.add,
                              filled: true,
                              onTap: () => _adjustSets(1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DurationCard(
                        label: 'Work',
                        subtitle: 'Push your pace',
                        field: _work,
                        color: AppColors.work,
                        icon: Icons.bolt_rounded,
                        requirePositive: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DurationCard(
                        label: 'Rest',
                        subtitle: 'Reset between rounds',
                        field: _rest,
                        color: AppColors.rest,
                        icon: Icons.air_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DurationCard(
                        label: 'Warm-up',
                        subtitle: 'Optional preparation',
                        field: _warmup,
                        color: AppColors.warmup,
                        icon: Icons.local_fire_department_outlined,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DurationCard(
                        label: 'Cooldown',
                        subtitle: 'Optional recovery',
                        field: _cooldown,
                        color: AppColors.cooldown,
                        icon: Icons.spa_outlined,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _TotalCard(total: _totalText, accent: accent),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text(isEditing ? 'Update session' : 'Save Template'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuilderHeader extends StatelessWidget {
  const _BuilderHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
              foregroundColor: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'SETUP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({
    required this.accent,
    required this.name,
    required this.type,
    required this.total,
  });

  final Color accent;
  final String name;
  final String type;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Image.asset(
              _movementAsset(type),
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSION PREVIEW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  total,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _MovementPicker extends StatelessWidget {
  const _MovementPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _exerciseTypes.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final type = _exerciseTypes[index];
          final isSelected = type == selected;
          final color = _movementColor(type);
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 82,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _movementIcon(type),
                    color: isSelected ? Colors.white : color,
                    size: 25,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _pretty(type),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuilderCard extends StatelessWidget {
  const _BuilderCard({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: filled ? AppColors.primary : AppColors.surface,
        foregroundColor: filled ? AppColors.background : AppColors.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
            color: filled ? AppColors.primary : AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _DurationCard extends StatefulWidget {
  const _DurationCard({
    required this.label,
    required this.subtitle,
    required this.field,
    required this.color,
    required this.icon,
    this.requirePositive = false,
  });

  final String label;
  final String subtitle;
  final _DurationField field;
  final Color color;
  final IconData icon;
  final bool requirePositive;

  @override
  State<_DurationCard> createState() => _DurationCardState();
}

class _DurationCardState extends State<_DurationCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          8,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(widget.icon, color: widget.color, size: 21),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    widget.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 46,
              child: TextFormField(
                controller: widget.field.controller,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.onSurface),
                validator: widget.requirePositive
                    ? (value) {
                        final number = double.tryParse(
                          (value ?? '').replaceAll(',', '.'),
                        );
                        return number == null || number <= 0 ? '!' : null;
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            _UnitSelector(
              field: widget.field,
              work: widget.label == 'Work',
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({
    required this.field,
    required this.work,
    required this.onChanged,
  });

  final _DurationField field;
  final bool work;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitChip(
            label: work ? 'sec' : 's',
            selected: !field.isMinutes,
            onTap: () {
              field.isMinutes = false;
              onChanged();
            },
          ),
          _UnitChip(
            label: work ? 'min' : 'm',
            selected: field.isMinutes,
            onTap: () {
              field.isMinutes = true;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.onSurfaceMute,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.accent});

  final String total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED DURATION',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: accent, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  total,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: accent),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline_rounded, color: accent),
        ],
      ),
    );
  }
}

class _DurationField {
  _DurationField(this.controller, this.isMinutes);

  factory _DurationField.fromSeconds(int seconds) {
    if (seconds > 0 && seconds % 60 == 0) {
      return _DurationField(
        TextEditingController(text: (seconds ~/ 60).toString()),
        true,
      );
    }
    return _DurationField(
      TextEditingController(text: seconds.toString()),
      false,
    );
  }

  final TextEditingController controller;
  bool isMinutes;

  int get seconds {
    final raw = controller.text.replaceAll(',', '.').trim();
    final value = double.tryParse(raw) ?? 0;
    return isMinutes ? (value * 60).round() : value.round();
  }

  void dispose() => controller.dispose();
}

String _pretty(String type) => type[0].toUpperCase() + type.substring(1);

String _movementAsset(String type) {
  switch (type) {
    case 'skipping':
      return 'assets/images/skipping.png';
    case 'walk':
      return 'assets/images/walk.png';
    case 'run':
      return 'assets/images/run.png';
    default:
      return 'assets/images/run.png';
  }
}

IconData _movementIcon(String type) {
  switch (type) {
    case 'skipping':
      return Icons.sports_handball_rounded;
    case 'walk':
      return Icons.directions_walk_rounded;
    case 'run':
      return Icons.directions_run_rounded;
    default:
      return Icons.fitness_center_rounded;
  }
}

Color _movementColor(String type) {
  switch (type) {
    case 'run':
      return AppColors.work;
    case 'walk':
      return AppColors.cooldown;
    case 'skipping':
      return AppColors.primary;
    default:
      return AppColors.rest;
  }
}
