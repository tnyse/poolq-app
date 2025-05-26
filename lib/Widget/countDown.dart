import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:provider/provider.dart';

class CountdownTimerDemo extends StatefulWidget {
  final DateTime date2;
  CountdownTimerDemo(this.date2);

  @override
  State<CountdownTimerDemo> createState() => _CountdownTimerDemoState();
}

class _CountdownTimerDemoState extends State<CountdownTimerDemo> {
  Timer? _timer;
  int _start = 10;
  bool _isActive = true;
  Duration? difference;
  Duration? myDuration;
  DateTime now = DateTime.now();
  DateTime? date1;

  @override
  void initState() {
    super.initState();
    DataProvider dataProvider = Provider.of(context, listen: false);
    // Update to 2025 season
    String year = dataProvider.game?["year"] ?? "2025";
    date1 = DateTime(int.parse(year), now.month, now.day, now.hour, now.minute, now.second, now.millisecond, now.microsecond);
    difference = widget.date2.difference(date1!);
    myDuration = Duration(days: difference!.inDays);
    startTimer();
  }

  @override
  void dispose() {
    _isActive = false;
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          if (_isActive && mounted) {
            setState(() {
              timer.cancel();
            });
          } else {
            timer.cancel();
          }
        } else {
          if (_isActive && mounted) {
            setState(() {
              _start--;
            });
          }
        }
      },
    );
  }

  void setCountDown() {
    if (_isActive && mounted) {
      setState(() {
        _start = 10;
      });
    }
  }

  int getV() {
    DateTime now2 = DateTime.now();
    DateTime endOfDay = DateTime(now2.year, now2.month, now2.day + 1); // Next day at 00:00:00
    Duration timeLeft = endOfDay.difference(now2);
    int hoursLeft = timeLeft.inHours;
    return hoursLeft == 0 ? 1 : hoursLeft;
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final days = strDigits(myDuration?.inDays ?? 0);
    final minutes = strDigits(myDuration?.inMinutes.remainder(60) ?? 0);
    final seconds = strDigits(myDuration?.inSeconds.remainder(60) ?? 0);
    return Center(
      child: Column(
        children: [
          Text(
            '${difference?.inDays ?? 0} Days ${getV()} hr $minutes mins $seconds sec',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}