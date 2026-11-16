/// VIT-AP Sports — AppTextField widget (Apple Design System).
///
/// Component specification:
/// - Surface fill (#F5F5F7 / #1C1C1E), radius 14, height 52.
/// - Borderless at rest, 1.5 px textPrimary border on focus.
/// - 1 px loss border plus error text on validation failure.
/// - Stacked label above field (Callout w500, textSecondary), 8 px gap.
/// - Helper/error text below (Footnote).
/// - Search variant: height 48, radius 14, 6% fillSecondary / surface fill, leading search icon.
/// - Tabular figures on numeric inputs.
library;

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

  /// Factory constructor for search field: height 48, radius 14, leading search icon
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
      color: enabled
          ? colors.textPrimary
          : colors.textPrimary.withAlpha((AppColors.overlayDisabledContent * 255).round()),
      fontFeatures: isNumber ? const [FontFeature.tabularFigures()] : null,
    );

    final inputRadius = BorderRadius.circular(AppSpacing.radiusInput);

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
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
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
            helperStyle: AppTypography.footnote.copyWith(color: colors.textSecondary),
            errorStyle: AppTypography.footnote.copyWith(color: colors.loss),
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide(color: colors.loss, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide(color: colors.loss, width: 1.5),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: colors.textSecondary)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
