import 'package:flutter/foundation.dart';

/// Template latihan interval. Semua durasi disimpan dalam DETIK (lihat skema DB).
/// `exercise_type` sengaja tetap String (skipping|walk|run|custom) — nilai bebas,
/// tidak dibatasi enum supaya "custom" fleksibel. ponytail: String cukup di sini.
@immutable
class WorkoutTemplate {
  final int? id; // null sebelum insert
  final String name;
  final String exerciseType;
  final int sets;
  final int workSeconds;
  final int restSeconds;
  final int warmupSeconds;
  final int cooldownSeconds;
  final bool isDefault;
  final int createdAt; // epoch ms

  const WorkoutTemplate({
    this.id,
    required this.name,
    required this.exerciseType,
    required this.sets,
    required this.workSeconds,
    required this.restSeconds,
    this.warmupSeconds = 0,
    this.cooldownSeconds = 0,
    this.isDefault = false,
    required this.createdAt,
  });

  factory WorkoutTemplate.fromMap(Map<String, Object?> map) => WorkoutTemplate(
    id: map['id'] as int?,
    name: map['name'] as String,
    exerciseType: map['exercise_type'] as String,
    sets: map['sets'] as int,
    workSeconds: map['work_seconds'] as int,
    restSeconds: map['rest_seconds'] as int,
    warmupSeconds: map['warmup_seconds'] as int,
    cooldownSeconds: map['cooldown_seconds'] as int,
    isDefault: (map['is_default'] as int) == 1,
    createdAt: map['created_at'] as int,
  );

  /// Map untuk insert/update. `id` diikutkan hanya kalau non-null (biarkan
  /// AUTOINCREMENT bekerja saat insert baru).
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'exercise_type': exerciseType,
    'sets': sets,
    'work_seconds': workSeconds,
    'rest_seconds': restSeconds,
    'warmup_seconds': warmupSeconds,
    'cooldown_seconds': cooldownSeconds,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt,
  };

  WorkoutTemplate copyWith({
    int? id,
    String? name,
    String? exerciseType,
    int? sets,
    int? workSeconds,
    int? restSeconds,
    int? warmupSeconds,
    int? cooldownSeconds,
    bool? isDefault,
    int? createdAt,
  }) => WorkoutTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    exerciseType: exerciseType ?? this.exerciseType,
    sets: sets ?? this.sets,
    workSeconds: workSeconds ?? this.workSeconds,
    restSeconds: restSeconds ?? this.restSeconds,
    warmupSeconds: warmupSeconds ?? this.warmupSeconds,
    cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
  );
}
