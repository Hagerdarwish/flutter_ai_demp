import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  const AppLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer placeholder for list items
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFE2E8F0),
      highlightColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer list that works BOTH inside bounded parents (Scaffold body, Expanded)
/// AND inside unbounded parents (Column, CustomScrollView sliver).
///
/// When [shrinkWrap] is true (default: false) it uses a Column instead of ListView
/// to avoid the "unbounded height" assertion.
class ShimmerList extends StatelessWidget {
  final int count;
  final bool shrinkWrap;

  const ShimmerList({super.key, this.count = 4, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      count,
      (i) => Padding(
        padding: EdgeInsets.only(bottom: i < count - 1 ? 12 : 0),
        child: const ShimmerCard(),
      ),
    );

    if (shrinkWrap) {
      // Use Column when inside an unbounded parent (Column, sliver, etc.)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(children: items),
      );
    }

    // Default: full scrollable list — must be inside a bounded parent
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const ShimmerCard(),
    );
  }
}

/// AI processing indicator card
class ProcessingCard extends StatelessWidget {
  final String message;
  const ProcessingCard({super.key, this.message = 'Analyzing with AI…'});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'This may take a moment depending on the file size.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
