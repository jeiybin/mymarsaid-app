import 'package:flutter/material.dart';

class AppTheme {

  static ThemeData lightTheme =
      ThemeData(

    useMaterial3: true,

    fontFamily: 'Poppins',

    // BACKGROUND
    scaffoldBackgroundColor:
        Color(0xFFFFF8EC),

    // WARNA UTAMA
    primaryColor:
        Color(0xFF99AD7A),

    colorScheme: ColorScheme.light(

      primary:
          Color(0xFF99AD7A),

      secondary:
          Color(0xFF99AD7A),
    ),

    // APPBAR
    appBarTheme: AppBarTheme(

      backgroundColor:
          Color(0xFF99AD7A),

      foregroundColor:
          Colors.white,

      elevation: 0,
    ),

    // FLOATING BUTTON
    floatingActionButtonTheme:
        FloatingActionButtonThemeData(

      backgroundColor:
          Color(0xFF99AD7A),

      foregroundColor:
          Colors.white,
    ),

    // DRAWER
    drawerTheme: DrawerThemeData(

      backgroundColor:
          Color(0xFFFFF8EC),
    ),

    // CARD
    cardTheme: CardThemeData(

      color: Colors.white,

      elevation: 2,

      shape: RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(20),
      ),
    ),

    // INPUT
    inputDecorationTheme:
        InputDecorationTheme(

      filled: true,

      fillColor: Colors.white,

      contentPadding:
          EdgeInsets.symmetric(

        horizontal: 20,
        vertical: 16,
      ),

      border: OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide(

          color:
              Color(0xFF99AD7A),
        ),
      ),
    ),
  );
}