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
    final work = _work.seconds;
    final rest = _rest.seconds;
    final warmup = _warmup.seconds;
    final cooldown = _cooldown.seconds;
    final total = warmup + cooldown + sets * (work + rest);
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
    final repo = ref.read(templateRepositoryProvider);
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
    final cur = int.tryParse(_sets.text) ?? 1;
    final next = cur + delta;
    if (next >= 1) {
      _sets.text = next.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(_exerciseType);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.onSurface),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceHigh,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existing == null ? 'New Template' : 'Edit Template',
                            style: const TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const Text(
                            'Create your custom workout template',
                            style: TextStyle(
                              fontFamily: 'Barlow',
                              fontSize: 13,
                              color: AppColors.onSurfaceMute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _BuilderCard(
                      icon: Icons.description_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Template Name',
                            style: TextStyle(
                              color: AppColors.onSurfaceMute,
                              fontSize: 12,
                            ),
                          ),
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              hintText: 'e.g. HIIT Cardio',
                              hintStyle: TextStyle(color: AppColors.onSurfaceDim),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BuilderCard(
                      icon: Icons.fitness_center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Exercise Type',
                                      style: TextStyle(
                                        color: AppColors.onSurfaceMute,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _exerciseType[0].toUpperCase() +
                                          _exerciseType.substring(1),
                                      style: const TextStyle(
                                        color: AppColors.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _exerciseTypes.map((type) {
                              final selected = _exerciseType == type;
                              return FilterChip(
                                label: Text(type[0].toUpperCase() + type.substring(1)),
                                selected: selected,
                                onSelected: (v) {
                                  setState(() => _exerciseType = type);
                                  _recalc();
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: AppColors.border),
                                ),
                                backgroundColor: selected ? AppColors.primary : AppColors.surfaceHigh,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : AppColors.onSurfaceMute,
                                  fontSize: 13,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BuilderCard(
                      icon: Icons.layers,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Number of Sets',
                                  style: TextStyle(
                                    color: AppColors.onSurfaceMute,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _sets.text.isEmpty ? '1' : _sets.text,
                                  style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  padding: const EdgeInsets.all(8),
                                ),
                                onPressed: () => _adjustSets(-1),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  padding: const EdgeInsets.all(8),
                                ),
                                onPressed: () => _adjustSets(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DurationCard(
                      label: 'Work',
                      subtitle: 'High intensity',
                      field: _work,
                      color: AppColors.work,
                      icon: Icons.timer_outlined,
                      requirePositive: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DurationCard(
                      label: 'Rest',
                      subtitle: 'Recovery time',
                      field: _rest,
                      color: AppColors.rest,
                      icon: Icons.local_cafe,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DurationCard(
                      label: 'Warm-up (optional)',
                      subtitle: 'Prepare your body',
                      field: _warmup,
                      color: AppColors.warmup,
                      icon: Icons.local_fire_department,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DurationCard(
                      label: 'Cooldown (optional)',
                      subtitle: 'Cool down & stretch',
                      field: _cooldown,
                      color: AppColors.cooldown,
                      icon: Icons.spa_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BuilderCard(
                      icon: Icons.access_time,
                      iconColor: accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Total Time',
                            style: TextStyle(
                              color: AppColors.onSurfaceMute,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _totalText,
                            style: TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, color: AppColors.background),
                      SizedBox(width: 8),
                      Text(
                        'Save Template',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _BuilderCard extends StatelessWidget {
  const _BuilderCard({
    required this.icon,
    this.iconColor = AppColors.primary,
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
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
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
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: AppColors.onSurfaceMute,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    validator: widget.requirePositive
                        ? (v) {
                            final n = double.tryParse(
                              (v ?? '').replaceAll(',', '.'),
                            );
                            return (n == null || n <= 0) ? '!' : null;
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UnitChip(
                      label: 'sec',
                      selected: !widget.field.isMinutes,
                      onTap: () => setState(() => widget.field.isMinutes = false),
                    ),
                    _UnitChip(
                      label: 'min',
                      selected: widget.field.isMinutes,
                      onTap: () => setState(() => widget.field.isMinutes = true),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.onSurfaceMute,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    final v = double.tryParse(raw) ?? 0;
    return isMinutes ? (v * 60).round() : v.round();
  }

  void dispose() => controller.dispose();
}
