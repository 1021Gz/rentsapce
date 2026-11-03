import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

final ValueNotifier<ThemeMode> appThemeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

void toggleAppThemeMode() {
  appThemeModeNotifier.value = appThemeModeNotifier.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
}

class ThemeToggleButton extends StatelessWidget {
  final Color? iconColor;

  const ThemeToggleButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'เปลี่ยนเป็นโหมดสว่าง' : 'เปลี่ยนเป็นโหมดมืด',
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 20,
            color: iconColor,
          ),
          onPressed: toggleAppThemeMode,
        );
      },
    );
  }
}

class ResponsiveFrame extends StatelessWidget {
  final Widget child;

  const ResponsiveFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            color: isDark ? const Color(0xFF090D16) : const Color(0xFFEFE9DE),
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

void main() {
  runApp(const RentSpaceApp());
}

class RentSpaceApp extends StatelessWidget {
  const RentSpaceApp({super.key});

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Authentic Reference Tokens from Downloads/rentspace/rentspace/src/styles.css
    // Primary: Terracotta Rust (oklch(0.6 0.15 40))
    const primaryColor = Color(0xFFC3562C);

    // Warm Sand Linen Ground & Deep Espresso Ink
    const backgroundLight = Color(0xFFFAF7F2);
    const backgroundDark = Color(0xFF101420);
    const foregroundLight = Color(0xFF32241D);
    const foregroundDark = Color(0xFFFAFBFD);

    // Ivory Card & Dark Slate Card
    const cardLight = Color(0xFFFFFFFF);
    const cardDark = Color(0xFF192030);

    // Borders & Muted
    const borderLight = Color(0xFFE8E2D8);
    const borderDark = Color(0xFF283248);
    const mutedDark = Color(0xFF141926);
    const mutedTextLight = Color(0xFF786D65);
    const mutedTextDark = Color(0xFF9E948C);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: const Color(0xFF2E633D),
      onSecondary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: isDark ? cardDark : cardLight,
      onSurface: isDark ? foregroundDark : foregroundLight,
      outline: isDark ? borderDark : borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? cardDark : cardLight,
        foregroundColor: isDark ? foregroundDark : foregroundLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? foregroundDark : foregroundLight,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : const Color(0xFF4A3E37),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? cardDark : cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? mutedDark : cardLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: isDark ? mutedTextDark : mutedTextLight,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDark ? mutedTextDark : mutedTextLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 48),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 48),
          foregroundColor: isDark ? foregroundDark : foregroundLight,
          side: BorderSide(color: isDark ? borderDark : borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? cardDark : cardLight,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primaryColor : (isDark ? mutedTextDark : mutedTextLight),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, activeThemeMode, _) {
        return MaterialApp(
          title: 'RentSpace',
          debugShowCheckedModeBanner: false,
          themeMode: activeThemeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const LoginScreen(),
        );
      },
    );
  }
}
