import 'package:flutter/material.dart';

class AnimatedRoundButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const AnimatedRoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  AnimatedRoundButtonState createState() => AnimatedRoundButtonState();
}

// State for the button
class AnimatedRoundButtonState extends State<AnimatedRoundButton> {
  Color _buttonColor = Colors.blue[600]!;
  double _scale = 1.0;

  // Change color and size when the button is pressed
  void onPressed(TapDownDetails details) {
    setState(() {
      _buttonColor = Colors.blue[800]!;
      _scale = 0.9;
    });
  }

  // Restore original size and color if the press is released
  void onRelease(TapUpDetails details) {
    setState(() {
      _buttonColor = Colors.blue[600]!;
      _scale = 1.0;
    });
    widget.onPressed();
  }

  // Restore original size and color if the press is canceled
  void onCancel() {
    setState(() {
      _buttonColor = Colors.blue[600]!;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Functions for button tap
      onTapDown: onPressed,
      onTapUp: onRelease,
      onTapCancel: onCancel,

      // Layout widget that takes a single icon and positions it in the middle of the parent.
      child: Transform.scale(
        scale: _scale, // Shrinking effect
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _buttonColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 30), // Icon for the button
        ),
      ),
    );
  }
}