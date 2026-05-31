import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class InsightsShimmer extends StatelessWidget {
  const InsightsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerCard(context, height: 200),
          const SizedBox(height: 20),
          _buildShimmerCard(context, height: 260),
          const SizedBox(height: 20),
          _buildShimmerCard(context, height: 260),
          const SizedBox(height: 20),
          _buildShimmerCard(context, height: 180),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context, {required double height}) {
    return ShimmerLoading(
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(LunaraRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerBox(width: 40, height: 40, borderRadius: 10),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 80, height: 12),
                    SizedBox(height: 6),
                    ShimmerBox(width: 120, height: 20),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const ShimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            const ShimmerBox(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}

class CommunityPostShimmer extends StatelessWidget {
  const CommunityPostShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ShimmerLoading(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerCircle(size: 45),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: 120, height: 16),
                          SizedBox(height: 6),
                          ShimmerBox(width: 80, height: 12),
                        ],
                      ),
                    ),
                    const ShimmerBox(width: 60, height: 24, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 15),
                const ShimmerBox(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const ShimmerBox(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const ShimmerBox(width: 200, height: 14),
                const SizedBox(height: 15),
                Row(
                  children: const [
                    ShimmerBox(width: 60, height: 32, borderRadius: 12),
                    SizedBox(width: 10),
                    ShimmerBox(width: 60, height: 32, borderRadius: 12),
                    Spacer(),
                    ShimmerBox(width: 32, height: 32, borderRadius: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
