import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'stats_page.dart';
import 'session.dart';
import 'about_us.dart';
import 'button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baldur',
      theme: ThemeData(
        // Theme of the application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Baldur'),
    );
  }
}

// Configuration for the state.
// Home page of the application.
// It is stateful (has a State object containing fields that affect how it looks)

// Holds the values (title) provided by the parent (App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class MyHomePage extends StatefulWidget {
  final String title;

  final String serverIp = "172.16.98.216";
  final int serverPort = 5005;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  bool isOn = false, firstTime = true;
  Timer? timer;
  int currTime = 0;
  double _scale = 1.0;
  int debrisCount = 0;
  int _selectedIndex = 0;
  List<Session> sessionHistory = []; // Store multiple sessions
  double rangeValue = 50;

  Socket? _socket;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() async {
    try {
      _socket = await Socket.connect(widget.serverIp, widget.serverPort);
      print("Connected to ${widget.serverIp}:${widget.serverPort}");
    } catch (e) {
      print("Failed to connect: $e");
    }
  }

  void _sendCommand(String command) {
    if (_socket != null) {
      _socket!.writeln(command);
      print("Sent command: $command");
    } else {
      print("No connection to server");
    }
  }

  @override
  void dispose() {
    _socket?.destroy();
    super.dispose();
  }

  void startStopwatch() {
    setState(() {
      currTime = 0; // Reset elapsed time
    });
    // Increment every second
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currTime++;
      });
    });
  }

  void toggleMode() {
    setState(() {
      isOn = !isOn;  // Toggle the state
      if (isOn) {
        _sendCommand("run");
        startStopwatch();  // Start stopwatch when turned on
      }
      // Stop stopwatch, add session to stats page, and reset debris count
      else {
        _sendCommand("pause");
        timer?.cancel();
        sessionHistory.add(Session(duration: currTime, debrisCount: debrisCount));
        debrisCount = 0;
      }
    });
  }

  // Format time in HH:MM:SS
  String displayTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString()
        .padLeft(2, '0')}";
  }

  String getTime() {
    return isOn ? "Current Session: ${displayTime(currTime)}" : "No Session Running";
  }

  String getDebrisData() {
    return isOn ? "Debris removed: $debrisCount" : "";
  }

  // Change color and size when the button is pressed
  void onPressed(TapDownDetails details) {
    setState(() {
      _scale = 0.9;
    });
  }

  // Restore original size and color if the press is released
  void onReleased(TapUpDetails details) {
    setState(() {
      _scale = 1.0; // Restore original size
    });
    toggleMode();
  }

  // Restore original size and color if the press is canceled
  void onCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  void rangeChangeWindow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double value = rangeValue; // set value to previous set one

        return StatefulBuilder(
          builder: (context, setState) {

            return AlertDialog(
              title: Text("Adjust Scanning Range"),
              content: Column(
                mainAxisSize: MainAxisSize.min, // Make alert window as small as possible
                children: [
                  // Slider for adjusting range
                  Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: value.round().toString(),
                    onChanged: (double newValue) {
                      setState(() {
                        value = newValue;
                      });
                    },
                  ),
                  Text("Current Range: ${value.round()}"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    rangeValue = value;
                    Navigator.pop(context);
                  },
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void timerWindow(BuildContext context) {
    int selectedHours = 0;
    int selectedMinutes = 0;
    int selectedSeconds = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Timer Duration"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200, // Height for the scrollable pickers
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hours Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: 0),
                        itemExtent: 40, // Height of each item
                        onSelectedItemChanged: (value) {
                          selectedHours = value;
                        },
                        children: List.generate(24, (index) => Text("$index h")),
                      ),
                    ),

                    // Minutes Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: 0),
                        itemExtent: 40,
                        onSelectedItemChanged: (value) {
                          selectedMinutes = value;
                        },
                        children: List.generate(60, (index) => Text("$index min")),
                      ),
                    ),

                    // Seconds Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: 0),
                        itemExtent: 40,
                        onSelectedItemChanged: (value) {
                          selectedSeconds = value;
                        },
                        children: List.generate(60, (index) => Text("$index sec")),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without saving
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Combine selected values into total seconds
                timer?.cancel();
                int totalSeconds = (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds;
                currTime = totalSeconds;
                isOn = true;
                timer = Timer.periodic(Duration(seconds: 1), (timer) {
                  if (currTime > 0) {
                    setState(() {
                      currTime--;
                    });
                  } else {
                    isOn = false;
                    setState(() {
                      timer.cancel();
                      if (totalSeconds > 0) {
                        sessionHistory.add(Session(duration: totalSeconds, debrisCount: debrisCount));
                      }
                      debrisCount = 0;  // Reset debris count when turned off
                    });
                  }
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void getPage(int index) {
    if (index == 1) { // Navigate to Stats
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StatsPage(sessions: sessionHistory)),
      );
    }
    else if (index == 2) { // Navigate to About Us
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AboutUs()),
      );
    }
    else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rerun every time setState is called
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Take value from MyHomePage object that was created by App.build() to set appbar title
        title: Text("ᛞ Baldur ᛞ", style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,

      ),
      // Layout widget that takes a single child and positions it in the middle of the parent.
      body: Center(
        // Layout widget, takes a list of children and arranges them vertically
        child: Column(
          // Center the children vertically
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Text( // Display Running Time
              getTime(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 50), // Spacing between text and main control button
            // Center Button (Main Control)
            AnimatedScale(
              scale: _scale,
              duration: Duration(milliseconds: 100),
              child: GestureDetector(
                // Functions for button tap
                onTapDown: onPressed,
                onTapUp: onReleased,
                onTapCancel: onCancel,

                child: Container( // Outer Thicker Circle
                  padding: EdgeInsets.all(4),  // Control outer spacing
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOn ? Colors.blue : Colors.grey,  // Dynamic color for outer border
                      width: 10,  // Width for outer thicker circle
                    ),
                  ),

                  child: Container( // Inner Circle
                    padding: EdgeInsets.all(20),  // Control the spacing around the image
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blueAccent,  // Static color for inner circle
                        width: 3,  // Static thickness for inner circle
                      ),
                    ),

                    child: Image.asset( // Boulder Image
                      'images/clawPic.png',
                      width: 220,
                      height: 210,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 50), // Spacing between main control and side control

            Row( // Side Control Buttons
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedRoundButton(
                  icon: Icons.alarm,
                  onPressed: () {
                    timerWindow(context);
                  },
                ),

                SizedBox(width: 40),  // Space between buttons

                AnimatedRoundButton(
                  icon: Icons.radar,
                  onPressed: () {
                    rangeChangeWindow(context);
                  },
                ),

                SizedBox(width: 40),  // Space between buttons

                AnimatedRoundButton(
                  icon: Icons.restore_from_trash,
                  onPressed: () {
                    if (isOn) {
                      setState(() {
                        debrisCount++;
                      });
                    }
                  },
                ),
              ],
            ),

            Row(
              children: [
                SizedBox(width: 85),
                Text("Timer"),
                SizedBox(width: 62),
                Text("Range"),
                SizedBox(width: 60),
                Text("Debris"),
              ],
            ),

            SizedBox(height: 50), // Spacing between side control and data text

            Text( // Display Data
              getDebrisData(),
              // "Debris removed: $debrisCount",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: getPage,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Stats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "About Us",
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );

  }
}
