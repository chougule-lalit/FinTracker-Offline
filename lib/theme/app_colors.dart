import 'package:flutter/material.dart';

class AppColors {
  // --- NEW DESIGN TOKENS (From Screenshots) ---
  static const Color brandRed = Color(0xFFF63C3A); 
  static const Color brandDark = Color(0xFF191908); 
  static const Color brandBeige = Color(0xFFD6D4CE); 
  static const Color brandWhite = Color(0xFFFFFFFF);

  // --- MAPPING OLD NAMES TO NEW DESIGN (Fixes Lint Errors) ---
  
  // Backgrounds
  static const Color scaffoldBackground = brandBeige; // Was White
  static const Color cardSurface = brandWhite; // Was Light Grey
  static const Color surface = brandWhite; 
  
  // Text & Icons
  static const Color primaryBlack = brandDark; // Was #1C1C1E
  static const Color secondaryGrey = Color(0xFF8E8E93); // Kept same
  
  // Financials
  static const Color expenseRed = brandRed; // Updated to new Red
  static const Color incomeGreen = Color(0xFF32D74B); // Kept same
  
  // UI Elements
  static const Color brandPrimary = brandDark; // Buttons are now Dark
  static const Color divider = Color(0xFFE5E5EA);
}