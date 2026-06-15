import 'package:flutter/material.dart';

class OpenCameraView extends StatelessWidget {
  final Function() onButtonPressed;
  const OpenCameraView({super.key, required this.onButtonPressed});

  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onButtonPressed();
      },
      child: Container(
        width: 200,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.camera, color: Colors.white),
            Text(
              'Use Camera',
              style: TextStyle(color: Colors.white, fontSize: 23),
            ),
          ],
        ),
      ),
    );
  }
}
