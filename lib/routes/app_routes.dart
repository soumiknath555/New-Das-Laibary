import 'package:flutter/cupertino.dart';
import 'package:new_das_laybary/drawer/add_page.dart';
import 'package:new_das_laybary/drawer/Drawer_page/drawer_page.dart';
import 'package:new_das_laybary/drawer/dashboard_page.dart';
import 'package:new_das_laybary/drawer/publication_page.dart';
import 'package:new_das_laybary/drawer/setting_page.dart';

class AppRoutes {
  static const DASHBOARD_PAGE = "/home";
  static const ADD_PAGE = "/addpage";
  static const SETTING_PAGE = "/setting";
  static const PUBLICATION_PAGE ="/publication_page";

  static const DRAWER_PAGE ="/drawer_page";


  static Map<String , Widget Function(BuildContext) > routes = {
    DASHBOARD_PAGE :(context) => DashboardPage(),
    ADD_PAGE : (context) => AddPage(),
    SETTING_PAGE :(context) => SettingPage(),
    PUBLICATION_PAGE : (context) => Publication_Page(),

    DRAWER_PAGE : (context) => DrawerPage(),
  };
}