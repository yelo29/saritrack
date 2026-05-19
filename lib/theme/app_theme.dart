import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primaryBlue       = Color(0xFF1A6B8A);
  static const Color primaryBlueDark   = Color(0xFF003547);
  static const Color primaryBlueLight  = Color(0xFFCDE9F5);

  static const Color secondaryBrown    = Color(0xFFC4793A);
  static const Color secondaryBrownDark  = Color(0xFF4A2800);
  static const Color secondaryBrownLight = Color(0xFFFFDCC2);

  static const Color tertiaryGreen     = Color(0xFF2D9D6E);
  static const Color tertiaryGreenDark  = Color(0xFF002117);
  static const Color tertiaryGreenLight = Color(0xFFB7F0D5);

  // ── Surfaces ──────────────────────────────────────────────────
  static const Color surfaceWhite      = Color(0xFFFFF8F0);
  static const Color surfaceCream      = Color(0xFFF5F0E8);
  static const Color surfaceCard       = Colors.white;
  static const Color onSurface        = Color(0xFF2C1F0E);
  static const Color onSurfaceVariant  = Color(0xFF5C4A2A);

  // ── Outline / Divider ─────────────────────────────────────────
  static const Color outline           = Color(0xFF8B7355);
  static const Color outlineVariant    = Color(0xFFD4C4A8);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color error             = Color(0xFFBA1A1A);
  static const Color errorContainer    = Color(0xFFFFDAD6);
  static const Color onError           = Colors.white;
  static const Color onErrorContainer  = Color(0xFF410002);

  static const Color inverseSurface    = Color(0xFF3D2E1A);
  static const Color onInverseSurface  = Color(0xFFFFF0DC);
  static const Color inversePrimary    = Color(0xFF8ECFEA);

  // ── ColorScheme ───────────────────────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,

    primary:            primaryBlue,
    onPrimary:          Colors.white,
    primaryContainer:   primaryBlueLight,
    onPrimaryContainer: primaryBlueDark,

    secondary:            secondaryBrown,
    onSecondary:          Colors.white,
    secondaryContainer:   secondaryBrownLight,
    onSecondaryContainer: secondaryBrownDark,

    tertiary:            tertiaryGreen,
    onTertiary:          Colors.white,
    tertiaryContainer:   tertiaryGreenLight,
    onTertiaryContainer: tertiaryGreenDark,

    surface:                 surfaceWhite,
    onSurface:               onSurface,
    surfaceContainerHighest: surfaceCream,
    onSurfaceVariant:        onSurfaceVariant,

    error:            error,
    onError:          onError,
    errorContainer:   errorContainer,
    onErrorContainer: onErrorContainer,

    outline:        outline,
    outlineVariant: outlineVariant,

    shadow:          Color(0xFF000000),
    scrim:           Color(0xFF000000),
    inverseSurface:  inverseSurface,
    onInverseSurface: onInverseSurface,
    inversePrimary:  inversePrimary,
  );

  // ── Sub-themes ────────────────────────────────────────────────
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
  );

  static NavigationBarThemeData get _navigationBarTheme =>
      NavigationBarThemeData(
        backgroundColor: surfaceCream,
        indicatorColor: primaryBlueLight,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryBlue);
          }
          return const IconThemeData(color: outline);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(color: outline, fontSize: 12);
        }),
      );

  static const FloatingActionButtonThemeData _fabTheme =
      FloatingActionButtonThemeData(
        backgroundColor: secondaryBrown,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      );

  static CardThemeData get _cardTheme => CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: outlineVariant, width: 0.8),
        ),
      );

  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: surfaceCream,
        selectedColor: primaryBlueLight,
        labelStyle: const TextStyle(color: onSurface, fontSize: 13),
        side: const BorderSide(color: outlineVariant, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: inverseSurface,
    contentTextStyle: TextStyle(color: onInverseSurface),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static const TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(primaryBlue),
    ),
  );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  static InputDecorationTheme get _inputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: surfaceCream,
        hintStyle: const TextStyle(color: outline, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: outlineVariant,
    thickness: 0.8,
  );

  static const TabBarThemeData _tabBarTheme = TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: primaryBlueLight,
    indicatorColor: Colors.white,
    labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    unselectedLabelStyle: TextStyle(fontSize: 13),
  );

  static const DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: surfaceWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    titleTextStyle: TextStyle(
      color: onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: TextStyle(
      color: onSurfaceVariant,
      fontSize: 14,
      height: 1.5,
    ),
  );

  static const ListTileThemeData _listTileTheme = ListTileThemeData(
    tileColor: Colors.transparent,
    iconColor: outline,
    titleTextStyle: TextStyle(
      color: onSurface,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    subtitleTextStyle: TextStyle(
      color: onSurfaceVariant,
      fontSize: 13,
    ),
  );

  // ── Main ThemeData ─────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: _colorScheme,
        scaffoldBackgroundColor: surfaceWhite,
        appBarTheme: _appBarTheme,
        navigationBarTheme: _navigationBarTheme,
        floatingActionButtonTheme: _fabTheme,
        cardTheme: _cardTheme,
        chipTheme: _chipTheme,
        snackBarTheme: _snackBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        textButtonTheme: _textButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        dividerTheme: _dividerTheme,
        tabBarTheme: _tabBarTheme,
        dialogTheme: _dialogTheme,
        listTileTheme: _listTileTheme,
      );
}