import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/features/settings/presentation/providers/settings_providers.dart';
import 'package:nested/nested.dart';

class EagerProviders extends SingleChildStatelessWidget {
  const EagerProviders({
    super.key,
  });

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return Consumer(
      builder: (context, ref, _) {
        ref.watch(settingsControllerProvider);

        return child!;
      },
    );
  }
}
