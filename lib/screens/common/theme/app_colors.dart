import 'package:flutter/material.dart';

class AppColors {
 //Light Mode
  static const Color primaryLight = Color(
    0xFFF7F8FA,
  ); // fondo principal gris tenue
  static const Color onPrimaryLight = Color.fromARGB(255, 30, 30, 30); // texto principal suave

  static const Color surfaceLight = Color(
    0xFFF2F4F6,
  ); // cards, backgrounds secundarios
  static const Color onSurfaceLight = Color.fromARGB(255, 90, 90, 90); // texto en cards
  static const Color onSurfaceVariantLight =  Color.fromARGB(167, 213, 213, 213); // bordes suaves

  static const Color secondaryLight = Color(0xFFAEDFD8); // acento pastel suave
  static const Color onSecondaryLight = Color(0xFF1A2F40); // texto sobre acento

  //Dark Mode (sin cambios porque ya se ve bien)
  static const Color primaryDark = Color.fromRGBO(0, 0, 0, 0.682);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);

  static const Color surfaceDark = Color(0xFF282828);
  static const Color onSurfaceDark = Color(0xFFFBFBFB);
  static const Color onSurfaceVariantDark =  Color.fromARGB(34, 121, 121, 121);

  static const Color secondaryDark = Color(0xFF425767);
  static const Color onSecondaryDark = Color(0xFFFFFFFF);
}
