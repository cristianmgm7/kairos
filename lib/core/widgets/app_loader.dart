import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoader({
    this.size = 40,
    this.color,
    this.strokeWidth = 4,
    super.key,
  });

  const AppLoader.small({
    this.color,
    super.key,
  })  : size = 20,
        strokeWidth = 2;

  const AppLoader.large({
    this.color,
    super.key,
  })  : size = 60,
        strokeWidth = 6;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation(effectiveColor),
        ),
      ),
    );
  }
}

// Full screen loader
class AppFullScreenLoader extends StatelessWidget {
  final String? message;

  const AppFullScreenLoader({
    this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
