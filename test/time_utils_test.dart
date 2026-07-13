import 'package:flutter_test/flutter_test.dart';
import 'package:queue_app/core/time_utils.dart';

void main() {
  group('parseBackendTime', () {
    test('парсит основной формат dd.MM.yyyy HH:mm', () {
      final dt = parseBackendTime('12.07.2026 10:30');
      expect(dt, DateTime(2026, 7, 12, 10, 30));
    });

    test('парсит формат с секундами', () {
      final dt = parseBackendTime('12.07.2026 10:30:45');
      expect(dt, DateTime(2026, 7, 12, 10, 30, 45));
    });

    test('парсит ISO-8601 с T', () {
      final dt = parseBackendTime('2026-07-12T10:30:00');
      expect(dt, DateTime(2026, 7, 12, 10, 30));
    });

    test('парсит yyyy-MM-dd HH:mm:ss', () {
      final dt = parseBackendTime('2026-07-12 10:30:00');
      expect(dt, DateTime(2026, 7, 12, 10, 30));
    });

    test('парсит формат со слэшами', () {
      final dt = parseBackendTime('12/07/2026 10:30');
      expect(dt, DateTime(2026, 7, 12, 10, 30));
    });

    test('парсит epoch в секундах и миллисекундах', () {
      final seconds = parseBackendTime('1783925400'); // 10 цифр → секунды
      expect(seconds,
          DateTime.fromMillisecondsSinceEpoch(1783925400 * 1000));
      final millis = parseBackendTime('1783925400000'); // 13 цифр → миллисекунды
      expect(millis, DateTime.fromMillisecondsSinceEpoch(1783925400000));
    });

    test('мусор и пустые строки → null, без исключений', () {
      expect(parseBackendTime('abc'), isNull);
      expect(parseBackendTime(''), isNull);
      expect(parseBackendTime('   '), isNull);
      expect(parseBackendTime('99.99.9999 99:99'), isNull);
      expect(parseBackendTime('12.07.2026'), isNull); // без времени
    });
  });

  group('getTimeDifference', () {
    test('прошедшее время → минуты', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      final raw = '${past.day.toString().padLeft(2, '0')}.'
          '${past.month.toString().padLeft(2, '0')}.${past.year} '
          '${past.hour.toString().padLeft(2, '0')}:'
          '${past.minute.toString().padLeft(2, '0')}';
      expect(getTimeDifference(raw), anyOf('4мин', '5мин'));
    });

    test('нераспознанный формат → пустая строка (не белый экран)', () {
      expect(getTimeDifference('это не дата'), '');
    });

    test('будущее время → 0мин, не отрицательное', () {
      final future = DateTime.now().add(const Duration(minutes: 10));
      final raw = '${future.day.toString().padLeft(2, '0')}.'
          '${future.month.toString().padLeft(2, '0')}.${future.year} '
          '${future.hour.toString().padLeft(2, '0')}:'
          '${future.minute.toString().padLeft(2, '0')}';
      expect(getTimeDifference(raw), '0мин');
    });
  });
}
