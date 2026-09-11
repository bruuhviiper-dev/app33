import 'package:flutter/material.dart';

/// Fundos-imagem para o nicho de REFLEXÃO. Começa pelos TEMÁTICOS novos
/// (montanha ao alvorecer, lago espelhado, noite estrelada, névoa, floresta,
/// zen, pôr do sol, céu, vale — desenhados p/ o app), depois os estéticos mais
/// serenos e por fim os genéricos. Assets leves, offline.
class ImageBackgrounds {
  ImageBackgrounds._();

  /// Cenas de reflexão desenhadas para o app (as mais aderentes ao tema).
  static const List<String> _reflexao = [
    'assets/backgrounds/bg_ref01_montanha.jpg',
    'assets/backgrounds/bg_ref02_lago.jpg',
    'assets/backgrounds/bg_ref03_noite.jpg',
    'assets/backgrounds/bg_ref04_amanhecer.jpg',
    'assets/backgrounds/bg_ref05_neblina.jpg',
    'assets/backgrounds/bg_ref06_floresta.jpg',
    'assets/backgrounds/bg_ref07_zen.jpg',
    'assets/backgrounds/bg_ref08_pordosol.jpg',
    'assets/backgrounds/bg_ref09_ceu.jpg',
    'assets/backgrounds/bg_ref10_vale.jpg',
    'assets/backgrounds/bg_ref11_teal.jpg',
    'assets/backgrounds/bg_ref12_crepusculo.jpg',
  ];

  /// Estéticos: os serenos primeiro; corações/flores (menos temáticos) por fim.
  static const List<String> _estetico = [
    'assets/backgrounds/bg_ceu.png',
    'assets/backgrounds/bg_pordosol.png',
    'assets/backgrounds/bg_pastel.png',
    'assets/backgrounds/bg_bokeh.png',
    'assets/backgrounds/bg_flores.png',
    'assets/backgrounds/bg_coracoes.png',
  ];

  static List<String> get all => [
        ..._reflexao,
        ..._estetico,
        for (var i = 1; i <= 96; i++)
          'assets/backgrounds/bg${i.toString().padLeft(2, '0')}.jpg',
      ];
}

/// Filtros de cor aplicados por cima do fundo (tinta translúcida). Dão a
/// sensação de "mais opções" sem precisar de mil imagens.
class CardFilters {
  CardFilters._();

  static const List<String> names = [
    'Original',
    'Quente',
    'Frio',
    'Rosé',
    'Vintage',
    'Escuro',
    'Claro',
  ];

  /// Cor da tinta do filtro [i] (0 = Original / sem filtro).
  static Color? color(int i) => switch (i) {
        1 => const Color(0x33FF7A18), // quente
        2 => const Color(0x332A6FFF), // frio
        3 => const Color(0x33FF3D8B), // rosé
        4 => const Color(0x40C9A24B), // vintage
        5 => const Color(0x59000000), // escuro
        6 => const Color(0x26FFFFFF), // claro
        _ => null,
      };
}
