import 'package:flutter_test/flutter_test.dart';
import 'package:queue_app/core/audio_assets.dart';

void main() {
  group('assetForCounter', () {
    test('однозначные номера дополняются нулём', () {
      expect(assetForCounter('5'), 'audio/05.mp3');
      expect(assetForCounter('1'), 'audio/01.mp3');
      expect(assetForCounter('9'), 'audio/09.mp3');
    });

    test('двузначные номера как есть', () {
      expect(assetForCounter('10'), 'audio/10.mp3');
      expect(assetForCounter('42'), 'audio/42.mp3');
      expect(assetForCounter('99'), 'audio/99.mp3');
    });

    test('100 — трёхзначный', () {
      expect(assetForCounter('100'), 'audio/100.mp3');
    });

    test('пробелы и ведущий ноль обрезаются корректно', () {
      expect(assetForCounter(' 7 '), 'audio/07.mp3');
      expect(assetForCounter('05'), 'audio/05.mp3');
    });

    test('вне диапазона / не число → null (пропуск без падения)', () {
      expect(assetForCounter('0'), isNull);
      expect(assetForCounter('101'), isNull);
      expect(assetForCounter('250'), isNull);
      expect(assetForCounter('-3'), isNull);
      expect(assetForCounter('abc'), isNull);
      expect(assetForCounter(''), isNull);
    });
  });
}
