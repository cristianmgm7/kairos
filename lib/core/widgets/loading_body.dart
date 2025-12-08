import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';

class LoadingBody extends StatelessWidget {
  const LoadingBody({
    this.height,
    super.key,
    this.loadingMessage,
  });

  final double? height;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.xs),
            if (loadingMessage != null) Text(loadingMessage!),
          ],
        ),
      ),
    );
  }
}
