import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Последовательное проигрывание озвучки: клипы не накладываются друг на друга.
class AudioService {
  AudioPlayer? _player;
  final Queue<String> _pending = Queue<String>();
  StreamSubscription<void>? _completeSub;
  bool _playing = false;

  /// Пауза между клипами для разборчивости.
  static const _gap = Duration(milliseconds: 150);

  /// Уведомление о смене статуса (для AudioCubit).
  void Function(bool playing, int pending)? onStatus;

  /// Плеер создаётся лениво — при первом реальном воспроизведении.
  AudioPlayer get _ensurePlayer {
    if (_player == null) {
      _player = AudioPlayer();
      _completeSub =
          _player!.onPlayerComplete.listen((_) => _onClipComplete());
    }
    return _player!;
  }

  void enqueue(List<String> assets) {
    if (assets.isEmpty) return;
    _pending.addAll(assets);
    if (!_playing) _playNext();
  }

  Future<void> _playNext() async {
    if (_pending.isEmpty) {
      _playing = false;
      onStatus?.call(false, 0);
      return;
    }
    _playing = true;
    final asset = _pending.removeFirst();
    onStatus?.call(true, _pending.length);
    try {
      await _ensurePlayer.play(AssetSource(asset));
      // Продолжение — по событию onPlayerComplete (см. _onClipComplete).
    } catch (e) {
      debugPrint('Ошибка воспроизведения $asset: $e');
      _playNext(); // не застреваем на битом/отсутствующем файле
    }
  }

  Future<void> _onClipComplete() async {
    await Future.delayed(_gap);
    _playNext();
  }

  Future<void> stop() async {
    _pending.clear();
    _playing = false;
    onStatus?.call(false, 0);
    await _player?.stop();
  }

  Future<void> dispose() async {
    await _completeSub?.cancel();
    _pending.clear();
    await _player?.dispose();
    _player = null;
  }
}
