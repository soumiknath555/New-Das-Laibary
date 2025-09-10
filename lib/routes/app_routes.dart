import 'package:flutter/cupertino.dart';
import 'package:new_das_laybary/drawer/add_page.dart';
import 'package:new_das_laybary/drawer/drawer_page.dart';
import 'package:new_das_laybary/drawer/home_page.dart';
import 'package:new_das_laybary/drawer/setting_page.dart';

class AppRoutes {
  static const HOME_PAGE = "/home";
  static const ADD_PAGE = "/addpage";
  static const SETTING_PAGE = "/setting";

  static const DRAWER_PAGE ="/drawer_page";


  static Map<String , Widget Function(BuildContext) > routes = {
    HOME_PAGE :(context) => HomePage(),
    ADD_PAGE : (context) => AddPage(),
    SETTING_PAGE :(context) => SettingPage(),

    DRAWER_PAGE : (context) => DrawerPage(),
  };
}