import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/theme/app_spacing.dart';

/// Push notifications settings screen - allows user to manage notification preferences.
class PushNotificationsScreen extends ConsumerWidget {
  const PushNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Notification Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Manage how and when you receive notifications from the app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _NotificationSwitchTile(
            title: 'Enable Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: true, // TODO: Connect to actual notification settings
            onChanged: (value) {
              // TODO: Implement notification toggle
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Notifications enabled' : 'Notifications disabled',
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _NotificationSwitchTile(
            title: 'Daily Reminders',
            subtitle: 'Get reminded to journal every day',
            value: false, // TODO: Connect to actual notification settings
            onChanged: (value) {
              // TODO: Implement daily reminder toggle
            },
          ),
          const Divider(),
          _NotificationSwitchTile(
            title: 'Insights Updates',
            subtitle: 'Get notified when new insights are available',
            value: true, // TODO: Connect to actual notification settings
            onChanged: (value) {
              // TODO: Implement insights notification toggle
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.title,
    required this.value, required this.onChanged, this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
