import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:queue_app/core/constants.dart';

/// HTTP-сервер, принимающий данные очереди от POS (порт 8088, как раньше).
///
/// Не парсит данные сам — отдаёт сырой JSON через [onData];
/// по возвращённому bool отвечает 200/400 (сохраняет старый контракт).
class HttpServerService {
  HttpServerService({
    required this.onData,
    this.onError,
    this.onRunningChanged,
  });

  /// Сырой JSON из тела POST. Возвращает true, если данные приняты.
  final bool Function(String rawJson) onData;
  final void Function(String message)? onError;
  final void Function(bool running)? onRunningChanged;

  HttpServer? _server;
  bool _stopped = false;

  Future<void> start() async {
    _stopped = false;
    var attempt = 0;
    while (!_stopped) {
      try {
        _server = await HttpServer.bind(
            InternetAddress.anyIPv4, AppConstants.httpPort);
        attempt = 0;
        debugPrint('HTTP-сервер запущен на порту ${AppConstants.httpPort}');
        onRunningChanged?.call(true);
        await for (final request in _server!) {
          try {
            _handleRequest(request);
          } catch (e) {
            debugPrint('Ошибка обработки запроса: $e');
            _respond(request, HttpStatus.internalServerError,
                '500 - Ошибка обработки запроса');
          }
        }
        onRunningChanged?.call(false);
      } catch (e) {
        onRunningChanged?.call(false);
        if (_stopped) break;
        debugPrint('Ошибка при запуске HTTP-сервера: $e');
        onError?.call('Ошибка при запуске HTTP-сервера: $e');
        // Экспоненциальный backoff вместо мгновенного повтора (без спина CPU).
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
    await _server?.close(force: true);
    _server = null;
  }

  void _handleRequest(HttpRequest request) {
    final method = request.method;
    final path = request.uri.path;

    if (method == 'GET' && path == '/') {
      request.response.headers.contentType = ContentType.html;
      _respond(request, HttpStatus.ok,
          '<h1 >Добро пожаловать на мой сервер!  ⭐⭐⭐</h1>');
    } else if (method == 'POST' && path == '/') {
      _handlePost(request);
    } else {
      _respond(request, HttpStatus.notFound, '404 - Не найдено');
    }
  }

  Future<void> _handlePost(HttpRequest request) async {
    final buffer = StringBuffer();
    try {
      // Читаем байты как code units (latin1-стиль) — перекодирование
      // в UTF-8 делает QueueParser, единый для HTTP и UDP.
      await for (final data in request) {
        buffer.write(String.fromCharCodes(data));
      }
      final accepted = onData(buffer.toString());
      if (accepted) {
        _respond(request, HttpStatus.ok, 'Success');
      } else {
        _respond(
            request, HttpStatus.badRequest, '400 - Ошибка обработки данных');
      }
    } catch (e) {
      debugPrint('Ошибка при обработке POST-запроса: $e');
      onError?.call('Ошибка при обработке POST-запроса: $e');
      _respond(request, HttpStatus.badRequest, '400 - Ошибка обработки данных');
    }
  }

  void _respond(HttpRequest request, int status, String body) {
    try {
      request.response
        ..statusCode = status
        ..write(body)
        ..close();
    } catch (_) {
      // соединение уже закрыто — игнорируем
    }
  }
}
