import 'package:equatable/equatable.dart';
import 'package:queue_app/models/model.dart';

sealed class QueueState extends Equatable {
  const QueueState();

  /// Последние успешно принятые данные (если были).
  Queues? get queuesOrNull => switch (this) {
        QueueLoaded(:final queues) => queues,
        QueueError(:final lastQueues) => lastQueues,
        QueueInitial() => null,
      };

  @override
  List<Object?> get props => [];
}

/// Данных ещё не было — показываем индикатор ожидания.
class QueueInitial extends QueueState {
  const QueueInitial();
}

class QueueLoaded extends QueueState {
  const QueueLoaded(this.queues);

  final Queues queues;

  @override
  List<Object?> get props => [queues];
}

/// Ошибка разбора: держим последние хорошие данные, ошибку — в настройки.
class QueueError extends QueueState {
  const QueueError(this.message, {this.lastQueues});

  final String message;
  final Queues? lastQueues;

  @override
  List<Object?> get props => [message, lastQueues];
}
