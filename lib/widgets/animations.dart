import 'package:flutter/material.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════
//  SUCCESS CHECK ANIMATION
//  A beautiful animated check mark with a circular burst effect.
// ═══════════════════════════════════════════════════════════════════

class SuccessCheckAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final VoidCallback? onComplete;

  const SuccessCheckAnimation({
    super.key,
    this.size = 120,
    this.color,
    this.onComplete,
  });

  @override
  State<SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<SuccessCheckAnimation>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;
  late AnimationController _particleController;

  late Animation<double> _circleScale;
  late Animation<double> _checkProgress;
  late Animation<double> _particleExpand;
  late Animation<double> _particleFade;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _circleScale = CurvedAnimation(
      parent: _circleController,
      curve: Curves.elasticOut,
    );
    _checkProgress = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutCubic,
    );
    _particleExpand = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );
    _particleFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _circleController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    _checkController.forward();
    _particleController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_circleController, _checkController, _particleController]),
        builder: (context, _) {
          return CustomPaint(
            painter: _SuccessCheckPainter(
              circleScale: _circleScale.value,
              checkProgress: _checkProgress.value,
              particleExpand: _particleExpand.value,
              particleFade: _particleFade.value,
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class _SuccessCheckPainter extends CustomPainter {
  final double circleScale;
  final double checkProgress;
  final double particleExpand;
  final double particleFade;
  final Color color;

  _SuccessCheckPainter({
    required this.circleScale,
    required this.checkProgress,
    required this.particleExpand,
    required this.particleFade,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.65;

    // Particle burst
    if (particleFade > 0) {
      final particlePaint = Paint()
        ..color = color.withOpacity(particleFade * 0.6)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4);
        final dist = radius * particleExpand;
        final particleCenter = Offset(
          center.dx + math.cos(angle) * dist,
          center.dy + math.sin(angle) * dist,
        );
        canvas.drawCircle(particleCenter, 3 * particleFade, particlePaint);
      }
    }

    // Circle background
    if (circleScale > 0) {
      final bgPaint = Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * circleScale, bgPaint);

      final ringPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius * circleScale, ringPaint);
    }

    // Check mark
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final startX = center.dx - radius * 0.3;
      final startY = center.dy + radius * 0.05;
      final midX = center.dx - radius * 0.05;
      final midY = center.dy + radius * 0.3;
      final endX = center.dx + radius * 0.35;
      final endY = center.dy - radius * 0.25;

      path.moveTo(startX, startY);

      if (checkProgress <= 0.5) {
        // First stroke (down)
        final t = checkProgress / 0.5;
        path.lineTo(
          startX + (midX - startX) * t,
          startY + (midY - startY) * t,
        );
      } else {
        // First stroke done, second stroke (up)
        path.lineTo(midX, midY);
        final t = (checkProgress - 0.5) / 0.5;
        path.lineTo(
          midX + (endX - midX) * t,
          midY + (endY - midY) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_SuccessCheckPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════
//  ANIMATED PRESSABLE CARD
//  A card that scales down on press for tactile feedback.
// ═══════════════════════════════════════════════════════════════════

class AnimatedPressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  final Duration duration;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AnimatedPressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.decoration,
    this.padding,
    this.margin,
  });

  @override
  State<AnimatedPressableCard> createState() => _AnimatedPressableCardState();
}

class _AnimatedPressableCardState extends State<AnimatedPressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          margin: widget.margin,
          decoration: widget.decoration,
          child: widget.child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHIMMER LOADING
//  A theme-aware shimmer placeholder for loading states.
// ═══════════════════════════════════════════════════════════════════

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FADE SLIDE IN
//  Wraps any widget to give it a slide-up-and-fade-in entrance.
// ═══════════════════════════════════════════════════════════════════

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offsetY = 30.0,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
