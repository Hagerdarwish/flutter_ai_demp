import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // --- Display ---
  static TextStyle displayLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: _textPrimary(context));

  static TextStyle displayMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w400, color: _textPrimary(context));

  // --- Headline ---
  static TextStyle headlineLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: _textPrimary(context));

  static TextStyle headlineMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.25, color: _textPrimary(context));

  static TextStyle headlineSmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary(context));

  // --- Title ---
  static TextStyle titleLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.15, color: _textPrimary(context));

  static TextStyle titleMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: _textPrimary(context));

  static TextStyle titleSmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary(context));

  // --- Body ---
  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: _textPrimary(context));

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: _textSecondary(context));

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: _textSecondary(context));

  // --- Label ---
  static TextStyle labelLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: _textPrimary(context));

  static TextStyle labelMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: _textSecondary(context));

  static TextStyle labelSmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: _textSecondary(context));

  // --- Helpers ---
  static Color _textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  static Color _textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
}
