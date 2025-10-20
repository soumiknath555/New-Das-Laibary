import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_das_laybary/firebase_options.dart';
import 'package:new_das_laybary/routes/app_routes.dart';
import 'package:new_das_laybary/drawer/shop_page/bloc/shop_bloc.dart';
import 'package:new_das_laybary/drawer/shop_page/shop_repository.dart';
import 'package:new_das_laybary/ui_helper/ui_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repo = ShopRepository();
  await repo.init();

  runApp(MyApp(repo: repo));
}

class MyApp extends StatelessWidget {
  final ShopRepository repo;
  const MyApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ShopBloc>(
          create: (_) => ShopBloc(repo)..loadShops(),
        ),
        // চাইলে এখানে অন্য BlocProvider future এ যোগ করতে পারো
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.BLACK_7,
          textTheme: GoogleFonts.notoSansTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
          ),
        ),
        initialRoute: AppRoutes.DRAWER_PAGE,
        routes: AppRoutes.routes,
      ),
    );
  }
}
