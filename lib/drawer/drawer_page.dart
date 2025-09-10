import 'package:flutter/material.dart';
import 'package:new_das_laybary/drawer/add_page.dart';
import 'package:new_das_laybary/drawer/home_page.dart';
import 'package:new_das_laybary/drawer/setting_page.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  int selectedIndex = 1 ;

  List<Widget> drawerPage = [
    HomePage(),
    AddPage(),
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
              child: Text("New Das Laybary"),
              decoration: BoxDecoration(color: Colors.blueAccent),

            ),
            ListTile(
              title: Text("Home Page"),
              onTap: ()=> onItemTapped(0),
            ),
            ListTile(
              title: Text("Add Page"),
              onTap: ()=> onItemTapped(1),
            ),
            ListTile(
              title: Text("Setting Page"),
              onTap: ()=> onItemTapped(2),
            )
          ],
        ),
      ),

      body: drawerPage[selectedIndex],
    );
  }
}
