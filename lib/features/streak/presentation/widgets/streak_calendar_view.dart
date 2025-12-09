import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/presentation/providers/streak_providers.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakCalendarView extends ConsumerStatefulWidget {
  const StreakCalendarView({super.key});

  @override
  ConsumerState<StreakCalendarView> createState() => _StreakCalendarViewState();
}

class _StreakCalendarViewState extends ConsumerState<StreakCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailyActivitiesAsync = ref.watch(dailyActivitiesProvider);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            dailyActivitiesAsync.when(
              data: (activities) => _buildCalendar(context, activities),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading calendar: $error'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, List<Map<String, dynamic>> activities) {
    final theme = Theme.of(context);

    // Convert activities to a map of dates with activity counts
    final activityMap = <DateTime, int>{};
    for (final activity in activities) {
      final date = DateTime.parse(activity['date'] as String);
      final count = activity['entryCount'] as int;
      if (count > 0) {
        activityMap[DateTime(date.year, date.month, date.day)] = count;
      }
    }

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 30)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
        defaultTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
        outsideTextStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ) ??
            const TextStyle(),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle(),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: theme.colorScheme.onSurface,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final count = activityMap[DateTime(date.year, date.month, date.day)];
          if (count != null && count > 0) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getActivityColor(count),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
        defaultBuilder: (context, date, focusedDay) {
          final count = activityMap[DateTime(date.year, date.month, date.day)];
          if (count != null && count > 0) {
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getActivityColor(count).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date.day.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return null;
        },
        todayBuilder: (context, date, focusedDay) {
          final count = activityMap[DateTime(date.year, date.month, date.day)];
          return Container(
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: count != null && count > 0
                  ? _getActivityColor(count).withValues(alpha: 0.2)
                  : theme.colorScheme.primary.withValues(alpha: 0.3),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              date.day.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, '1 entry', _getActivityColor(1)),
        const SizedBox(width: AppSpacing.md),
        _buildLegendItem(context, '2-3 entries', _getActivityColor(2)),
        const SizedBox(width: AppSpacing.md),
        _buildLegendItem(context, '4+ entries', _getActivityColor(4)),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(int count) {
    if (count == 1) {
      return const Color(0xFF9BE9A8); // Light green
    } else if (count <= 3) {
      return const Color(0xFF40C463); // Medium green
    } else {
      return const Color(0xFF30A14E); // Dark green
    }
  }
}
