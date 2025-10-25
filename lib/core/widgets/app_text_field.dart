import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  // constructor
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.onEditingComplete,
    this.onSubmitted,
    super.key,
  });

  // properties
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      onTap: onTap,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
