import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_das_laybary/routes/app_routes.dart';

void main (){

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.notoSansTextTheme()),
      initialRoute: AppRoutes.DRAWER_PAGE,
      routes: AppRoutes.routes,
    );
  }
}