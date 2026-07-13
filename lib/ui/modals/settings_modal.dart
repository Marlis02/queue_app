import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/network/network_cubit.dart';
import 'package:queue_app/cubits/network/network_state.dart';
import 'package:queue_app/cubits/queue/queue_cubit.dart';
import 'package:queue_app/cubits/queue/queue_state.dart';
import 'package:queue_app/app.dart';
import 'package:queue_app/cubits/settings/settings_cubit.dart';
import 'package:queue_app/cubits/settings/settings_state.dart';
import 'package:queue_app/ui/modals/logs_modal.dart';

Future<void> settingsInput(BuildContext context) {
  context.read<NetworkCubit>().refreshIp();
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return MediaQuery.withNoTextScaling(
        child: AlertDialog(
          scrollable: true,
          contentPadding: const EdgeInsets.all(20),
          content: FocusTraversalGroup(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settings) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Размер текста',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    _FontSizeStepper(
                      value: settings.fontSize,
                      onDec: () => context
                          .read<SettingsCubit>()
                          .setFontSize(_clampFont(settings.fontSize - 0.1)),
                      onInc: () => context
                          .read<SettingsCubit>()
                          .setFontSize(_clampFont(settings.fontSize + 0.1)),
                    ),
                    const SizedBox(height: 12),
                    _SettingTile(
                      label: 'Reverse List',
                      value: settings.isReverse,
                      onChanged: (_) =>
                          context.read<SettingsCubit>().toggleReverse(),
                    ),
                    const SizedBox(height: 8),
                    _SettingTile(
                      label: 'Keep Screen On',
                      value: settings.keepScreenAwake,
                      onChanged: (value) => context
                          .read<SettingsCubit>()
                          .setKeepScreenAwake(value),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<NetworkCubit, NetworkState>(
                      builder: (context, net) => Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi, size: 20),
                              const SizedBox(width: 6),
                              Text('IP: ${net.ipAddress ?? ""}',
                                  style: const TextStyle(fontSize: 20)),
                            ],
                          ),
                          Text(
                            'HTTP: ${net.httpPort}  •  UDP: ${net.udpPort}',
                            style: const TextStyle(fontSize: 20),
                          ),
                          if (net.errorMessage != null)
                            Text(
                              net.errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 20),
                            ),
                        ],
                      ),
                    ),
                    BlocBuilder<QueueCubit, QueueState>(
                      builder: (context, queueState) => switch (queueState) {
                        QueueError(:final message) => Text(
                            message,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 20),
                          ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => showLogsDialog(context),
                          child: const Text('Логи',
                              style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Закрыть',
                              style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

const double _fontMin = 0.5;
const double _fontMax = 4.0;

double _clampFont(double v) =>
    ((v * 10).roundToDouble() / 10).clamp(_fontMin, _fontMax);

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? const Color(0xFFE0E0E0) : const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSizeStepper extends StatelessWidget {
  const _FontSizeStepper({
    required this.value,
    required this.onDec,
    required this.onInc,
  });

  final double value;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          autofocus: true, // первый фокус для пульта
          onPressed: value > _fontMin ? onDec : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < _fontMax ? onInc : null,
        ),
      ],
    );
  }
}
