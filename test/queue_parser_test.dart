import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:queue_app/services/queue_parser.dart';

void main() {
  group('QueueParser', () {
    test('парсит валидный payload', () {
      const raw = '{"queues":{"cooking":[{"id":1,"time":"12.07.2026 10:00",'
          '"info":"A","counter":"5"}],"done":[{"id":2,"time":"12.07.2026 10:01",'
          '"info":"B","counter":"7","selected":true}]}}';
      final queues = QueueParser.parse(raw);
      expect(queues.cooking, hasLength(1));
      expect(queues.cooking.first.counter, '5');
      expect(queues.done, hasLength(1));
      expect(queues.done.first.selected, isTrue);
    });

    test('чинит кириллицу, прочитанную как latin1-байты (HTTP/UDP путь)', () {
      const original = '{"queues":{"cooking":[{"id":1,"time":"t",'
          '"info":"Плов","counter":"5"}],"done":[]}}';
      // Как читают сервисы: байты → String.fromCharCodes.
      final wire = String.fromCharCodes(utf8.encode(original));
      final queues = QueueParser.parse(wire);
      expect(queues.cooking.first.info, 'Плов');
    });

    test('обычная Dart-строка с кириллицей тоже работает', () {
      const raw = '{"queues":{"cooking":[],"done":[{"id":1,"time":"t",'
          '"info":"Самса","counter":"3","selected":false}]}}';
      final queues = QueueParser.parse(raw);
      expect(queues.done.first.info, 'Самса');
    });

    test('битый JSON бросает (обрабатывается в QueueCubit → 400/QueueError)', () {
      expect(() => QueueParser.parse('не json'), throwsA(anything));
    });

    test('кривые поля не роняют парсинг (null-безопасная модель)', () {
      const raw = '{"queues":{"cooking":[{"id":"7","counter":12}],'
          '"done":[{"id":null}]}}';
      final queues = QueueParser.parse(raw);
      expect(queues.cooking.first.id, 7); // строка → int
      expect(queues.cooking.first.counter, '12'); // число → строка
      expect(queues.done.first.selected, isFalse);
    });

    test('отсутствующие списки → пустые', () {
      final queues = QueueParser.parse('{"queues":{}}');
      expect(queues.cooking, isEmpty);
      expect(queues.done, isEmpty);
    });
  });
}
