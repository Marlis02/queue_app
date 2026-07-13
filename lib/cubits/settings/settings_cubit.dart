import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/settings/settings_state.dart';
import 'package:queue_app/services/settings_repository.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Настройки табло: размер шрифта, реверс списков, wake-lock.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> loadSettings() async {
    final fontSize = await _repository.getFontSize();
    final isReverse = await _repository.getIsReverse();
    final keepScreenAwake = await _repository.getKeepScreenAwake();
    emit(state.copyWith(
      fontSize: fontSize,
      isReverse: isReverse,
      keepScreenAwake: keepScreenAwake,
    ));
    await _applyWakelock(keepScreenAwake);
  }

  Future<void> setFontSize(double value) async {
    emit(state.copyWith(fontSize: value));
    await _repository.setFontSize(value);
  }

  Future<void> toggleReverse() async {
    final value = !state.isReverse;
    emit(state.copyWith(isReverse: value));
    await _repository.setIsReverse(value);
  }

  Future<void> setKeepScreenAwake(bool value) async {
    emit(state.copyWith(keepScreenAwake: value));
    await _applyWakelock(value);
    await _repository.setKeepScreenAwake(value);
  }

  /// Повторно применить wake-lock (после возврата приложения на передний план).
  Future<void> reapplyWakelock() => _applyWakelock(state.keepScreenAwake);

  /// Отпустить wake-lock (при сворачивании приложения).
  Future<void> releaseWakelock() => _applyWakelock(false);

  Future<void> _applyWakelock(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } catch (e) {
      // Платформа без поддержки (тесты/редкие десктопы) — не критично.
      debugPrint('Wakelock недоступен: $e');
    }
  }
}
