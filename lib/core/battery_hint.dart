import 'package:flutter/services.dart';

void requestBatteryOptimizationExemption() {
  try {
    const MethodChannel('intervalfit/battery').invokeMethod('requestBattery');
  } catch (_) {}
}
