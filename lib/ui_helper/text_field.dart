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
      style: const TextStyle(
        color: Colors.white, // 🔸 Text color white
      ),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        hintStyle: const TextStyle(
          color: Colors.lightBlue, // 🔹 Hint color light blue
        ),
        labelStyle: const TextStyle(
          color: Colors.lightBlue, // 🔹 Label color light blue
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color ?? Colors.white60),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color ?? Colors.lightBlue),
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
