import 'package:flutter/material.dart';

class SnButton extends StatelessWidget {
  final String? text;
  final Color? color;
  final VoidCallback onPressed;

  const SnButton({
    Key? key,
    required this.text,
    this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        )
      ),
      onPressed: onPressed,
      child: Text(text!, style: TextStyle(color: color ?? Colors.white ,fontSize: 16)),
    );
  }
}
