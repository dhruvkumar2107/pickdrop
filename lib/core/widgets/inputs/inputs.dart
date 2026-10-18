import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/colors.dart';
import '../../constants/dimensions.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingMd,
            ),
        counterText: '',
      ),
    );
  }
}

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      enabled: enabled,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            if (value.length != 10) {
              return 'Enter a valid 10-digit phone number';
            }
            return null;
          },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: AppDimensions.spacingMd, right: AppDimensions.spacingSm),
        child: const Text(
          '+91 ',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class OtpInputField extends StatelessWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final Duration? autoFocusDelay;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? selectedColor;

  const OtpInputField({
    super.key,
    this.length = 4,
    this.onCompleted,
    this.onChanged,
    this.autoFocusDelay,
    this.enabled = true,
    this.activeColor,
    this.inactiveColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(length, (index) {
        return SizedBox(
          width: 56,
          height: 56,
          child: TextFormField(
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(
                  color: inactiveColor ?? AppColors.outline,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(
                  color: inactiveColor ?? AppColors.outline,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(
                  color: activeColor ?? AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < length - 1) {
                  FocusScope.of(context).nextFocus();
                } else {
                  FocusScope.of(context).unfocus();
                }
              }
              onChanged?.call(value);
            },
            onSaved: (value) {
              // Handled by onChanged
            },
          ),
        );
      }),
    );
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool readOnly;
  final bool autofocus;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const SearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onTap,
    this.onClear,
    this.readOnly = false,
    this.autofocus = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: onChanged,
      onTap: onTap,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint ?? 'Search...',
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: AppColors.onSurfaceVariant,
        ),
        prefixIcon: leadingIcon ??
            const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: AppDimensions.iconMd),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.onSurfaceVariant),
                onPressed: () {
                  controller!.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
              )
            : trailingIcon,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class DropdownField<T> extends StatelessWidget {
  final T? value;
  final String? label;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final String? errorText;

  const DropdownField({
    super.key,
    this.value,
    this.label,
    this.hint,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
      ),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: AppColors.onSurface,
      ),
      dropdownColor: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.onSurfaceVariant),
      selectedItemBuilder: (context) => items.map((item) {
        return Text(
          (item.child as Text).data ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppColors.onSurface,
          ),
        );
      }).toList(),
    );
  }
}

class MultilineTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final FocusNode? focusNode;

  const MultilineTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.maxLines = 4,
    this.minLines = 3,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
    );
  }
}