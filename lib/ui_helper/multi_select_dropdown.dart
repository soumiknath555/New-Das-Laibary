import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class SnMultiSelectDropdown<T> extends StatefulWidget {
  final List<MultiSelectItem> items;
  final String title;
  final Function(List<T>) onConfirm;
  final List<T>? initialValue;

  const SnMultiSelectDropdown({
    Key? key,
    required this.title,
    required this.items,
    required this.onConfirm,
    this.initialValue,
  }) : super(key: key);

  @override
  State<SnMultiSelectDropdown<T>> createState() =>
      _SnMultiSelectDropdownState<T>();
}

class _SnMultiSelectDropdownState<T> extends State<SnMultiSelectDropdown<T>> {
  List<T> selectedItems = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedItems = widget.initialValue ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return MultiSelectDialogField(
      items: widget.items,
      title: Text(widget.title),
      initialValue: selectedItems,
      selectedColor: Colors.green,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54 ,),
        borderRadius: BorderRadius.circular(10)
      ),
      buttonText: Text(widget.title),

      onConfirm: (value) {
        setState(() {
          selectedItems = value.cast<T>();
        });
        widget.onConfirm(value.cast<T>());
      },
    );
  }
}


class MultiSelectModel {
  final String name;
  final int id;

  MultiSelectModel({required this.name, required this.id});
}
