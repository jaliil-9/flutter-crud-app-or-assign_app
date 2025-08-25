import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.black, fontSize: 20.0),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 14.0),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontSize: 20.0),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14.0),
    ),
  );
}
