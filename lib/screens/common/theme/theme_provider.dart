import 'package:flutter/material.dart';
import 'package:alive_shot/screens/common/theme/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider() : _themeMode = _getInitialTheme();

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();
  }

  static ThemeMode _getInitialTheme() {
    final hour = DateTime.now().hour;
    // Automático por hora (oscuro de 7pm a 6am)
    if (hour >= 19 || hour < 6) {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  // Tema claro
  static ThemeData getTheme(bool isDark) {
    return ThemeData(
      
      useMaterial3: false,
      colorScheme: ColorScheme(
        // Botones de accion, iconos destacados
        primary: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        // Texto o iconos encima de primary
        onPrimary: isDark ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
        /*Background secundarios, iconos.
        */
        secondary: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
        // Color del texto/icono encima de secondary
        onSecondary: isDark
            ? AppColors.onSecondaryDark
            : AppColors.onSecondaryLight,
        // Background de pantallas, targetas, dialogos, menus.
        surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        // Color para texto/iconos/bordes encima de surface
        onSurface: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
        surfaceContainer: isDark
            ? AppColors.onSurfaceVariantDark
            : const Color.fromARGB(98, 213, 213, 213),
        onSurfaceVariant: isDark
            ? AppColors.onSurfaceVariantDark
            : const Color.fromARGB(255, 146, 146, 146),
        brightness: isDark ? Brightness.dark : Brightness.light,
        error: Colors.red,
        onError: Colors.white,

      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}