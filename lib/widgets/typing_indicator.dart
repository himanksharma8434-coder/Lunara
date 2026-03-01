import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color dotColor;
  const TypingIndicator({super.key, this.dotColor = const Color(0xFFD8405B)});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(); // This makes it jump forever
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Calculate a delayed staggered bounce for each dot
            final double delay = index * 0.2;
            final double value =
                (_animationController.value - delay).clamp(0.0, 1.0);
            final double bounce = (value < 0.5)
                ? (value * 2) // Moving up
                : (1.0 - (value - 0.5) * 2); // Moving down

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 8 + (bounce * 8), // Changes height slightly to "jump"
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.dotColor.withOpacity(0.4 + (bounce * 0.6)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
