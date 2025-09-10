import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:new_das_laybary/ui_helper/text_field.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  TextEditingController brandControlar = TextEditingController();

  List<String> brandList = ["chaya", "roymartin", "prantik"];

  String? selectedBrand;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              value: selectedBrand,
              hint: Text("Brand",style: snTextStyle16(),),
              items: brandList.map((brand) => DropdownMenuItem(
                  value: brand,
                  child: Text(brand,style: snTextStyle16(),))).toList(),
              onChanged: (value){
                setState(() {
                  selectedBrand = value;
                });
              },
              buttonStyleData: ButtonStyleData(
                height: 50,
                width: double.infinity,
              ),
              dropdownStyleData: DropdownStyleData(
                width: double.infinity,
                maxHeight: 200,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40,
              ),
              dropdownSearchData: DropdownSearchData(
                searchController: brandControlar,
                 searchInnerWidgetHeight: 50,
                searchInnerWidget: Container(
                  child: snTextField(hint: "Brand Name" ,controller: brandControlar),
                ),
                searchMatchFn: (item , searchValue){
                  return item.value.toString().toLowerCase().contains(searchValue.toLowerCase());
                }
              ),
            ),
          ),
        ),
      ),
    );
  }
}
