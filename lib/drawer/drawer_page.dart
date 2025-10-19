import 'package:flutter/material.dart';
import 'package:new_das_laybary/drawer/add_page.dart';
import 'package:new_das_laybary/drawer/class_page.dart';
import 'package:new_das_laybary/drawer/books_type.dart';
import 'package:new_das_laybary/drawer/dashboard_page.dart';
import 'package:new_das_laybary/drawer/publication_page.dart';
import 'package:new_das_laybary/drawer/School_Name/school_name.dart';
import 'package:new_das_laybary/drawer/setting_page.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';
import 'package:new_das_laybary/ui_helper/ui_colors.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  int selectedIndex = 4 ;

  List<Widget> drawerPage = [
    DashboardPage(),
    AddPage(),
    Publication_Page(),
    BooksType(),
    ClassNamePage(),
    SchoolNamePage(),
    SettingPage(),
  ] ;


 void onItemTapped(int Index) {
    setState(() {
      selectedIndex = Index ;
    });
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Das Laybary",
          style: snTextStyle20Bold(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text("New Das Laybary", style: snTextStyle20Bold(color: AppColors.WHITE_9),),
              decoration: BoxDecoration(color: AppColors.BLACK_9),
            ),
            ListTile(
              title: Text("Dashboard Page"),
              onTap: ()=> onItemTapped(0),
            ),
            ListTile(
              title: Text("Add Page"),
              onTap: ()=> onItemTapped(1),
            ),

            ListTile(title: Text("Publication"),
              onTap: () => onItemTapped(2),
            ),

            ListTile(title: Text("Books Type"),
              onTap: () => onItemTapped(3),
            ),

            ListTile(
              title: Text("Add Class"),
              onTap: ()=> onItemTapped(4),
            ),
            ListTile(
              title: Text("Add School Name"),
              onTap: ()=> onItemTapped(5),
            ),
            ListTile(
              title: Text("Setting Page"),
              onTap: ()=> onItemTapped(16),
            ),

          ],
        ),
      ),

      body: drawerPage[selectedIndex],
    );
  }
}
