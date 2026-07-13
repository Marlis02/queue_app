import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.fontSize = 1.0,
    this.isReverse = false,
    this.keepScreenAwake = false,
  });

  final double fontSize;
  final bool isReverse;

  /// Не давать экрану гаснуть, пока приложение на переднем плане.
  final bool keepScreenAwake;

  SettingsState copyWith({
    double? fontSize,
    bool? isReverse,
    bool? keepScreenAwake,
  }) {
    return SettingsState(
      fontSize: fontSize ?? this.fontSize,
      isReverse: isReverse ?? this.isReverse,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    );
  }

  @override
  List<Object> get props => [fontSize, isReverse, keepScreenAwake];
}
