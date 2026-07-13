import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/settings/settings_cubit.dart';
import 'package:queue_app/cubits/settings/settings_state.dart';
import 'package:queue_app/ui/home_screen.dart';

/// Радиус скруглений во всём приложении.
const double kRadius = 8;

/// Стандартная высота кнопок.
const double kButtonHeight = 44;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CTmax Queue',
      theme: _buildTheme(),
      // Глобальный масштаб текста из настроек.
      builder: (context, child) => BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (prev, next) => prev.fontSize != next.fontSize,
        builder: (context, settings) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontSize),
          ),
          child: child!,
        ),
      ),
      home: const SafeArea(
        child: HomeScreen(),
      ),
    );
  }

  /// Чёрно-белая тема: классические кнопки, скругления [kRadius].
  ThemeData _buildTheme() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
      cardTheme: CardThemeData(shape: shape),
      // Кнопки в модалках — классические чёрно-белые с рамкой,
      // единой высотой [kButtonHeight], чтобы читались как кнопки.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          minimumSize: const Size(0, kButtonHeight),
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          minimumSize: const Size(0, kButtonHeight),
          elevation: 0,
          shape: shape,
        ),
      ),
      // IconButton — квадратный с рамкой и скруглением [kRadius].
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: shape,
          fixedSize: const Size.square(kButtonHeight),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.black,
        thumbColor: Colors.black,
        inactiveTrackColor: Color(0xFFBDBDBD),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : Colors.black,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white,
        ),
        // Обводка, чтобы переключатель читался и в выключенном состоянии.
        trackOutlineColor: WidgetStateProperty.all(Colors.black),
        trackOutlineWidth: WidgetStateProperty.all(1.5),
      ),
    );
  }
}
