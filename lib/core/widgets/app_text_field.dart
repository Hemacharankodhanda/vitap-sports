/// VIT-AP Sports — AppTextField widget.
///
/// Component specification:
/// - Stacked label: label above field (Callout / w500, textSecondary), 8 px gap.
/// - Field: height 48, radius 8, 1 px borderStrong, surface fill, 12 px horizontal padding.
/// - Focus: 2 px accent border. Error: 1 px negative border plus error text.
/// - Search variant: height 48, radius 12, filled with 6% textPrimary, no border, 20 px leading icon.
/// - Tabular figures on numeric inputs.
library;

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.onTap,
    this.focusNode,
    this.isSearch = false,
    this.onClear,
  });

  /// Factory constructor for search field per spec: radius 12, 6% fill, no border
  const AppTextField.search({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.onTap,
    this.focusNode,
    this.onClear,
  })  : label = null,
        errorText = null,
        helperText = null,
        prefixIcon = Icons.search_rounded,
        suffixIcon = null,
        validator = null,
        keyboardType = TextInputType.text,
        textInputAction = TextInputAction.search,
        inputFormatters = null,
        obscureText = false,
        readOnly = false,
        maxLines = 1,
        maxLength = null,
        enabled = true,
        isSearch = true;

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool isSearch;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isNumber = keyboardType == TextInputType.number ||
        keyboardType == TextInputType.phone;

    final textStyle = AppTypography.body.copyWith(
      color: enabled ? colors.textPrimary : colors.textPrimary.withAlpha((AppColors.overlayDisabledContent * 255).round()),
      fontFeatures: isNumber ? const [FontFeature.tabularFigures()] : null,
    );

    if (isSearch) {
      return SizedBox(
        height: 48,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          enabled: enabled,
          onTap: onTap,
          focusNode: focusNode,
          style: textStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: colors.textSecondary),
            filled: true,
            fillColor: colors.textPrimary.withAlpha(15), // 6% tint
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.accent, width: 2),
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            prefixIconColor: colors.textSecondary,
            suffixIcon: (controller?.text.isNotEmpty == true && onClear != null)
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: colors.textSecondary,
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.callout.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          enabled: enabled,
          onTap: onTap,
          focusNode: focusNode,
          style: textStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: colors.textSecondary),
            errorText: errorText,
            helperText: helperText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            prefixIconColor: colors.textSecondary,
            suffixIcon: suffixIcon,
            counterText: '',
            filled: true,
            fillColor: enabled
                ? colors.surface
                : colors.surfaceVariant.withAlpha((AppColors.overlayDisabledContainer * 255).round()),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderStrong, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderStrong, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.loss, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.loss, width: 2),
            ),
            errorStyle: AppTypography.caption.copyWith(color: colors.loss),
            helperStyle: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
