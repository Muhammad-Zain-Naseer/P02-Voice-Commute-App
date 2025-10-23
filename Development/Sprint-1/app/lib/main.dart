import 'package:flutter/material.dart';
import "./screens/home/new_home_page.dart";

void main() {
  runApp(const HerSafarApp());
}

class HerSafarApp extends StatelessWidget {
  const HerSafarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HerSafar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF6C63FF),
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NewHomePage(),
    );
  }
}