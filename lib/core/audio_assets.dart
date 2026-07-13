/// Маппинг номера заказа (`counter`) в файл озвучки.
///
/// В assets/audio/ лежат файлы 01.mp3–100.mp3
/// (01–09 — с ведущим нулём, 100 — трёхзначный).
String? assetForCounter(String counter) {
  final n = int.tryParse(counter.trim());
  if (n == null || n < 1 || n > 100) return null; // не число / вне диапазона → пропуск
  final name = n.toString().padLeft(2, '0'); // 5 → "05", 42 → "42", 100 → "100"
  return 'audio/$name.mp3'; // путь AssetSource — относительно assets/
}
