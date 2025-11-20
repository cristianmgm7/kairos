import 'package:flutter/material.dart';
import 'package:kairos/core/widgets/app_button.dart';
import 'package:kairos/core/widgets/app_text.dart';

/// A reusable dialog widget for the app
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.content,
    this.actions,
    this.icon,
    super.key,
  })  : _isConfirmation = false,
        _isInfo = false,
        onConfirm = null,
        onCancel = null,
        confirmText = null,
        cancelText = null,
        isDestructive = null,
        onOk = null,
        okText = null;

  /// Creates a confirmation dialog with standard cancel/confirm actions
  const AppDialog.confirmation({
    required this.title,
    required this.content,
    this.onConfirm,
    this.onCancel,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.icon,
    super.key,
  })  : actions = null,
        _isConfirmation = true,
        _isInfo = false,
        onOk = null,
        okText = null;

  /// Creates an info dialog with a single OK button
  const AppDialog.info({
    required this.title,
    required this.content,
    this.onOk,
    this.okText = 'OK',
    this.icon,
    super.key,
  })  : actions = null,
        _isConfirmation = false,
        _isInfo = true,
        onConfirm = null,
        onCancel = null,
        confirmText = null,
        cancelText = null,
        isDestructive = null;

  final String title;
  final String content;
  final List<Widget>? actions;
  final Widget? icon;
  final bool _isConfirmation;
  final bool _isInfo;

  // Confirmation dialog properties
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? confirmText;
  final String? cancelText;
  final bool? isDestructive;

  // Info dialog properties
  final VoidCallback? onOk;
  final String? okText;

  @override
  Widget build(BuildContext context) {
    if (_isConfirmation) {
      return _buildConfirmationDialog(context);
    } else if (_isInfo) {
      return _buildInfoDialog(context);
    } else {
      return _buildCustomDialog(context);
    }
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    return AlertDialog(
      icon: icon,
      title: AppText.titleLarge(title),
      content: AppText.bodyMedium(content),
      actions: [
        AppButton.text(
          text: cancelText ?? 'Cancel',
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
        ),
        if (isDestructive ?? false)
          TextButton(
            onPressed: () {
              onConfirm?.call();
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(confirmText ?? 'Confirm'),
          )
        else
          AppButton.text(
            text: confirmText ?? 'Confirm',
            onPressed: () {
              onConfirm?.call();
              Navigator.of(context).pop(true);
            },
          ),
      ],
    );
  }

  Widget _buildInfoDialog(BuildContext context) {
    return AlertDialog(
      icon: icon,
      title: AppText.titleLarge(title),
      content: AppText.bodyMedium(content),
      actions: [
        AppButton.text(
          text: okText ?? 'OK',
          onPressed: () {
            onOk?.call();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildCustomDialog(BuildContext context) {
    return AlertDialog(
      icon: icon,
      title: AppText.titleLarge(title),
      content: AppText.bodyMedium(content),
      actions: actions ?? [],
    );
  }
}

/// Helper function to show a confirmation dialog
Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
  Widget? icon,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AppDialog.confirmation(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      icon: icon,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}

/// Helper function to show an info dialog
Future<void> showAppInfoDialog({
  required BuildContext context,
  required String title,
  required String content,
  String okText = 'OK',
  Widget? icon,
  VoidCallback? onOk,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) => AppDialog.info(
      title: title,
      content: content,
      okText: okText,
      icon: icon,
      onOk: onOk,
    ),
  );
}
