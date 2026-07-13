import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/network/network_state.dart';
import 'package:queue_app/cubits/queue/queue_cubit.dart';
import 'package:queue_app/services/http_server_service.dart';
import 'package:queue_app/services/network_info_service.dart';
import 'package:queue_app/services/udp_service.dart';

/// Жизненный цикл серверов (HTTP + UDP) и диагностика для настроек.
class NetworkCubit extends Cubit<NetworkState> {
  NetworkCubit({
    required QueueCubit queueCubit,
    NetworkInfoService? networkInfo,
    this.log,
  })  : _networkInfo = networkInfo ?? NetworkInfoService(),
        super(const NetworkState()) {
    _http = HttpServerService(
      onData: (raw) => queueCubit.onPayloadReceived(raw, source: 'http'),
      onError: _onError,
      onRunningChanged: (running) {
        log?.call('HTTP-сервер ${running ? 'запущен (порт ${state.httpPort})' : 'остановлен'}');
        _safeEmit(state.copyWith(httpRunning: running, clearError: running));
      },
    );
    _udp = UdpService(
      onData: (raw) => queueCubit.onPayloadReceived(raw, source: 'udp'),
      ipProvider: _networkInfo.getWifiIp,
      onError: _onError,
      onRunningChanged: (running) {
        log?.call('UDP-сокет ${running ? 'запущен (порт ${state.udpPort})' : 'остановлен'}');
        _safeEmit(state.copyWith(udpRunning: running));
      },
      onDiscovery: (from) => log?.call('UDP: обнаружение от $from — ответ отправлен'),
    );
  }

  /// Журнал событий (модалка «Логи»).
  final void Function(String message)? log;

  final NetworkInfoService _networkInfo;
  late final HttpServerService _http;
  late final UdpService _udp;

  Future<void> start() async {
    unawaited(refreshIp());
    unawaited(_http.start());
    unawaited(_udp.start());
  }

  Future<void> refreshIp() async {
    final ip = await _networkInfo.getWifiIp();
    if (ip != null) _safeEmit(state.copyWith(ipAddress: ip));
  }

  void _onError(String message) {
    log?.call(message);
    _safeEmit(state.copyWith(errorMessage: message));
  }

  void _safeEmit(NetworkState newState) {
    if (!isClosed) emit(newState);
  }

  @override
  Future<void> close() async {
    await _http.stop();
    await _udp.stop();
    return super.close();
  }
}
