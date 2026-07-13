import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queue_app/app.dart';
import 'package:queue_app/cubits/audio/audio_cubit.dart';
import 'package:queue_app/cubits/queue/queue_cubit.dart';
import 'package:queue_app/cubits/settings/settings_cubit.dart';
import 'package:queue_app/services/audio_service.dart';
import 'package:queue_app/services/settings_repository.dart';
import 'package:queue_app/ui/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsCubit settingsCubit;
  late QueueCubit queueCubit;
  late AudioCubit audioCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settingsCubit = SettingsCubit(SettingsRepository());
    queueCubit = QueueCubit();
    audioCubit = AudioCubit(AudioService());
  });

  tearDown(() async {
    await settingsCubit.close();
    await queueCubit.close();
    await audioCubit.close();
  });

  Widget buildApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsCubit),
        BlocProvider.value(value: queueCubit),
        BlocProvider.value(value: audioCubit),
      ],
      child: const MyApp(),
    );
  }

  testWidgets('без данных показывается индикатор ожидания',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(Loading), findsOneWidget);
    expect(find.text('Готовятся'), findsNothing);

    await tester.pumpWidget(const SizedBox()); // dispose таймеров/аниматоров
  });

  testWidgets('после прихода данных рендерится табло',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    const raw = '{"queues":{"cooking":[{"id":1,"time":"12.07.2026 10:00",'
        '"info":"Заказ","counter":"5"}],"done":[{"id":2,'
        '"time":"12.07.2026 10:01","info":"Готов","counter":"7",'
        '"selected":false}]}}';
    final accepted = queueCubit.onPayloadReceived(raw, source: 'test');
    expect(accepted, isTrue);
    await tester.pump();

    expect(find.text('Готовятся'), findsOneWidget);
    expect(find.text('Готовы'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byType(Loading), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('битый payload не роняет UI — старые данные остаются',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    queueCubit.onPayloadReceived(
      '{"queues":{"cooking":[{"id":1,"time":"мусорная дата","info":"X",'
      '"counter":"5"}],"done":[]}}',
      source: 'test',
    );
    await tester.pump();
    expect(find.text('Готовятся'), findsOneWidget); // строка с кривой датой отрисована

    final accepted = queueCubit.onPayloadReceived('не json', source: 'test');
    expect(accepted, isFalse);
    await tester.pump();
    // Табло всё ещё показывает последние хорошие данные.
    expect(find.text('Готовятся'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
