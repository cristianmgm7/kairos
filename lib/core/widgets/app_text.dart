import 'package:flutter/material.dart';

enum AppTextStyle {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

class AppText extends StatelessWidget {
  // constructor
  const AppText(
    this.text, {
    this.style = AppTextStyle.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    super.key,
  });

  // Named constructors for common use cases
  const AppText.displayLarge(
    this.text, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    super.key,
  }) : style = AppTextStyle.displayLarge;

  const AppText.headlineMedium(
    this.text, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    super.key,
  }) : style = AppTextStyle.headlineMedium;

  const AppText.titleLarge(
    this.text, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    super.key,
  }) : style = AppTextStyle.titleLarge;

  const AppText.bodyLarge(
    this.text, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    super.key,
  }) : style = AppTextStyle.bodyLarge;

  const AppText.bodyMedium(
    this.text, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    super.key,
  }) : style = AppTextStyle.bodyMedium;

  const AppText.labelLarge(
    this.text, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    super.key,
  }) : style = AppTextStyle.labelLarge;

  // properties
  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final baseStyle = switch (style) {
      AppTextStyle.displayLarge => textTheme.displayLarge,
      AppTextStyle.displayMedium => textTheme.displayMedium,
      AppTextStyle.displaySmall => textTheme.displaySmall,
      AppTextStyle.headlineLarge => textTheme.headlineLarge,
      AppTextStyle.headlineMedium => textTheme.headlineMedium,
      AppTextStyle.headlineSmall => textTheme.headlineSmall,
      AppTextStyle.titleLarge => textTheme.titleLarge,
      AppTextStyle.titleMedium => textTheme.titleMedium,
      AppTextStyle.titleSmall => textTheme.titleSmall,
      AppTextStyle.bodyLarge => textTheme.bodyLarge,
      AppTextStyle.bodyMedium => textTheme.bodyMedium,
      AppTextStyle.bodySmall => textTheme.bodySmall,
      AppTextStyle.labelLarge => textTheme.labelLarge,
      AppTextStyle.labelMedium => textTheme.labelMedium,
      AppTextStyle.labelSmall => textTheme.labelSmall,
    };

    return Text(
      text,
      style: baseStyle?.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
