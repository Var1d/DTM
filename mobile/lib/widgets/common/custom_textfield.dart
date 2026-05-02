import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final Widget? prefixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      maxLines:     maxLines,
      validator:    validator,
      decoration: InputDecoration(
        labelText:    label,
        prefixIcon:   prefixIcon,
        border:       OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled:       true,
        fillColor:    Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
