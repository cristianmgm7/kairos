import 'package:flutter/material.dart';

enum AppButtonType { elevated, outlined, text }

class AppButton extends StatelessWidget {
  // constructor
  const AppButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.elevated,
    this.icon,
    this.fullWidth = false,
    super.key,
  });
  // constructors
  const AppButton.elevated({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    super.key,
  }) : type = AppButtonType.elevated;
  // constructor
  const AppButton.outlined({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    super.key,
  }) : type = AppButtonType.outlined;

  // constructor
  const AppButton.text({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    super.key,
  }) : type = AppButtonType.text;

  // properties
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final Widget? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    // build the button based on the type
    final button = switch (type) {
      AppButtonType.elevated => _buildElevatedButton(context),
      AppButtonType.outlined => _buildOutlinedButton(context),
      AppButtonType.text => _buildTextButton(context),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildElevatedButton(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? _buildLoader(context) : icon!,
        label: Text(text),
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? _buildLoader(context) : Text(text),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? _buildLoader(context) : icon!,
        label: Text(text),
      );
    }
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? _buildLoader(context) : Text(text),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? _buildLoader(context) : icon!,
        label: Text(text),
      );
    }
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? _buildLoader(context) : Text(text),
    );
  }

  Widget _buildLoader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          type == AppButtonType.elevated ? colors.onPrimary : colors.primary,
        ),
      ),
    );
  }
}
