import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:provider/provider.dart';
import 'package:shop/order_history/order_history.dart';
import 'package:shop/screens/favourites.dart';
import 'package:shop/screens/mainscreen.dart';
import 'package:shop/screens/splash_screen.dart';
import 'Providers/cart_provider.dart';
import 'cart_screens/cart.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // final Cart cart = Cart();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FavouriteProductPageProvider>(
          create: (_) => FavouriteProductPageProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<Cart>(
          create: (_) => Cart(),
        ),

        // Add other providers here if needed
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 804),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(

            theme: ThemeData(
              scaffoldBackgroundColor:  Colors.blueGrey,
              primarySwatch: Colors.blueGrey,
              // accentColor: Colors.pink,
              inputDecorationTheme: const InputDecorationTheme(
                // enabledBorder: OutlineInputBorder(
                //   borderSide: BorderSide(width: 1, color: Color(0xffffa7a6)),
                //   borderRadius: BorderRadius.all(Radius.circular(20)),
                // ),
                // focusedBorder: OutlineInputBorder(
                //   borderSide: BorderSide(width: 1, color: Color(0xffffa7a6)),
                //   borderRadius: BorderRadius.all(Radius.circular(20)),
                // ),
              ),
            ),
            home: OrderHistoryScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
