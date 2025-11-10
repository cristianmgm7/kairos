import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';

class MoodChartWidget extends StatelessWidget {
  const MoodChartWidget({
    required this.insights,
    super.key,
  });

  final List<InsightEntity> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No mood data available yet'),
        ),
      );
    }

    // Sort by date (oldest first for chronological display)
    final sortedInsights = List<InsightEntity>.from(insights)
      ..sort((a, b) => a.periodEnd.compareTo(b.periodEnd));

    // Take last 14 insights (2 weeks)
    final displayInsights = sortedInsights.length > 14
        ? sortedInsights.sublist(sortedInsights.length - 14)
        : sortedInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Mood Over Time',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                minY: 0,
                barGroups: displayInsights.asMap().entries.map((entry) {
                  final index = entry.key;
                  final insight = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: insight.moodScore,
                        color: _getEmotionColor(insight.dominantEmotion),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= displayInsights.length) {
                          return const SizedBox();
                        }
                        final insight = displayInsights[value.toInt()];
                        final date = DateFormat('M/d').format(insight.periodEnd);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            date,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                ),
                gridData: const FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                    left: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: EmotionType.values.map((emotion) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getEmotionColor(emotion),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _getEmotionLabel(emotion),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.joy:
        return Colors.amber;
      case EmotionType.calm:
        return Colors.blue.shade300;
      case EmotionType.neutral:
        return Colors.grey;
      case EmotionType.sadness:
        return Colors.grey.shade600;
      case EmotionType.stress:
        return Colors.orange;
      case EmotionType.anger:
        return Colors.red;
      case EmotionType.fear:
        return Colors.purple;
      case EmotionType.excitement:
        return Colors.pink;
    }
  }

  String _getEmotionLabel(EmotionType emotion) {
    return emotion.toString().split('.').last;
  }
}
