import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_das_laybary/firebase_options.dart';
import 'package:new_das_laybary/routes/app_routes.dart';

void main () async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          textTheme: GoogleFonts.notoSansTextTheme(),
        useMaterial3: false, // 👈 এটা যোগ করো
      ),
      initialRoute: AppRoutes.DRAWER_PAGE,
      routes: AppRoutes.routes,
    );
  }
}