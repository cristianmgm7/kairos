import 'package:flutter/material.dart';

import 'package:kairos/core/theme/app_spacing.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.message,
    this.title,
    this.onRetry,
    this.icon = Icons.error_outline,
    super.key,
  });

  /// Convenience constructor that accepts an error object directly
  AppErrorView.fromError({
    required Object error,
    this.title,
    this.onRetry,
    this.icon = Icons.error_outline,
    super.key,
  }) : message = error.toString();

  final String message;
  final String? title;
  final VoidCallback? onRetry;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: colors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Empty state variant
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.message,
    this.title,
    this.onAction,
    this.actionText,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final String? title;
  final VoidCallback? onAction;
  final String? actionText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: colors.outline,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
