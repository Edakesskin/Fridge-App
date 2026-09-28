import 'package:flutter/material.dart';

class AppColors {
  // pink
  static const Color mypink = Color(0xFFC6286B);
  
  //green
  static const Color mygreen = Color(0xFF97CC66);
  
  //blue
  static const Color myblue = Color (0xFF0A315C);
  
  // Optional: Helper for theme
  static ThemeData get theme {
    return ThemeData(
      primaryColor: mypink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mypink,
        primary: mypink,
        secondary: mygreen,
      ),
    );
  }
}