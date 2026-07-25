import 'package:flutter/foundation.dart';

@immutable
class HealthData {
  final int? id;
  final HealthRecordType type;
  final double value;
  final String unit;
  final int startTime;
  final int endTime;
  final int syncedAt;
  final String source;

  const HealthData({
    this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.startTime,
    required this.endTime,
    required this.syncedAt,
    this.source = 'Health Connect',
  });

  factory HealthData.fromMap(Map<String, Object?> map) => HealthData(
        id: map['id'] as int?,
        type: HealthRecordType.values.firstWhere(
          (e) => e.name == (map['record_type'] as String),
          orElse: () => HealthRecordType.steps,
        ),
        value: (map['value'] as num?)?.toDouble() ?? 0.0,
        unit: map['unit'] as String? ?? '',
        startTime: map['start_time'] as int? ?? 0,
        endTime: map['end_time'] as int? ?? 0,
        syncedAt: map['synced_at'] as int? ?? 0,
        source: map['source'] as String? ?? 'Health Connect',
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'record_type': type.name,
        'value': value,
        'unit': unit,
        'start_time': startTime,
        'end_time': endTime,
        'synced_at': syncedAt,
        'source': source,
      };
}

enum HealthRecordType {
  steps,
  heartRate,
  activeEnergyBurned,
}

extension HealthRecordTypeX on HealthRecordType {
  String get label => switch (this) {
        HealthRecordType.steps => 'Steps',
        HealthRecordType.heartRate => 'Heart Rate',
        HealthRecordType.activeEnergyBurned => 'Calories',
      };
  String get unit => switch (this) {
        HealthRecordType.steps => 'steps',
        HealthRecordType.heartRate => 'bpm',
        HealthRecordType.activeEnergyBurned => 'kcal',
      };
}
