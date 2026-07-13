import 'dart:convert';

import 'package:queue_app/models/model.dart';

/// Единый путь разбора JSON для HTTP и UDP — идентичное поведение
/// и одинаковый фикс кириллицы на обоих каналах.
class QueueParser {
  QueueParser._();

  static Queues parse(String rawJson) {
    final map = jsonDecode(_fixEncoding(rawJson)) as Map<String, dynamic>;
    return Queues.fromJson(map['queues'] as Map<String, dynamic>? ?? const {});
  }

  /// Тело HTTP/UDP читается как Latin-1 (String.fromCharCodes по байтам),
  /// поэтому перекодируем обратно в байты и декодируем как UTF-8 —
  /// иначе кириллица превращается в mojibake.
  static String _fixEncoding(String raw) {
    try {
      return utf8.decode(latin1.encode(raw), allowMalformed: true);
    } on ArgumentError {
      return raw; // уже нормальная строка (не latin1-байты)
    }
  }
}
