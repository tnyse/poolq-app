import 'dart:async';

import 'package:flutter/material.dart';

/// Live countdown to [deadline]. Ticks every second.
class CountdownTimerDemo extends StatefulWidget {
  final DateTime deadline;
  final TextStyle? style;
  final String lockedLabel;

  const CountdownTimerDemo(
    this.deadline, {
    super.key,
    this.style,
    this.lockedLabel = 'Entries locked',
  });

  @override
  State<CountdownTimerDemo> createState() => _CountdownTimerDemoState();
}

class _CountdownTimerDemoState extends State<CountdownTimerDemo> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(CountdownTimerDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final next = widget.deadline.difference(DateTime.now());
    setState(() {
      _remaining = next.isNegative ? Duration.zero : next;
    });
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
          letterSpacing: 0.3,
        );

    if (_remaining == Duration.zero &&
        !widget.deadline.isAfter(DateTime.now())) {
      return Text(widget.lockedLabel, style: style, textAlign: TextAlign.center);
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final label = days > 0
        ? '$days Day${days == 1 ? '' : 's'} ${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}'
        : '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}';

    return Text(label, style: style, textAlign: TextAlign.center);
  }
}
