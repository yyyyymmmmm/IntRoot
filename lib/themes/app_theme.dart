import 'package:flutter/material.dart';

class AppTheme {
  // 亮色模式颜色
  // 主色调
  static const Color primaryColor = Color(0xFF2C9678);
  static const Color primaryLightColor = Color(0xFF5DB79F); // 主色浅色变体
  static const Color primaryDarkColor = Color(0xFF1A7559); // 主色深色变体
  static const Color accentColor = Color(0xFF47B995);
  
  // 背景色
  static const Color backgroundColor = Color(0xFFF5F4F7);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  
  // 文字颜色
  static const Color textPrimaryColor = Color(0xFF2D2F33);
  static const Color textSecondaryColor = Color(0xFF6C6E72);
  static const Color textTertiaryColor = Color(0xFF9EA1A7);
  
  // 辅助颜色
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color warningColor = Color(0xFFFFB74D);
  
  // 深色模式颜色
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF252525);
  static const Color darkDividerColor = Color(0xFF2C2C2C);
  static const Color darkTextPrimaryColor = Color(0xFFFAFAFA);
  static const Color darkTextSecondaryColor = Color(0xFFD0D0D0);
  static const Color darkTextTertiaryColor = Color(0xFFAAAAAA);
  
  // 卡片阴影
  static List<BoxShadow> neuCardShadow({Color? shadowColor, bool isDark = false}) => [
    BoxShadow(
      color: (shadowColor ?? (isDark ? Colors.black : Colors.black)).withOpacity(isDark ? 0.3 : 0.05),
      offset: const Offset(2, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    if (!isDark) BoxShadow(
      color: (shadowColor ?? Colors.white).withOpacity(0.05),
      offset: const Offset(-2, -2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  // 拟态按钮阴影
  static List<BoxShadow> neuButtonShadow({bool isPressed = false, bool isDark = false}) => [
    BoxShadow(
      color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.4 : (isPressed ? 0.01 : 0.05)),
      offset: isPressed ? const Offset(1, 1) : const Offset(3, 3),
      blurRadius: isPressed ? 2 : 5,
      spreadRadius: 0,
    ),
    if (!isDark) BoxShadow(
      color: Colors.white.withOpacity(isPressed ? 0.01 : 0.8),
      offset: isPressed ? const Offset(-1, -1) : const Offset(-3, -3),
      blurRadius: isPressed ? 2 : 5,
      spreadRadius: 0,
    ),
  ];
  
  // 毛玻璃效果装饰
  static BoxDecoration frostedGlassDecoration({
    double? borderRadius, 
    Color? color,
    bool isDark = false,
  }) => BoxDecoration(
    color: (color ?? (isDark ? darkCardColor.withOpacity(0.7) : Colors.white.withOpacity(0.7))),
    borderRadius: BorderRadius.circular(borderRadius ?? 12),
    boxShadow: [
      BoxShadow(
        color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.1),
        blurRadius: 10,
        spreadRadius: isDark ? 0 : -5,
      )
    ],
  );

  // 获取根据主题模式的主题
  static ThemeData getTheme(String mode, bool isDark) {
    switch (mode) {
      case 'default':
      default:
        return isDark ? darkTheme() : lightTheme();
    }
  }
  
  // 亮色主题
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        onBackground: textPrimaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryColor,
          fontSize: 14,
        ),
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          textStyle: MaterialStateProperty.all<TextStyle>(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
          padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevation: MaterialStateProperty.all(0),
          shadowColor: MaterialStateProperty.all(Colors.transparent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: TextStyle(color: textTertiaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        color: surfaceColor,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.4);
          }
          return Colors.grey[300];
        }),
      ),
    );
  }

  // 暗色主题
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryLightColor,
        background: darkBackgroundColor,
        surface: darkSurfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimaryColor,
        onBackground: darkTextPrimaryColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryLightColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: darkTextSecondaryColor,
          fontSize: 14,
        ),
        titleLarge: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          textStyle: MaterialStateProperty.all<TextStyle>(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
          padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevation: MaterialStateProperty.all(2),
          shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        hintStyle: TextStyle(color: darkTextTertiaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        color: darkCardColor,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      iconTheme: const IconThemeData(
        color: primaryLightColor,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCardColor,
        modalBackgroundColor: darkCardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkCardColor,
        contentTextStyle: TextStyle(color: darkTextPrimaryColor),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: darkDividerColor,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey[600];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.4);
          }
          return Colors.grey[800];
        }),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: darkCardColor,
        iconColor: primaryLightColor,
        textColor: darkTextPrimaryColor,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryLightColor,
        unselectedLabelColor: darkTextSecondaryColor,
        indicatorColor: primaryColor,
      ),
    );
  }
} 