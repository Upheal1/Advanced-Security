import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.validator,
    this.autofillHints,
    this.semanticLabel,
    this.semanticHint,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final String? semanticLabel;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Semantics(
      textField: true,
      enabled: enabled,
      label: semanticLabel ?? label ?? hint,
      hint: semanticHint ?? errorText ?? helper ?? hint,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        constraints: const BoxConstraints(minHeight: AppComponentSizes.inputMinHeight),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(
            alpha: isDark ? AppEffects.glassSurfaceAlphaDark : AppEffects.glassHighlightAlphaLight,
          ),
          borderRadius: AppRadius.md,
          boxShadow: theme.appShadows.soft,
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autofillHints: autofillHints,
          keyboardAppearance: theme.brightness,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintMaxLines: 2,
            helperText: helper,
            helperMaxLines: 3,
            errorText: errorText,
            errorMaxLines: 3,
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                    child: prefixIcon,
                  ),
            suffixIcon: suffixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                    child: suffixIcon,
                  ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: AppComponentSizes.buttonHeight,
              minHeight: AppComponentSizes.buttonHeight,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: AppComponentSizes.buttonHeight,
              minHeight: AppComponentSizes.buttonHeight,
            ),
            filled: true,
            fillColor: scheme.surface.withValues(alpha: 0.01),
          ),
        ),
      ),
    );
  }
}
