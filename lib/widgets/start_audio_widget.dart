import 'package:flutter/material.dart';
import 'package:iris/themes/theme.dart';

class StartAudioCaptureWidget extends StatefulWidget {
  final String buttonText;
  final Function() onButtonPressed;
  final bool isListening;

  const StartAudioCaptureWidget({
    super.key,
    required this.buttonText,
    required this.onButtonPressed,
    this.isListening = false,
  });

  @override
  State<StartAudioCaptureWidget> createState() =>
      _StartAudioCaptureWidgetState();
}

class _StartAudioCaptureWidgetState extends State<StartAudioCaptureWidget>
    with SingleTickerProviderStateMixin {
  static const double _buttonSize = 120;
  static const double _ringScale = 1.5;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(StartAudioCaptureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expandedSize = _buttonSize * _ringScale;
    
    // Choose accent color based on state
    final color = widget.isListening ? kPrimaryAccent : kSecondaryAccent;

    return SizedBox(
      height: expandedSize,
      width: expandedSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isListening) ...[
            _PulsingRing(animation: _controller, phase: 0.0, color: color),
            _PulsingRing(animation: _controller, phase: 0.5, color: color),
          ],
          SizedBox(
            height: _buttonSize,
            width: _buttonSize,
            child: InkWell(
              onTap: widget.onButtonPressed,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isListening ? null : kAccentGradient,
                  color: widget.isListening ? color : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: widget.isListening ? 30 : 15,
                      spreadRadius: widget.isListening ? 10 : 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none, 
                  color: Colors.white, 
                  size: 48,
                ),
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
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
            ),
          ),
        );
      },
    );
  }
}
