import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Service responsible for keeping the screen awake while reading.
class ScreenWakeService {
  bool _isAwake = false;

  /// Whether the screen wake lock is currently active.
  bool get isAwake => _isAwake;

  /// Enables the wake lock to prevent the screen from turning off.
  Future<void> enable() async {
    _isAwake = true;
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('ScreenWakeService.enable error: $e');
    }
  }

  /// Disables the wake lock to allow the screen to sleep normally.
  Future<void> disable() async {
    _isAwake = false;
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('ScreenWakeService.disable error: $e');
    }
  }

  /// Sets the screen wake lock state based on [awake].
  Future<void> setAwake(bool awake) async {
    if (awake) {
      await enable();
    } else {
      await disable();
    }
  }
}
