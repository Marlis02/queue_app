import 'package:shared_preferences/shared_preferences.dart';

/// Хранение настроек в SharedPreferences.
class SettingsRepository {
  static const _kFontSize = 'fontSize';
  static const _kIsReverse = 'isReverse';
  static const _kKeepScreenAwake = 'keepScreenAwake';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<double> getFontSize() async =>
      (await _prefs).getDouble(_kFontSize) ?? 1.0;

  Future<void> setFontSize(double value) async =>
      (await _prefs).setDouble(_kFontSize, value);

  Future<bool> getIsReverse() async =>
      (await _prefs).getBool(_kIsReverse) ?? false;

  Future<void> setIsReverse(bool value) async =>
      (await _prefs).setBool(_kIsReverse, value);

  Future<bool> getKeepScreenAwake() async =>
      (await _prefs).getBool(_kKeepScreenAwake) ?? false; // по умолчанию выкл

  Future<void> setKeepScreenAwake(bool value) async =>
      (await _prefs).setBool(_kKeepScreenAwake, value);
}
