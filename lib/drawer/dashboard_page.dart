import 'package:flutter/material.dart';
import 'package:new_das_laybary/drawer/add_page.dart';
import 'package:new_das_laybary/ui_helper/text_field.dart';
import 'package:new_das_laybary/ui_helper/text_style.dart';
import 'package:new_das_laybary/ui_helper/ui_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  TextEditingController controller = TextEditingController();


  @override
  Widget build(BuildContext context) {

    final List<Map<String , dynamic>> dashboardItems = [
      {
        "title" : "Total Orders",
        "value" : 78 ,
        "icon" : Icons.list_alt_rounded,
        "color" : Colors.red
      },
      {
        "title" : "Total Coustomer",
        "value" : 78 ,
        "icon" : Icons.list_alt_rounded,
        "color" : Colors.red
      },
      {
        "title" : "Total Student",
        "value" : 78 ,
        "icon" : Icons.list_alt_rounded,
        "color" : Colors.red
      },
      {
        "title" : "Total Teacher",
        "value" : 78 ,
        "icon" : Icons.list_alt_rounded,
        "color" : Colors.red
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.BLACK_9,
      appBar: AppBar(
        backgroundColor: AppColors.BLACK_9,
        title: Text("Dashboard Page", style: snTextStyle25Bold(color: AppColors.WHITE_9)),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: GridView.builder(
            itemCount: dashboardItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
            childAspectRatio: 8/1
        ),
            itemBuilder: (context , index){
              final item = dashboardItems[index];
              return DashboardCard(title: item["title"],
                  value: item["value"].toString(),
                  icon: item["icon"],
                  color: item["color"]);
            }),
      )
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.BLACK_7,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            /*BoxShadow(
              color: Colors.grey,
              spreadRadius: 3,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),*/
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            bottom: 10,
            left: 30,
            right: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Order ",
                      style: snTextStyle20Bold(
                        color: Colors.green,
                      ),
                    ),
                    Text("78", style: snTextStyle20()),
                  ],
                ),
              ),
              Icon(Icons.list_alt_sharp, size: 30,color: AppColors.WHITE_9,),
            ],
          ),
        ),
    );

  }

}
