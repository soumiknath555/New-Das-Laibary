import 'package:flutter/material.dart';
import 'package:new_das_laybary/drawer/add_page.dart';
import 'package:new_das_laybary/ui_helper/text_field.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(title: Text("Home Page",style: snTextStyle20Bold(),),centerTitle: true ,),

      body: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 20,right: 20,top: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [


                snTextField(hint: "Enter Your Name", controller: controller,),
                SizedBox(height: 5,),
                snTextField(hint: "Enter Your Email", controller: controller),
                SizedBox(height: 5,),
                snTextField(hint: "Enter Your Password", controller: controller),
                SizedBox(height: 5,),

                Row(
                  children: [
                    Expanded(child: snTextField(hint: "Enter Your Name", controller: controller,)),
                    SizedBox(width: 5,),
                    Expanded(child: snTextField(hint: "Enter Your Email", controller: controller)),
                    SizedBox(width:  5,),
                    Expanded(child: snTextField(hint: "Enter Your Password", controller: controller)),
                    SizedBox(width:  5,),
                  ],
                ),

                TextField(
                  decoration: InputDecoration(
                    hint: Text("Discount"),

                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)
                    )
                  ),
                )
              ],
            ),
          ),
        ),

      ),
    );
  }
}
