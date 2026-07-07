import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TalyTextStyles {
  TalyTextStyles._();

  static TextStyle regular400({
    double? fontSize,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.manrope(
        fontWeight: FontWeight.w400,
        fontSize: fontSize,
        color: color,
        height: height,
        decoration: decoration,
      );

  static TextStyle medium500({
    double? fontSize,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.manrope(
        fontWeight: FontWeight.w500,
        fontSize: fontSize,
        color: color,
        height: height,
        decoration: decoration,
      );

  static TextStyle semiBold600({
    double? fontSize,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: color,
        height: height,
        decoration: decoration,
      );

  static TextStyle bold700({
    double? fontSize,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        color: color,
        height: height,
        decoration: decoration,
      );

  static TextStyle tabText({Color? color}) => GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: color,
      );

  static ThemeData applyToTheme(ThemeData base) =>
      base.copyWith(textTheme: GoogleFonts.manropeTextTheme(base.textTheme));
}
