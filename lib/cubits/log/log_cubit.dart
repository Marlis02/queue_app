import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogEntry extends Equatable {
  LogEntry(this.message) : time = DateTime.now();

  final DateTime time;
  final String message;

  String get timeLabel =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';

  @override
  List<Object> get props => [time, message];
}

/// Журнал событий приложения (сеть, данные, озвучка) для модалки «Логи».
/// Держит последние [_maxEntries] записей, новые — в начале списка.
class LogCubit extends Cubit<List<LogEntry>> {
  LogCubit() : super(const []);

  static const _maxEntries = 200;

  void add(String message) {
    if (isClosed) return;
    final next = [LogEntry(message), ...state];
    emit(next.length > _maxEntries ? next.sublist(0, _maxEntries) : next);
  }

  void clear() => emit(const []);
}
