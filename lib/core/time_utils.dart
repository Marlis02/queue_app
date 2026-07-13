import 'package:intl/intl.dart';

/// Известные форматы времени от бэкенда. Специфичные/частые — первыми,
/// `HH:mm:ss` раньше `HH:mm`, чтобы секунды не терялись.
final List<DateFormat> _knownFormats = [
  DateFormat('dd.MM.yyyy HH:mm:ss'),
  DateFormat('dd.MM.yyyy HH:mm'),
  DateFormat('yyyy-MM-dd HH:mm:ss'),
  DateFormat('yyyy-MM-dd HH:mm'),
  DateFormat('dd/MM/yyyy HH:mm:ss'),
  DateFormat('dd/MM/yyyy HH:mm'),
  DateFormat("yyyy-MM-dd'T'HH:mm:ss"),
];

/// Пытается разобрать время в любом известном формате. Никогда не бросает.
DateTime? parseBackendTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  // 1) Чисто числовая строка → epoch: >=12 цифр — миллисекунды, иначе секунды.
  // Проверяется ДО ISO: DateTime.tryParse «съедает» строку из цифр как дату.
  final numeric = int.tryParse(value);
  if (numeric != null) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.length >= 12 ? numeric : numeric * 1000,
    );
  }

  // 2) ISO-8601 (включая 'T', таймзоны, доли секунд).
  final iso = DateTime.tryParse(value);
  if (iso != null) return iso.toLocal();

  // 3) Перебор известных форматов; parseStrict, чтобы не «проглатывать» мусор.
  for (final format in _knownFormats) {
    try {
      return format.parseStrict(value);
    } catch (_) {
      // не подошёл — пробуем следующий
    }
  }
  return null;
}

/// Разница в минутах от времени заказа до текущего момента.
/// Не распарсилось → пустая строка (строка заказа всё равно отображается).
String getTimeDifference(String timeFromBackend) {
  final parsed = parseBackendTime(timeFromBackend);
  if (parsed == null) return '';
  final minutes = DateTime.now().difference(parsed).inMinutes;
  return '${minutes < 0 ? 0 : minutes}мин'; // защита от рассинхрона часов
}
