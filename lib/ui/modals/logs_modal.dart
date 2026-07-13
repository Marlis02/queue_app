import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_app/cubits/log/log_cubit.dart';

/// Модалка «Логи»: журнал событий (сеть, данные, озвучка).
void showLogsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(12),
        title: const Text('Логи', textAlign: TextAlign.center),
        content: SizedBox(
          width: 500,
          height: 400,
          child: BlocBuilder<LogCubit, List<LogEntry>>(
            builder: (context, entries) {
              if (entries.isEmpty) {
                return const Center(child: Text('Пока пусто'));
              }
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${entry.timeLabel}  ${entry.message}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.read<LogCubit>().clear(),
            child: const Text('Очистить'),
          ),
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );
    },
  );
}
