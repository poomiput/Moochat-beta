import 'package:flutter/material.dart';

class ColorsManager {
  // === DARK THEME (Charcoal/Graphite Range) ===
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkElevated = Color(0xFF333333);
  static const Color darkAccent = Color(0xFF444444);

  // === LIGHT THEME (Soft Grey Range) ===
  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color lightSurface = Color(0xFFE9E9E9);
  static const Color lightCard = Color(0xFFD8D8D8);
  static const Color lightElevated = Color(0xFFC8C8C8);
  static const Color lightAccent = Color(0xFFBBBBBB);

  // === THEME SELECTION (Dark by default) ===
  static const bool isDarkMode = true;
  static Color get backgroundColor =>
      isDarkMode ? darkBackground : lightBackground;
  static Color get surfaceColor => isDarkMode ? darkSurface : lightSurface;
  static Color get cardColor => isDarkMode ? darkCard : lightCard;
  static Color get elevatedColor => isDarkMode ? darkElevated : lightElevated;
  static Color get accentColor => isDarkMode ? darkAccent : lightAccent;

  // === TYPOGRAPHY HIERARCHY ===
  static Color get titleText =>
      isDarkMode ? const Color(0xFFF8F8F8) : const Color(0xFF1A1A1A);
  static Color get subtitleText =>
      isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF2A2A2A);
  static Color get bodyText =>
      isDarkMode ? const Color(0xFFD0D0D0) : const Color(0xFF404040);
  static Color get captionText =>
      isDarkMode ? const Color(0xFF999999) : const Color(0xFF666666);
  static Color get mutedText =>
      isDarkMode ? const Color(0xFF707070) : const Color(0xFF888888);

  // === BORDERS & DIVIDERS ===
  static Color get strokeColor =>
      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFD0D0D0);
  static Color get dividerColor =>
      isDarkMode ? const Color(0xFF222222) : const Color(0xFFE0E0E0);
  static Color get subtleBorder =>
      isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFEEEEEE);

  // === INTERACTIVE STATES ===
  static Color get interactiveNormal =>
      isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFCCCCCC);
  static Color get interactiveHover =>
      isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFBBBBBB);
  static Color get interactivePressed =>
      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFDDDDDD);

  // === FUNCTIONAL COLORS (Minimal) ===
  static Color get unreadIndicator =>
      isDarkMode ? const Color(0xFF666666) : const Color(0xFF999999);
  static Color get connectionStrength =>
      isDarkMode ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
  static Color get typingIndicator =>
      isDarkMode ? const Color(0xFF404040) : const Color(0xFFCCCCCC);

  // === ADDITIONAL UI COLORS ===
  static Color get primaryColor =>
      isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF4A90E2);
  static Color get shadowColor => const Color(0xFF000000);
  static Color get avatarBackground =>
      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

  // Additional interactive colors for compatibility
  static Color get interactiveGrey => interactiveNormal;
  static Color get hoverGrey => interactiveHover;

  // === LEGACY COMPATIBILITY ===
  static const Color mainColor = Color(0xFF666666);
  static const Color primaryText = Color(0xFFE0E0E0);
  static const Color secondaryText = Color(0xFFD0D0D0);
  static const Color tertiaryText = Color(0xFF999999);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color grayColor = Color(0xFF999999);
  static const Color customGray = Color(0xFF444444);
  static const Color borderColor = Color(0xFF2A2A2A);

  // Semantic colors (monochrome)
  static const Color customRed = Color(0xFF666666);
  static const Color customOrange = Color(0xFF666666);
  static const Color customBlue = Color(0xFF666666);
  static const Color customGreen = Color(0xFF666666);
  static const Color successColor = Color(0xFF666666);
  static const Color warningColor = Color(0xFF666666);
  static const Color errorColor = Color(0xFF666666);
  static const Color infoColor = Color(0xFF666666);
}
