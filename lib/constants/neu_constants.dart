import 'package:flutter/material.dart';

class NeuConstants {
  static const Color primaryColor = Color(0xFFFF5C00);
  static const Color secondaryColor = Color(0xFF00FF94);
  static const Color backgroundColor = Color(0xFFFFF4E9);
  static const Color shadowColor = Colors.black;
  
  static BoxDecoration neuBrutalismBoxDecoration({
    Color? color,
    double offsetX = 4,
    double offsetY = 4,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      border: Border.all(
        color: Colors.black,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black,
          offset: Offset(offsetX, offsetY),
          blurRadius: 0,
        ),
      ],
    );
  }
  
  static ButtonStyle neuBrutalismButtonStyle({
    Color? color,
    EdgeInsetsGeometry? padding,
  }) {
    return ButtonStyle(
      padding: MaterialStateProperty.all(
        padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      backgroundColor: MaterialStateProperty.all(color ?? Colors.white),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      elevation: MaterialStateProperty.all(0),
      shadowColor: MaterialStateProperty.all(Colors.black),
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.black.withOpacity(0.1);
        }
        return null;
      }),
    );
  }

  static ThemeData neuBrutalismTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: neuBrutalismButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: neuBrutalismButtonStyle(),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
} 