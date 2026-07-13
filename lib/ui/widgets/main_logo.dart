import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/settings/settings_cubit.dart';

/// Логотип: двойной тап (тач) открывает настройки. На пульте настройки
/// открывает центр/OK — глобально в HomeScreen, поэтому Focus здесь не нужен.
class MainLogoButton extends StatelessWidget {
  const MainLogoButton({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final fontSize = context.select((SettingsCubit c) => c.state.fontSize);
    return GestureDetector(
      onDoubleTap: onOpenSettings,
      child: Image.asset(
        'assets/main_logo.png',
        height: 50 * fontSize,
      ),
    );
  }
}
