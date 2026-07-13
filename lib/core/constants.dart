/// Сетевые константы и протокол обнаружения.
class AppConstants {
  AppConstants._();

  /// Порт HTTP-сервера, на который POS шлёт данные очереди.
  static const int httpPort = 8088;

  /// Порт UDP: обнаружение (discovery) + приём данных.
  /// Тот же номер, что HTTP — TCP-8088 и UDP-8088 не конфликтуют
  /// (разные протоколы), одно число проще запомнить.
  static const int udpPort = 8088;

  /// Запрос обнаружения от POS (broadcast на 255.255.255.255:8088).
  static const String udpDiscoverPrefix = 'QUEUE_DISCOVER_V1';

  /// Ответ табло со своим адресом.
  static const String udpAnnouncePrefix = 'QUEUE_ANNOUNCE_V1';

  /// Префикс датаграммы с данными очереди (далее тот же JSON, что и HTTP POST).
  static const String udpDataPrefix = 'QUEUE_DATA_V1';

  /// Периодический broadcast присутствия (по умолчанию выключен,
  /// чтобы не засорять сеть — POS сам шлёт discovery-запрос).
  static const bool enableBeacon = false;
  static const Duration beaconInterval = Duration(seconds: 10);

  /// Максимальная задержка повторной попытки bind сервера.
  static const Duration maxBindBackoff = Duration(seconds: 30);

  /// Датаграммы крупнее этого размера рискуют фрагментироваться и теряться —
  /// большие payload должны идти по HTTP.
  static const int udpSizeWarnBytes = 1400;

  static const String appName = 'CTmax Queue';
}
