import 'package:flutter/material.dart';
import 'package:nested/nested.dart';

class KeyboardDismisser extends SingleChildStatelessWidget {
  const KeyboardDismisser({super.key});

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final focusScopeNode = FocusScope.of(context);
        if (!focusScopeNode.hasPrimaryFocus && focusScopeNode.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}
