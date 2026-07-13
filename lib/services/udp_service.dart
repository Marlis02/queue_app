import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:queue_app/core/constants.dart';

/// UDP-канал табло: ответчик обнаружения + приём данных очереди.
///
/// Протокол (текстовые датаграммы):
///  - `QUEUE_DISCOVER_V1` (broadcast от POS) → отвечаем отправителю
///    `QUEUE_ANNOUNCE_V1 {"ip":...,"httpPort":8088,"udpPort":8088,...}`;
///  - `QUEUE_DATA_V1 {"queues":{...}}` → те же данные, что HTTP POST.
/// Большие payload должны идти по HTTP: датаграммы крупнее ~1500 байт
/// фрагментируются и теряются.
class UdpService {
  UdpService({
    required this.onData,
    required this.ipProvider,
    this.onError,
    this.onRunningChanged,
    this.onDiscovery,
  });

  final bool Function(String rawJson) onData;
  final Future<String?> Function() ipProvider;
  final void Function(String message)? onError;
  final void Function(bool running)? onRunningChanged;
  final void Function(String from)? onDiscovery;

  RawDatagramSocket? _socket;
  Timer? _beaconTimer;
  bool _stopped = false;

  Future<void> start() async {
    _stopped = false;
    var attempt = 0;
    while (!_stopped) {
      try {
        final socket = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4, AppConstants.udpPort);
        _socket = socket;
        socket.broadcastEnabled = true;
        attempt = 0;
        debugPrint('UDP-сокет запущен на порту ${AppConstants.udpPort}');
        onRunningChanged?.call(true);

        if (AppConstants.enableBeacon) {
          _beaconTimer = Timer.periodic(
              AppConstants.beaconInterval, (_) => _broadcastAnnounce());
        }
        final done = Completer<void>();
        socket.listen(
          (event) {
            if (event == RawSocketEvent.read) {
              final datagram = socket.receive();
              if (datagram != null) _handleDatagram(socket, datagram);
            }
          },
          onError: (Object e) {
            onError?.call('Ошибка UDP-сокета: $e');
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
        );
        await done.future;
        _beaconTimer?.cancel();
        onRunningChanged?.call(false);
      } catch (e) {
        onRunningChanged?.call(false);
        if (_stopped) break;
        debugPrint('Ошибка при запуске UDP-сокета: $e');
        onError?.call('Ошибка при запуске UDP-сокета: $e');
        final delay = Duration(
          seconds: math.min(
              AppConstants.maxBindBackoff.inSeconds, 1 << math.min(attempt, 5)),
        );
        attempt++;
        await Future.delayed(delay);
      }
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _beaconTimer?.cancel();
    _socket?.close();
    _socket = null;
  }

  void _handleDatagram(RawDatagramSocket socket, Datagram datagram) {
    if (datagram.data.length > AppConstants.udpSizeWarnBytes) {
      debugPrint('UDP: датаграмма ${datagram.data.length} байт — крупные '
          'payload могут теряться, используйте HTTP');
    }
    final text = String.fromCharCodes(datagram.data).trim();

    if (text.startsWith(AppConstants.udpDiscoverPrefix)) {
      onDiscovery?.call('${datagram.address.address}:${datagram.port}');
      _sendAnnounce(socket, datagram.address, datagram.port);
    } else if (text.startsWith(AppConstants.udpDataPrefix)) {
      final rawJson = text.substring(AppConstants.udpDataPrefix.length).trim();
      onData(rawJson);
    } else {
      debugPrint('UDP: неизвестная датаграмма от ${datagram.address.address}');
    }
  }

  Future<void> _sendAnnounce(
      RawDatagramSocket socket, InternetAddress to, int port) async {
    final message = await _announceMessage();
    try {
      socket.send(utf8.encode(message), to, port);
      debugPrint('UDP: ответ обнаружения → ${to.address}:$port');
    } catch (e) {
      debugPrint('UDP: не удалось отправить ответ обнаружения: $e');
    }
  }

  Future<void> _broadcastAnnounce() async {
    final socket = _socket;
    if (socket == null) return;
    final message = await _announceMessage();
    try {
      socket.send(utf8.encode(message), InternetAddress('255.255.255.255'),
          AppConstants.udpPort);
    } catch (e) {
      debugPrint('UDP: не удалось отправить beacon: $e');
    }
  }

  Future<String> _announceMessage() async {
    String? ip;
    try {
      ip = await ipProvider();
    } catch (_) {}
    final payload = jsonEncode({
      'ip': ip ?? '',
      'httpPort': AppConstants.httpPort,
      'udpPort': AppConstants.udpPort,
      'name': AppConstants.appName,
      'app': 'queue_app',
      'v': 1,
    });
    return '${AppConstants.udpAnnouncePrefix} $payload';
  }
}
