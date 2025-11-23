import 'package:flutter/material.dart';
import 'package:kairos/core/widgets/eager_providers.dart';
import 'package:kairos/core/widgets/keyboard_dismisser.dart';
import 'package:nested/nested.dart';

class Globals extends StatelessWidget {
  const Globals({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Nested(
      children: const [
        KeyboardDismisser(),
        EagerProviders(),
      ],
      child: child,
    );
  }
}
