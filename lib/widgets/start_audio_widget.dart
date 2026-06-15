import 'package:flutter/material.dart';

class StartAudioCaptureWidget extends StatelessWidget {
  final String buttonText;
  final Function() onButtonPressed;

  const StartAudioCaptureWidget({
    super.key,
    required this.buttonText,
    required this.onButtonPressed,
  });

  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 100,
      child: InkWell(
        onTap: onButtonPressed,
        customBorder: CircleBorder(),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.9))],
          ),

          child: Icon(Icons.mic, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
