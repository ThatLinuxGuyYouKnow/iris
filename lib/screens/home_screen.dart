import 'package:flutter/material.dart';
import 'package:iris/widgets/open_camera_view.dart';
import 'package:iris/widgets/start_audio_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Campus Navigation', style: TextStyle(fontSize: 25)),
          ),
          StartAudioCaptureWidget(
            buttonText: 'Use voice controls',
            onButtonPressed: () {},
          ),
          SizedBox(height: 20),
          Text('Tap to start voice controls'),
          SizedBox(height: 10),
          OpenCameraView(onButtonPressed: () {}),
        ],
      ),
    );
  }
}
