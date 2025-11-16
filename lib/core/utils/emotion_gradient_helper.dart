import 'package:flutter/material.dart';
import 'package:kairos/features/insights/domain/value_objects/value_objects.dart';

class EmotionGradientHelper {
  /// Get gradient colors for an emotion
  static LinearGradient getGradientForEmotion(EmotionType emotion) {
    final colors = _getColorsForEmotion(emotion);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  /// Get solid color for emotion (fallback)
  static Color getColorForEmotion(EmotionType emotion) {
    return _getColorsForEmotion(emotion).first;
  }

  static List<Color> _getColorsForEmotion(EmotionType emotion) {
    return switch (emotion) {
      EmotionType.joy => [
          const Color(0xFFFFF176), // Light yellow
          const Color(0xFFFFD54F), // Amber
        ],
      EmotionType.calm => [
          const Color(0xFF81D4FA), // Light blue
          const Color(0xFF4FC3F7), // Sky blue
        ],
      EmotionType.neutral => [
          const Color(0xFFE0E0E0), // Light gray
          const Color(0xFFBDBDBD), // Gray
        ],
      EmotionType.sadness => [
          const Color(0xFF90CAF9), // Pale blue
          const Color(0xFF5C6BC0), // Indigo
        ],
      EmotionType.stress => [
          const Color(0xFFFFB74D), // Light orange
          const Color(0xFFFF9800), // Orange
        ],
      EmotionType.anger => [
          const Color(0xFFEF5350), // Light red
          const Color(0xFFD32F2F), // Red
        ],
      EmotionType.fear => [
          const Color(0xFFBA68C8), // Light purple
          const Color(0xFF8E24AA), // Purple
        ],
      EmotionType.excitement => [
          const Color(0xFFFF80AB), // Light pink
          const Color(0xFFF06292), // Pink
        ],
    };
  }

  /// Get readable text color for emotion background
  static Color getTextColorForEmotion(EmotionType emotion) {
    // Dark text for light emotions, light text for dark emotions
    return switch (emotion) {
      EmotionType.joy ||
      EmotionType.calm ||
      EmotionType.neutral ||
      EmotionType.excitement =>
        Colors.black87,
      EmotionType.sadness ||
      EmotionType.stress ||
      EmotionType.anger ||
      EmotionType.fear =>
        Colors.white,
    };
  }
}
