import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'app_icon.dart';

/// Text input with the label above it.
///
/// Focused: 1.5px primary border plus a 4px primarySoft ring.
/// Error: 1.5px danger border and an inline message below.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.readOnly = false,
    this.height = 54,
    this.labelGap = 8,
    this.fill,
    this.prefix,
    this.leadingIcon,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final double height;
  final double labelGap;

  /// Background; defaults to surface.
  final Color? fill;

  /// Shown before the text, e.g. a "+218" country code.
  final Widget? prefix;
  final IconData? leadingIcon;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focus = FocusNode();
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasError = widget.errorText != null;
    final focused = _focus.hasFocus && !widget.readOnly;

    final Border border;
    if (hasError) {
      border = Border.all(color: c.danger, width: 1.5);
    } else if (focused) {
      border = Border.all(color: c.primary, width: 1.5);
    } else {
      border = Border.all(color: c.line);
    }

    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      padding: const EdgeInsetsDirectional.only(start: 16, end: 6),
      decoration: BoxDecoration(
        color: widget.fill ?? c.surface,
        borderRadius: BorderRadius.circular(14),
        border: border,
        boxShadow: focused && !hasError
            ? [BoxShadow(color: c.primarySoft, spreadRadius: 4)]
            : const [],
      ),
      child: Row(
        children: [
          if (widget.leadingIcon != null) ...[
            AppIcon(widget.leadingIcon!, size: 22, color: c.subtext),
            const SizedBox(width: 12),
          ],
          if (widget.prefix != null) widget.prefix!,
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              readOnly: widget.readOnly,
              obscureText: widget.isPassword && _obscured,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              onSubmitted: widget.onSubmitted,
              style: AppFonts.body(
                context,
                16,
                color: widget.readOnly ? c.subtext : c.text,
              ),
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: AppFonts.body(context, 16, color: c.subtext),
              ),
            ),
          ),
          if (widget.isPassword)
            IconButton(
              onPressed: () => setState(() => _obscured = !_obscured),
              icon: AppIcon(
                _obscured
                    ? Symbols.visibility_rounded
                    : Symbols.visibility_off_rounded,
                size: 22,
                color: c.subtext,
              ),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppFonts.body(
              context,
              14,
              weight: FontWeight.w600,
              color: c.text,
            ),
          ),
          SizedBox(height: widget.labelGap),
        ],
        field,
        if (hasError) ...[
          const SizedBox(height: 6),
          FieldError(message: widget.errorText!),
        ],
      ],
    );
  }
}

/// Inline error row: filled `error` icon and a short message in danger.
class FieldError extends StatelessWidget {
  const FieldError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: AppIcon(
            Symbols.error_rounded,
            size: 16,
            color: c.danger,
            filled: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: AppFonts.body(
              context,
              13,
              weight: FontWeight.w500,
              color: c.danger,
            ),
          ),
        ),
      ],
    );
  }
}
