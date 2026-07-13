import 'package:flutter/material.dart';
import 'dart:async';

class CurrentTimeWidget extends StatefulWidget {
  const CurrentTimeWidget({super.key});

  @override
  _CurrentTimeWidgetState createState() => _CurrentTimeWidgetState();
}

class _CurrentTimeWidgetState extends State<CurrentTimeWidget> {
  String _currentTime = _formatTime(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = _formatTime(DateTime.now());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _currentTime,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          color: Color.fromARGB(255, 197, 196, 196),
        ),
      ),
    );
  }
}
