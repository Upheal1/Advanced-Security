import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;

  const SkeletonLoader.cardSkeleton({Key? key, this.width, this.height})
      : child = const _CardSkeleton(),
        super(key: key);

  const SkeletonLoader.chartSkeleton({Key? key, this.width, this.height})
      : child = const _ChartSkeleton(),
        super(key: key);

  const SkeletonLoader.listItemSkeleton({Key? key, this.width, this.height})
      : child = const _ListItemSkeleton(),
        super(key: key);

  const SkeletonLoader({super.key, required this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.15),
      highlightColor: Colors.white.withOpacity(0.3),
      period: const Duration(milliseconds: 1200),
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 16, width: 120, decoration: _block()),
          const SizedBox(height: 12),
          Container(height: 24, width: 160, decoration: _block()),
          const SizedBox(height: 12),
          Container(height: 12, width: double.infinity, decoration: _block()),
          const SizedBox(height: 8),
          Container(height: 12, width: double.infinity, decoration: _block()),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(height: 16, width: 120, decoration: _block()),
              const Spacer(),
              Container(height: 12, width: 60, decoration: _block()),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(8, (index) {
                final h = 40.0 + (index * 10);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 16,
                    height: h,
                    decoration: _block(radius: 8),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItemSkeleton extends StatelessWidget {
  const _ListItemSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(height: 48, width: 48, decoration: _block(radius: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, decoration: _block()),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, decoration: _block()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(height: 14, width: 40, decoration: _block()),
            ],
          ),
        );
      }),
    );
  }
}

BoxDecoration _block({double radius = 10}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.35),
    borderRadius: BorderRadius.circular(radius),
  );
}
