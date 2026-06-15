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
          StartAudioCaptureWidget(
            buttonText: 'Use voice controls',
            onButtonPressed: () {},
          ),
          OpenCameraView(onButtonPressed: () {}),
        ],
      ),
    );
  }
}
