import 'package:flutter/material.dart';

class StartAudioCaptureWidget extends StatefulWidget {
  final String buttonText;
  final Function() onButtonPressed;

  const StartAudioCaptureWidget({
    super.key,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  State<StartAudioCaptureWidget> createState() =>
      _StartAudioCaptureWidgetState();
}

class _StartAudioCaptureWidgetState extends State<StartAudioCaptureWidget>
    with SingleTickerProviderStateMixin {
  static const double _buttonSize = 200;
  static const double _ringScale = 1.6;
  static const Color _accent = Color.fromARGB(255, 2, 111, 201);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expandedSize = _buttonSize * _ringScale;
    return SizedBox(
      height: expandedSize,
      width: expandedSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulsingRing(animation: _controller, phase: 0.0, color: _accent),
          _PulsingRing(animation: _controller, phase: 0.5, color: _accent),
          SizedBox(
            height: _buttonSize,
            width: _buttonSize,
            child: InkWell(
              onTap: widget.onButtonPressed,
              customBorder: const CircleBorder(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 60),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingRing extends StatelessWidget {
  final Animation<double> animation;
  final double phase;
  final Color color;

  const _PulsingRing({
    required this.animation,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (animation.value + phase) % 1.0;
        final eased = Curves.easeOut.transform(t);
        final scale = 1.0 + eased * 0.6;
        final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.7;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
            ),
          ),
        );
      },
    );
  }
}
