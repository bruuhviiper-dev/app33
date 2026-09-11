import 'package:flutter/material.dart';

/// Tema do app — azul/roxo moderno (aesthetic, estiloso).
class AppTheme {
  AppTheme._();

  static const brand = Color(0xFF6C4BF4); // roxo-azulado
  static const brandDark = Color(0xFF4A2FB8);
  static const gold = Color(0xFFC9BEFF);

  /// Gradiente da "frase do dia" e da marca.
  static const hero = [Color(0xFF5B4FE0), Color(0xFF8E54E9)];

  static LinearGradient gradient(List<Color> colors) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );

  static ThemeData light([Color accent = brand]) {
    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFEFF4F5),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  static ThemeData dark([Color accent = brand]) {
    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0E1518),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
