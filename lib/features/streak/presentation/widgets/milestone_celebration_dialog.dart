import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';

class MilestoneCelebrationDialog extends StatefulWidget {
  const MilestoneCelebrationDialog({
    required this.achievement,
    super.key,
  });

  final AchievementEntity achievement;

  @override
  State<MilestoneCelebrationDialog> createState() => _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ),);

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ),);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration animation
                _buildCelebrationHeader(context),
                const SizedBox(height: AppSpacing.lg),

                // Achievement details
                _buildAchievementContent(context),
                const SizedBox(height: AppSpacing.xl),

                // Continue button
                _buildContinueButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Animated sparkles/confetti effect
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _getAchievementColor(widget.achievement.type).withValues(alpha: 0.2),
                _getAchievementColor(widget.achievement.type).withValues(alpha: 0.4),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getAchievementColor(widget.achievement.type).withValues(alpha: 0.1),
                ),
              ),

              // Achievement icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getAchievementColor(widget.achievement.type),
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 4,
                  ),
                ),
                child: Icon(
                  _getAchievementIcon(widget.achievement.type),
                  color: theme.colorScheme.onPrimary,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Celebration text
        Text(
          '🎉 Achievement Unlocked! 🎉',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Achievement title
        Text(
          _getAchievementTitle(widget.achievement.type),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Achievement description
        Text(
          _getAchievementDescription(widget.achievement.type),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),

        // Unlocked date
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Unlocked ${_formatDate(widget.achievement.unlockedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Continue Journey',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return Icons.edit_note;
      case AchievementType.streak7:
        return Icons.view_week;
      case AchievementType.streak30:
        return Icons.calendar_view_month;
      case AchievementType.streak100:
        return Icons.event_available;
      case AchievementType.streak365:
        return Icons.timeline;
      case AchievementType.weekGoal:
        return Icons.celebration;
    }
  }

  Color _getAchievementColor(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return const Color(0xFF4CAF50); // Green
      case AchievementType.streak7:
        return const Color(0xFF2196F3); // Blue
      case AchievementType.streak30:
        return const Color(0xFF9C27B0); // Purple
      case AchievementType.streak100:
        return const Color(0xFFFF9800); // Orange
      case AchievementType.streak365:
        return const Color(0xFFE91E63); // Pink
      case AchievementType.weekGoal:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  String _getAchievementTitle(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return 'First Steps Taken';
      case AchievementType.streak7:
        return 'Week Warrior';
      case AchievementType.streak30:
        return 'Monthly Master';
      case AchievementType.streak100:
        return 'Century Champion';
      case AchievementType.streak365:
        return 'Year of Wisdom';
      case AchievementType.weekGoal:
        return 'Weekly Warrior';
    }
  }

  String _getAchievementDescription(AchievementType type) {
    switch (type) {
      case AchievementType.firstEntry:
        return 'Your journaling journey has officially begun! Every great story starts with a single word.';
      case AchievementType.streak7:
        return "Seven days of dedication! You've turned journaling into a habit that will serve you for life.";
      case AchievementType.streak30:
        return "A full month of self-reflection! You're building wisdom that compounds over time.";
      case AchievementType.streak100:
        return '100 days of transformation! Your commitment is inspiring and your future self will thank you.';
      case AchievementType.streak365:
        return "A year of daily wisdom! You've given yourself the gift of self-discovery and growth.";
      case AchievementType.weekGoal:
        return "Perfect week completed! You're mastering the art of consistency.";
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final achievementDate = DateTime(date.year, date.month, date.day);

    if (achievementDate == today) {
      return 'today';
    } else if (achievementDate == today.subtract(const Duration(days: 1))) {
      return 'yesterday';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  static Future<void> show(BuildContext context, AchievementEntity achievement) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneCelebrationDialog(achievement: achievement),
    );
  }
}
