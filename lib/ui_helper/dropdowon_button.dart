import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class SnDropdown extends StatelessWidget {
  final List<String> items;
  final String? value;
  final String hintText;
  final ValueChanged<String?> onChanged;

   SnDropdown({
    Key? key,
    required this.items,
    required this.value,
    required this.hintText,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          hintText,
          style: const TextStyle(fontSize: 14),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        ))
            .toList(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 50,
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black45, // ✅ Outline border color
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blueAccent, // ✅ Dropdown box border color
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
        ),
      ),
    );
  }
}
