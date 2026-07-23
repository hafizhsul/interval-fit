import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/workout_template.dart';
import '../../shared/design/tokens.dart';

const _exerciseTypes = ['skipping', 'walk', 'run', 'custom'];

class TemplateBuilderScreen extends ConsumerStatefulWidget {
  const TemplateBuilderScreen({super.key, this.existing});

  final WorkoutTemplate? existing;

  @override
  ConsumerState<TemplateBuilderScreen> createState() =>
      _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState
    extends ConsumerState<TemplateBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sets;
  late String _exerciseType;

  // Tiap durasi: nilai + unit. Disimpan sebagai detik saat save.
  late final _DurationField _work;
  late final _DurationField _rest;
  late final _DurationField _warmup;
  late final _DurationField _cooldown;

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'New Template' : 'Edit Template',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              style: Theme.of(context).textTheme.bodyLarge,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Exercise type'),
              style: Theme.of(context).textTheme.bodyLarge,
              items: _exerciseTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _exerciseType = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _sets,
              decoration: const InputDecoration(labelText: 'Number of sets'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.bodyLarge,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n <= 0) ? 'Sets must be > 0' : null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _DurationInput(label: 'Work', field: _work, requirePositive: true),
            const SizedBox(height: AppSpacing.md),
            _DurationInput(label: 'Rest', field: _rest),
            const SizedBox(height: AppSpacing.md),
            _DurationInput(label: 'Warm-up (optional)', field: _warmup),
            const SizedBox(height: AppSpacing.md),
            _DurationInput(label: 'Cooldown (optional)', field: _cooldown),
          ],
        ),
      ),
      // Save pinned to the bottom so it's always reachable without scrolling.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: FilledButton(
          onPressed: _save,
          child: Text('Save', style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}

/// State satu input durasi: controller nilai + unit (detik/menit).
class _DurationField {
  _DurationField(this.controller, this.isMinutes);

  factory _DurationField.fromSeconds(int seconds) {
    // Tampilkan menit kalau kelipatan 60 & > 0, selain itu detik.
    if (seconds > 0 && seconds % 60 == 0) {
      return _DurationField(
          TextEditingController(text: (seconds ~/ 60).toString()), true);
    }
    return _DurationField(
        TextEditingController(text: seconds.toString()), false);
  }

  final TextEditingController controller;
  bool isMinutes;

  int get seconds {
    // Terima koma ATAU titik sebagai pemisah desimal (locale ID pakai koma).
    // Detik dibulatkan ke bilangan bulat: mis. 1,2 menit -> 72 detik.
    final raw = controller.text.replaceAll(',', '.').trim();
    final v = double.tryParse(raw) ?? 0;
    return isMinutes ? (v * 60).round() : v.round();
  }

  void dispose() => controller.dispose();
}

class _DurationInput extends StatefulWidget {
  const _DurationInput({
    required this.label,
    required this.field,
    this.requirePositive = false,
  });

  final String label;
  final _DurationField field;
  final bool requirePositive;

  @override
  State<_DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends State<_DurationInput> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: widget.field.controller,
            decoration: InputDecoration(labelText: widget.label),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Izinkan digit + satu pemisah desimal (koma/titik) untuk mis. 1,5 menit.
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: Theme.of(context).textTheme.bodyLarge,
            validator: widget.requirePositive
                ? (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return (n == null || n <= 0) ? 'Must be > 0' : null;
                  }
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        DropdownButton<bool>(
          value: widget.field.isMinutes,
          items: const [
            DropdownMenuItem(value: false, child: Text('sec')),
            DropdownMenuItem(value: true, child: Text('min')),
          ],
          onChanged: (v) => setState(() => widget.field.isMinutes = v!),
        ),
      ],
    );
  }
}
