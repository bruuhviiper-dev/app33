import 'package:flutter/material.dart';

/// Paleta de cores vendável (tema do app). A "clássica" é grátis.
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.accent,
    required this.gradient,
    this.premium = false,
    this.productId,
  });

  final String id;
  final String name;
  final Color accent;
  final List<Color> gradient;
  final bool premium;
  final String? productId;
}

class AppPalettes {
  AppPalettes._();

  static const classico = AppPalette(
    id: 'classico',
    name: 'Sereno',
    accent: Color(0xFF2C7A7B),
    gradient: [Color(0xFF0F2027), Color(0xFF2C5364)],
    premium: false,
  );

  static const all = <AppPalette>[
    classico,
    AppPalette(
        id: 'dourado',
        name: 'Dourado',
        accent: Color(0xFFD4AF37),
        gradient: [Color(0xFFB8860B), Color(0xFF1A1A1A)],
        productId: 'theme_dourado'),
    AppPalette(
        id: 'oliveira',
        name: 'Floresta',
        accent: Color(0xFF2E7D32),
        gradient: [Color(0xFF134E5E), Color(0xFF71B280)],
        productId: 'theme_oliveira'),
    AppPalette(
        id: 'ceu',
        name: 'Céu',
        accent: Color(0xFF0EA5E9),
        gradient: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
        productId: 'theme_ceu'),
    AppPalette(
        id: 'purpura',
        name: 'Púrpura Real',
        accent: Color(0xFF7C3AED),
        gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        productId: 'theme_purpura'),
    AppPalette(
        id: 'aurora',
        name: 'Aurora',
        accent: Color(0xFFEC4899),
        gradient: [Color(0xFFF857A6), Color(0xFFFF5858)],
        productId: 'theme_aurora'),
    AppPalette(
        id: 'noturno',
        name: 'Noturno',
        accent: Color(0xFF6366F1),
        gradient: [Color(0xFF141E30), Color(0xFF243B55)],
        productId: 'theme_noturno'),
  ];

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => classico);
}
