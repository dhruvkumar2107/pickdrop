import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';

/// A premium input field with consistent styling
class PDInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputFormatter? inputFormatter;

  const PDInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onTap,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.focusNode,
    this.autofocus = false,
    this.inputFormatter,
  });

  @override
  State<PDInput> createState() => _PDInputState();
}

class _PDInputState extends State<PDInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TokenTextStyles.labelMedium(
              color: colors.onSurface,
              weight: DesignTokens.wMedium,
            ),
          ),
          SizedBox(height: DesignTokens.space2),
        ],
        Material(
          color: Colors.transparent,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            validator: widget.validator,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            textCapitalization: widget.textCapitalization,
            autofocus: widget.autofocus,
            inputFormatters: widget.inputFormatter != null ? [widget.inputFormatter!] : null,
            style: TokenTextStyles.bodyMedium(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TokenTextStyles.bodyMedium(
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              helperText: widget.helperText,
              helperStyle: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
              errorText: widget.errorText,
              errorStyle: TokenTextStyles.bodySmall(color: colors.error),
              errorMaxLines: 3,
              counterText: '',
              filled: true,
              fillColor: widget.enabled 
                  ? (_isFocused ? colors.surface : colors.surfaceVariant.withValues(alpha: 0.5))
                  : colors.surfaceVariant.withValues(alpha: 0.3),
              contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingMd,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: DesignTokens.spacingMd,
                        right: DesignTokens.spacingSm,
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: _isFocused ? colors.primary : colors.onSurfaceVariant,
                          size: DesignTokens.iconMd,
                        ),
                        child: widget.prefixIcon!,
                      ),
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              prefix: widget.prefix,
              suffix: widget.suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.outline, width: DesignTokens.borderThin),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.outline, width: DesignTokens.borderThin),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.primary, width: DesignTokens.borderFocus),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.error, width: DesignTokens.borderFocus),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.error, width: DesignTokens.borderFocus),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.5),
                  width: DesignTokens.borderThin,
                ),
              ),
              labelStyle: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

/// A premium select/dropdown field
class PDSelect<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final T? value;
  final List<PDSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final EdgeInsetsGeometry? contentPadding;

  const PDSelect({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    required this.value,
    required this.options,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.contentPadding,
  });

  @override
  State<PDSelect<T>> createState() => _PDSelectState<T>();
}

class _PDSelectState<T> extends State<PDSelect<T>> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TokenTextStyles.labelMedium(
              color: colors.onSurface,
              weight: DesignTokens.wMedium,
            ),
          ),
          SizedBox(height: DesignTokens.space2),
        ],
        Material(
          color: Colors.transparent,
          child: DropdownButtonFormField<T>(
            focusNode: _focusNode,
            initialValue: widget.value,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TokenTextStyles.bodyMedium(
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              helperText: widget.helperText,
              helperStyle: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
              errorText: widget.errorText,
              errorStyle: TokenTextStyles.bodySmall(color: colors.error),
              errorMaxLines: 3,
              filled: true,
              fillColor: widget.enabled
                  ? (_isFocused ? colors.surface : colors.surfaceVariant.withValues(alpha: 0.5))
                  : colors.surfaceVariant.withValues(alpha: 0.3),
              contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingMd,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: DesignTokens.spacingMd,
                        right: DesignTokens.spacingSm,
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: _isFocused ? colors.primary : colors.onSurfaceVariant,
                          size: DesignTokens.iconMd,
                        ),
                        child: widget.prefixIcon!,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.outline, width: DesignTokens.borderThin),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.outline, width: DesignTokens.borderThin),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.primary, width: DesignTokens.borderFocus),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.error, width: DesignTokens.borderFocus),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(color: colors.error, width: DesignTokens.borderFocus),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.5),
                  width: DesignTokens.borderThin,
                ),
              ),
            ),
            items: widget.options.map((option) {
              return DropdownMenuItem<T>(
                value: option.value,
                child: Text(
                  option.label,
                  style: TokenTextStyles.bodyMedium(color: colors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: widget.enabled ? widget.onChanged : null,
            validator: widget.validator,
            style: TokenTextStyles.bodyMedium(color: colors.onSurface),
            dropdownColor: colors.surfaceCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _isFocused ? colors.primary : colors.onSurfaceVariant,
            ),
            selectedItemBuilder: (context) {
              return widget.options.map((option) {
                return Text(
                  option.label,
                  style: TokenTextStyles.bodyMedium(color: colors.onSurface),
                  overflow: TextOverflow.ellipsis,
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }
}

class PDSelectOption<T> {
  final T value;
  final String label;
  final String? description;
  final Widget? leading;
  final Widget? trailing;

  const PDSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.leading,
    this.trailing,
  });
}