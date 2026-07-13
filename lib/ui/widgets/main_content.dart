import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/core/time_utils.dart';
import 'package:queue_app/cubits/settings/settings_cubit.dart';
import 'package:queue_app/models/model.dart';

class MainContent extends StatefulWidget {
  final List<Queue> cooking;
  final List<QueueDone> done;

  const MainContent({
    super.key,
    required this.cooking,
    required this.done,
  });

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent>
    with SingleTickerProviderStateMixin {
  static const _baseColor = Color.fromARGB(255, 255, 241, 241);
  static const _highlightColor = Color.fromARGB(255, 120, 220, 140);

  late final AnimationController _blinkController;
  late final Animation<Color?> _blinkColor;
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    // Плавная мягкая пульсация: длиннее и с кривой easeInOut,
    // чтобы не «дёргалось» на разворотах.
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _blinkColor = ColorTween(begin: _baseColor, end: _highlightColor).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _syncBlinking();
    // Метки «N мин» освежаются раз в минуту — дешёвый одиночный ребилд
    // видимых строк вместо прежнего перестроения всего экрана каждую секунду.
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(MainContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBlinking();
  }

  /// Мигание работает только когда есть что мигать.
  void _syncBlinking() {
    final hasSelected = widget.done.any((d) => d.selected);
    if (hasSelected && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (!hasSelected && _blinkController.isAnimating) {
      _blinkController.stop();
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = context.select((SettingsCubit c) => c.state.fontSize);
    final isReverse = context.select((SettingsCubit c) => c.state.isReverse);
    // Реверс меняет только порядок строк; списки всегда прижаты к верху
    // (reverse: у ListView не используем — он переносит якорь вниз).
    final cookingItems =
        isReverse ? widget.cooking.reversed.toList() : widget.cooking;
    final doneItems = isReverse ? widget.done.reversed.toList() : widget.done;
    return Container(
      color: _baseColor,
      width: size.width,
      height: size.height,
      margin: EdgeInsets.only(
        top: 70 * fontSize,
        bottom: 60 * fontSize,
        left: 15,
        right: 15,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // Ленивый список: строятся только видимые строки.
            child: ListView.builder(
              itemCount: cookingItems.length,
              itemBuilder: (context, index) {
                final item = cookingItems[index];
                return QueueRow(
                  time: item.time,
                  info: item.info,
                  counter: item.counter,
                );
              },
            ),
          ),
          Container(
            width: 1,
            height: size.height,
            color: Colors.black,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: doneItems.length,
              itemBuilder: (context, index) {
                final item = doneItems[index];
                final row = QueueRow(
                  time: item.time,
                  info: item.info,
                  counter: item.counter,
                );
                if (!item.selected) return row;
                // Мигает только фон selected-ячейки; сама строка (child)
                // не перестраивается на каждый тик анимации.
                return AnimatedBuilder(
                  animation: _blinkColor,
                  builder: (context, child) => ColoredBox(
                    color: _blinkColor.value ?? _baseColor,
                    child: child,
                  ),
                  child: row,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка заказа: время ожидания, инфо, номер.
class QueueRow extends StatelessWidget {
  const QueueRow({
    super.key,
    required this.time,
    required this.info,
    required this.counter,
  });

  final String time;
  final String info;
  final String counter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: Colors.orange),
        ),
      ),
      child: Row(
        children: [
          Text(
            getTimeDifference(time),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          Text(
            info,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            counter,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
        ],
      ),
    );
  }
}
