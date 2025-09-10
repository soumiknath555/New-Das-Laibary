import 'package:flutter/material.dart';

Widget snTextField({
  required String hint,
  required TextEditingController controller,
  String label = '',
  bool obscureText = false,
  Color? color,
  Icon? prefixIcon,
  Icon? suffixIcon,

  // 🔹 New Parameters
  ValueChanged<String>? onChanged,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
}) =>
    TextField(
      obscureText: obscureText,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color ?? Colors.black45),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color ?? Colors.lightBlue),
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
