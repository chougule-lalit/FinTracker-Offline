import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    // Logic to switch colors based on brightness using only available AppColors
    final bgColor = isDark ? AppColors.brandDark : AppColors.scaffoldBackground;
    final textColor = isDark ? AppColors.brandWhite : AppColors.primaryBlack;
    final cardColor = isDark ? const Color(0xFF252525) : AppColors.cardSurface;
    final iconColor = isDark ? AppColors.brandWhite : AppColors.brandDark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      
      // Typography: Poppins
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: iconColor),
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme (32px Radius)
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      // Elevated Button (Stadium Shape + Brand Red)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          shape: const StadiumBorder(), // Pill shape
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandDark, 
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(color: iconColor),
    );
  }
}