import 'package:claw_app/minutes.dart';
import 'package:claw_app/seconds.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'hours.dart';

class MyTimePage extends StatefulWidget {
  const MyTimePage({super.key, required this.title});

  final String title;

  @override
  State<MyTimePage> createState() => _MyTimePageState();
}

class _MyTimePageState extends State<MyTimePage> {
  int selectedHours = 0;
  int selectedMinutes = 0;
  int selectedSeconds = 0;
  Timer? timer;
  bool isRunning = false;
  int remainingSeconds = 0;

  void setTimer() {
    setState(() {
      isRunning = true;
      remainingSeconds = (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds;
    });

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        stopTimer();
      }
    });
  }

  void stopTimer() {
    if (timer != null) {
      timer!.cancel();
    }
    setState(() {
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Set Timer"),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildTimeColumn("Hours", 24, (index) {
            return GestureDetector(
              onTap: () => setState(() => selectedHours = index),
              child: MyHours(hours: index),
            );
          }),
          buildTimeColumn("Minutes", 60, (index) {
            return GestureDetector(
              onTap: () => setState(() => selectedMinutes = index),
              child: MyMinutes(mins: index),
            );
          }),
          buildTimeColumn("Seconds", 60, (index) {
            return GestureDetector(
              onTap: () => setState(() => selectedSeconds = index),
              child: MySeconds(seconds: index),
            );
          }),
        ],
      ),
    );
  }

  Widget buildTimeColumn(String label, int childCount, Widget Function(int) builder) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(height: 250),
          Text(label, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // Label for each wheel
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              perspective: 0.01,
              diameterRatio: 1.2,
              physics: FixedExtentScrollPhysics(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: childCount,
                builder: (context, index) => builder(index),
              ),
            ),
          ),
          SizedBox(height: 350),
        ],
      ),


    );
  }
}
