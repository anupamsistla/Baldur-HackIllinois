import 'package:flutter/material.dart';

class MyMinutes extends StatelessWidget {

  int mins;
  MyMinutes({required this.mins});

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        child: Center(
          child: Text(
            mins.toString(),
            style: TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }
}

