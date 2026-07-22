import 'package:flutter/foundation.dart';

/// Riwayat satu sesi latihan. Snapshot nama & jenis disimpan supaya riwayat
/// tetap utuh walau template asalnya diedit/dihapus (template_id nullable,
/// FK ON DELETE SET NULL).
@immutable
class WorkoutSession {
  final int? id; // null sebelum insert
  final int? templateId; // nullable
  final String templateName; // snapshot
  final String exerciseType; // snapshot
  final int startedAt; // epoch ms
  final int durationSeconds; // waktu aktif, exclude pause
  final int setsPlanned;
  final int setsCompleted;
  final bool completed; // true = full, false = stopped di tengah

  const WorkoutSession({
    this.id,
    this.templateId,
    required this.templateName,
    required this.exerciseType,
    required this.startedAt,
    required this.durationSeconds,
    required this.setsPlanned,
    required this.setsCompleted,
    this.completed = false,
  });

  factory WorkoutSession.fromMap(Map<String, Object?> map) => WorkoutSession(
    id: map['id'] as int?,
    templateId: map['template_id'] as int?,
    templateName: map['template_name'] as String,
    exerciseType: map['exercise_type'] as String,
    startedAt: map['started_at'] as int,
    durationSeconds: map['duration_seconds'] as int,
    setsPlanned: map['sets_planned'] as int,
    setsCompleted: map['sets_completed'] as int,
    completed: (map['completed'] as int) == 1,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'template_id': templateId,
    'template_name': templateName,
    'exercise_type': exerciseType,
    'started_at': startedAt,
    'duration_seconds': durationSeconds,
    'sets_planned': setsPlanned,
    'sets_completed': setsCompleted,
    'completed': completed ? 1 : 0,
  };

  WorkoutSession copyWith({
    int? id,
    int? templateId,
    String? templateName,
    String? exerciseType,
    int? startedAt,
    int? durationSeconds,
    int? setsPlanned,
    int? setsCompleted,
    bool? completed,
  }) => WorkoutSession(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    templateName: templateName ?? this.templateName,
    exerciseType: exerciseType ?? this.exerciseType,
    startedAt: startedAt ?? this.startedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    setsPlanned: setsPlanned ?? this.setsPlanned,
    setsCompleted: setsCompleted ?? this.setsCompleted,
    completed: completed ?? this.completed,
  );
}
