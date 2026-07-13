import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/audio/audio_cubit.dart';
import 'package:queue_app/cubits/queue/queue_cubit.dart';
import 'package:queue_app/cubits/queue/queue_state.dart';
import 'package:queue_app/cubits/settings/settings_cubit.dart';
import 'package:queue_app/models/model.dart';
import 'package:queue_app/ui/modals/settings_modal.dart';
import 'package:queue_app/ui/widgets/current_time.dart';
import 'package:queue_app/ui/widgets/loading.dart';
import 'package:queue_app/ui/widgets/main_content.dart';
import 'package:queue_app/ui/widgets/main_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Wake-lock держим только пока приложение на переднем плане.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsCubit>();
    switch (state) {
      case AppLifecycleState.resumed:
        settings.reapplyWakelock();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        settings.releaseWakelock();
    }
  }

  bool _settingsOpen = false;
  DateTime? _lastOkPress;

  /// Центр/OK пульта — открывает настройки по ДВОЙНОМУ нажатию.
  static final Set<LogicalKeyboardKey> _okKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.gameButtonA,
  };

  /// Интервал, в пределах которого два нажатия считаются двойным кликом.
  static const _doubleClickWindow = Duration(milliseconds: 500);

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // MENU открывает настройки одиночным нажатием.
    if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
      _openSettings();
      return KeyEventResult.handled;
    }

    // Центр/OK — только двойное нажатие в пределах окна.
    if (_okKeys.contains(event.logicalKey)) {
      final now = DateTime.now();
      if (_lastOkPress != null &&
          now.difference(_lastOkPress!) <= _doubleClickWindow) {
        _lastOkPress = null;
        _openSettings();
      } else {
        _lastOkPress = now;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openSettings() {
    if (_settingsOpen) return; // не открывать поверх уже открытых
    _settingsOpen = true;
    settingsInput(context).whenComplete(() => _settingsOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QueueCubit, QueueState>(
      // Озвучиваем готовые заказы при каждом принятом обновлении данных.
      listener: (context, state) {
        if (state is QueueLoaded) {
          context.read<AudioCubit>().announceSelected(state.queues.done);
        }
      },
      // autofocus + фокусируемый верхний Focus: центр/OK пульта ловится
      // на табло всегда (когда диалог не открыт — он берёт фокус себе).
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: BlocBuilder<QueueCubit, QueueState>(
            builder: (context, state) {
              final queues = state.queuesOrNull;
              return queues == null
                  ? const _WaitingView()
                  : _BoardView(queues: queues);
            },
          ),
        ),
      ),
    );
  }
}

/// Данных ещё нет: индикатор ожидания, тап/OK открывает настройки.
class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    final fontSize = context.select((SettingsCubit c) => c.state.fontSize);
    return Container(
      alignment: Alignment.center,
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.all(Colors.transparent),
              // Никакой подсветки/рамки на логотипе-индикаторе,
              // и не навязываем ему стандартную высоту кнопок.
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              side: WidgetStateProperty.all(BorderSide.none),
              fixedSize: WidgetStateProperty.all(null),
              minimumSize: WidgetStateProperty.all(Size.zero),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
            onPressed: () => settingsInput(context),
            child: Loading(
              size: 60 * fontSize,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({required this.queues});

  final Queues queues;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = context.select((SettingsCubit c) => c.state.fontSize);
    return Container(
      color: Colors.black,
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          MainContent(
            cooking: queues.cooking,
            done: queues.done,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 70 * fontSize,
              decoration: const BoxDecoration(color: Colors.black),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Готовятся',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: CurrentTimeWidget(),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Готовы',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.black),
              height: 60 * fontSize,
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 10),
              child: const Text(
                'Очередь заказов',
                style: TextStyle(
                  height: 0,
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60 * fontSize,
              padding: const EdgeInsets.only(bottom: 10, left: 15),
              alignment: Alignment.topLeft,
              child: MainLogoButton(
                onOpenSettings: () => settingsInput(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
