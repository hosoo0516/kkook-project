import 'package:flutter/material.dart';

import '../theme/kkook_theme.dart';

class KkookLabeledField extends StatelessWidget {
  const KkookLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.helperText,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? helperText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(fontSize: 12, color: KkookColors.hint),
          ),
        ],
      ],
    );
  }
}
