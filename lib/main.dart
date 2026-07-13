import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/app.dart';
import 'package:queue_app/cubits/audio/audio_cubit.dart';
import 'package:queue_app/cubits/log/log_cubit.dart';
import 'package:queue_app/cubits/network/network_cubit.dart';
import 'package:queue_app/cubits/queue/queue_cubit.dart';
import 'package:queue_app/cubits/settings/settings_cubit.dart';
import 'package:queue_app/services/audio_service.dart';
import 'package:queue_app/services/settings_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (_) => LogCubit(),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => SettingsCubit(SettingsRepository())..loadSettings(),
        ),
        BlocProvider(
          lazy: false,
          create: (context) =>
              AudioCubit(AudioService(), log: context.read<LogCubit>().add),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => QueueCubit(log: context.read<LogCubit>().add),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => NetworkCubit(
            queueCubit: context.read<QueueCubit>(),
            log: context.read<LogCubit>().add,
          )..start(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
