import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:provider/provider.dart';

class CountdownTimerDemo extends StatefulWidget {
  DateTime date2;
  CountdownTimerDemo(this.date2);

  @override
  State<CountdownTimerDemo> createState() => _CountdownTimerDemoState();
}



class _CountdownTimerDemoState extends State<CountdownTimerDemo> {
  // Step 2
  Timer? countdownTimer;
  Duration ?difference;
  Duration ?myDuration ;
  DateTime now = DateTime.now();
  DateTime ?date1;
  @override
  void initState() {
    super.initState();
    DataProvider dataProvider = Provider.of(context, listen: false);
    // print(DateTime(int.parse(dataProvider.game!["year"]), now.month, now.day, now.hour, now.minute, now.second, now.millisecond, now.microsecond));
    // print(widget.date2);
    date1 = DateTime(int.parse(dataProvider.game!["year"]), now.month, now.day, now.hour, now.minute, now.second, now.millisecond, now.microsecond);
    difference =  widget.date2.difference(date1!);
    myDuration = Duration(days: difference!.inDays);
    startTimer();
  }
  /// Timer related methods ///
  // Step 3
  void startTimer() {
    countdownTimer =
        Timer.periodic(Duration(seconds: 1), (_) => setCountDown());
  }
  // Step 4
  void stopTimer() {
    setState(() => countdownTimer!.cancel());
  }
  // Step 5
  void resetTimer() {
    stopTimer();
    setState(() => myDuration = Duration(days: 5));
  }
  // Step 6
  void setCountDown() {
    final reduceSecondsBy = 1;
    setState(() {
      final seconds = myDuration!.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countdownTimer!.cancel();
      } else {
        myDuration = Duration(seconds: seconds);
      }
    });
  }

  getV(){
    DateTime now2 = DateTime.now();
    DateTime endOfDay = DateTime(now2.year, now2.month, now2.day + 1); // Next day at 00:00:00
    Duration timeLeft = endOfDay.difference(now);
    int hoursLeft = timeLeft.inHours;
    return hoursLeft==0?1:hoursLeft;
  }



  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final days = strDigits(myDuration!.inDays);



    // Step 7
    // final hours = strDigits(myDuration!.inHours.remainder(int.parse(date1!.hour.toString())));
    final minutes = strDigits(myDuration!.inMinutes.remainder(60));
    final seconds = strDigits(myDuration!.inSeconds.remainder(60));
    return Center(
      child: Column(
        children: [
          Text(
            '${difference!.inDays} Days ${getV()} hr $minutes mins $seconds sec',
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