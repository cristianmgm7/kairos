import 'package:flutter/material.dart';
import 'package:kairos/core/extensions/extensions.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    this.title = 'Kairos',
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
