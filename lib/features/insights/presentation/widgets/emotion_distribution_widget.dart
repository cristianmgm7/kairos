import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';

class EmotionDistributionWidget extends StatelessWidget {
  const EmotionDistributionWidget({
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
          child: Text('No emotion data available yet'),
        ),
      );
    }

    // Count emotions
    final emotionCounts = <EmotionType, int>{};
    for (final insight in insights) {
      emotionCounts[insight.dominantEmotion] = (emotionCounts[insight.dominantEmotion] ?? 0) + 1;
    }

    final total = insights.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Emotion Distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sections: emotionCounts.entries.map((entry) {
                      final percentage = (entry.value / total * 100);
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '${percentage.toStringAsFixed(0)}%',
                        color: _getEmotionColor(entry.key),
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: emotionCounts.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getEmotionColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _getEmotionLabel(entry.key),
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
