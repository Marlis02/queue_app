// Null-безопасные fromJson: UDP — второй, непроверенный вход,
// кривая датаграмма не должна ронять парсинг.

class Queues {
  final List<Queue> cooking;
  final List<QueueDone> done;

  Queues({
    this.cooking = const [],
    this.done = const [],
  });

  factory Queues.fromJson(Map<String, dynamic> json) {
    return Queues(
      cooking: (json['cooking'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Queue.fromJson)
          .toList(),
      done: (json['done'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QueueDone.fromJson)
          .toList(),
    );
  }
}

class Queue {
  final int id;
  final String time;
  final String info;
  final String counter;

  Queue({
    required this.id,
    required this.time,
    required this.info,
    required this.counter,
  });

  factory Queue.fromJson(Map<String, dynamic> json) {
    return Queue(
      id: int.tryParse('${json['id']}') ?? 0,
      time: '${json['time'] ?? ''}',
      info: '${json['info'] ?? ''}',
      counter: '${json['counter'] ?? ''}',
    );
  }
}

class QueueDone {
  final int id;
  final String time;
  final String info;
  final String counter;
  final bool selected;

  QueueDone({
    required this.id,
    required this.time,
    required this.info,
    required this.counter,
    required this.selected,
  });

  factory QueueDone.fromJson(Map<String, dynamic> json) {
    return QueueDone(
      id: int.tryParse('${json['id']}') ?? 0,
      time: '${json['time'] ?? ''}',
      info: '${json['info'] ?? ''}',
      counter: '${json['counter'] ?? ''}',
      selected: json['selected'] == true,
    );
  }
}
