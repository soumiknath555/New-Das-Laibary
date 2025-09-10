

import 'dart:ui';
import 'package:flutter/material.dart';


TextStyle snTextStyle16({
 Color? color,
  FontWeight? fontWeight,
}) => TextStyle(
  fontSize: 16,
  color:  color,
  fontWeight: fontWeight ?? FontWeight.normal,
);

TextStyle snTextStyle16Bold ({
  Color? color,
  FontWeight? fontWeight,
}) => TextStyle(
  fontSize: 16,
  fontWeight: fontWeight ?? FontWeight.bold,
  color: color,
);

TextStyle snTextStyle18({
  Color? color,
  FontWeight? fontWeight,
}) => TextStyle(
  fontSize: 18,
  color: color,
  fontWeight: fontWeight ?? FontWeight.normal,
);

TextStyle snTextStyle18Bold ({
  Color? color,
  FontWeight? fontWeight,
}) => TextStyle(
  fontSize: 18,
  color: color,
  fontWeight: fontWeight ?? FontWeight.bold
);

TextStyle snTextStyle20({
  Color? color,
  FontWeight? fontWeight,
}) => TextStyle(
  fontSize: 20,
  fontWeight: fontWeight ?? FontWeight.normal,
  color: color ,
);

TextStyle snTextStyle20Bold ({
  Color? color,
  FontWeight? fontWeight,
}) {
  return TextStyle(
  fontSize: 20,
  fontWeight: fontWeight ?? FontWeight.bold,
  color: color
);}


/*
// 🔹 Size 22
TextStyle mTextStyle22({
  Color color = Colors.black,
  FontWeight fontWeight = FontWeight.normal,
}) {
  return TextStyle(
    fontSize: 22,
    color: color,
    fontWeight: fontWeight,
  );
}

TextStyle mTextStyle22Bold({
  Color color = Colors.black,
}) {
  return TextStyle(
    fontSize: 22,
    color: color,
    fontWeight: FontWeight.bold,
  );
}*/
