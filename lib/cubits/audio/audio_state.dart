import 'package:equatable/equatable.dart';

class AudioState extends Equatable {
  const AudioState({this.playing = false, this.queuedCount = 0});

  final bool playing;
  final int queuedCount;

  @override
  List<Object> get props => [playing, queuedCount];
}
