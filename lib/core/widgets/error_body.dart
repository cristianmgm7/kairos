import 'package:flutter/material.dart';
import 'package:kairos/core/extensions/extensions.dart';
import 'package:kairos/core/theme/app_spacing.dart';

class ErrorBody extends StatelessWidget {
  const ErrorBody({
    required this.description,
    this.title,
    this.height,
    super.key,
  });

  final String? title;
  final String description;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error,
            size: 80,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (title != null)
            Text(
              title!,
              style: theme.textTheme.titleLarge,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            description,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
