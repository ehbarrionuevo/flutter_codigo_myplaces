
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myplaces/pages/home_page.dart';
import 'package:myplaces/pages/permission_page.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "My Places",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.manropeTextTheme(),
      ),
      home: PermissionPage(),
    );
  }
}
