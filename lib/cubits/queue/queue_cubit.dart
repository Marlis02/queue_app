import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/queue/queue_state.dart';
import 'package:queue_app/services/queue_parser.dart';

/// Данные очереди. Единая точка входа для HTTP и UDP.
class QueueCubit extends Cubit<QueueState> {
  QueueCubit({this.log}) : super(const QueueInitial());

  /// Журнал событий (модалка «Логи»).
  final void Function(String message)? log;

  /// Возвращает true, если payload принят (для ответа 200/400 по HTTP).
  /// Всегда применяем последний полученный пакет — без отбрасывания.
  bool onPayloadReceived(String rawJson, {required String source}) {
    if (isClosed) return false;
    try {
      final queues = QueueParser.parse(rawJson);
      emit(QueueLoaded(queues));
      log?.call('Данные ($source): готовятся '
          '${queues.cooking.length}, готовы ${queues.done.length}');
      return true;
    } catch (e) {
      debugPrint('Ошибка при обработке данных ($source): $e');
      log?.call('Ошибка данных ($source): $e');
      emit(QueueError(
        'Ошибка при обработке данных ($source): $e',
        lastQueues: state.queuesOrNull,
      ));
      return false;
    }
  }
}
