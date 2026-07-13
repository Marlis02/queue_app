import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/core/audio_assets.dart';
import 'package:queue_app/cubits/audio/audio_state.dart';
import 'package:queue_app/models/model.dart';
import 'package:queue_app/services/audio_service.dart';

/// Озвучка готовых заказов.
class AudioCubit extends Cubit<AudioState> {
  AudioCubit(this._audioService, {this.log}) : super(const AudioState()) {
    _audioService.onStatus = (playing, pending) {
      if (!isClosed) {
        emit(AudioState(playing: playing, queuedCount: pending));
      }
    };
  }

  final AudioService _audioService;

  /// Журнал событий (модалка «Логи»).
  final void Function(String message)? log;

  /// Уже озвученные заказы (id). Reset-семантика: множество заменяется
  /// текущим набором selected, поэтому заказ, снятый и снова отмеченный
  /// selected, будет озвучен повторно (повторный вызов клиента).
  Set<int> _announcedIds = {};

  /// Озвучить все новые selected-заказы из колонки «Готовы».
  /// На первом снимке _announcedIds пуст → озвучиваются все текущие selected.
  void announceSelected(List<QueueDone> done) {
    final currentSelectedIds =
        done.where((d) => d.selected).map((d) => d.id).toSet();
    final newlySelected = currentSelectedIds.difference(_announcedIds);
    _announcedIds = currentSelectedIds;
    if (newlySelected.isEmpty) return;

    final toAnnounce =
        done.where((d) => d.selected && newlySelected.contains(d.id)).toList();
    final assets = toAnnounce
        .map((d) => assetForCounter(d.counter))
        .whereType<String>()
        .toList();
    if (toAnnounce.isNotEmpty) {
      log?.call('Озвучка: №${toAnnounce.map((d) => d.counter).join(', №')}');
    }
    _audioService.enqueue(assets);
  }

  @override
  Future<void> close() async {
    await _audioService.dispose();
    return super.close();
  }
}
