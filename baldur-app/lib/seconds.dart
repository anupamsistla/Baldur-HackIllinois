import 'package:flutter/material.dart';

class MySeconds extends StatelessWidget {

  int seconds;
  MySeconds({required this.seconds});

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        child: Center(
          child: Text(
              seconds.toString(),
              style: TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }
}