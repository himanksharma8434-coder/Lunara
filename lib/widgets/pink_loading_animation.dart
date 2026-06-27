import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class PinkLoadingAnimation extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onAnimationComplete;

  const PinkLoadingAnimation({
    super.key,
    this.isLoading = true,
    this.onAnimationComplete,
  });

  @override
  State<PinkLoadingAnimation> createState() => _PinkLoadingAnimationState();
}

class _PinkLoadingAnimationState extends State<PinkLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _blastController;

  late Animation<double> _dropAnimation;
  late Animation<double> _overallFadeAnimation;
  late Animation<double> _elementsScaleDownAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entry Drop Animation (Pops down from above smoothly)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _dropAnimation = Tween<double>(begin: -400.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.elasticOut,
      ),
    );

    // 2. Exit Blast Animation
    _blastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // The animation sucks inwards before the blast
    _elementsScaleDownAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _blastController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInBack),
      ),
    );

    // The entire overlay fades out to reveal the home screen
    _overallFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _blastController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start entry animation
    _entryController.forward();

    // Listen for blast completion
    _blastController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(PinkLoadingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading == true && widget.isLoading == false) {
      // Trigger the blast!
      _blastController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _blastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.background(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entryController,
        _blastController,
      ]),
      builder: (context, child) {
        final elementsScale = _elementsScaleDownAnimation.value;
        final overallOpacity = _overallFadeAnimation.value;

        return IgnorePointer(
          ignoring: !widget.isLoading,
          child: Opacity(
            opacity: overallOpacity,
            child: Container(
              color: bgColor, // Solid background
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dropping and smooth Lottie UI
                  Transform.translate(
                    offset: Offset(0, _dropAnimation.value),
                    child: Transform.scale(
                      scale: elementsScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Smooth Lottie Animation with blended edges
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.45,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.6, 1.0], // Solid in center, fades out near edges
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Lottie.asset(
                                'assets/lottie/loading.json',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback if Lottie is missing
                                  return const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFEC407A),
                                    size: 100,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
