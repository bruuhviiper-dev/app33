import 'package:flutter/material.dart';

/// Fundo de imagem para o cartão de story. Alguns são grátis; os marcados como
/// [premium] fazem parte do valor da loja (temas/pacote/assinatura).
class StoryBg {
  const StoryBg(this.colors, {this.premium = false, this.asset});
  final List<Color> colors;
  final bool premium;

  /// Caminho de uma imagem offline (assets/backgrounds/...). Quando presente,
  /// o fundo usa a foto em vez do gradiente.
  final String? asset;
  bool get isImage => asset != null;

  static const List<StoryBg> all = [
    // ----- imagens offline (natureza/vida) grátis -----
    StoryBg([Color(0xFFf6d365), Color(0xFFff5e62)],
        asset: 'assets/backgrounds/bg_pordosol.png'),
    StoryBg([Color(0xFF1f4037), Color(0xFF99f2c8)],
        asset: 'assets/backgrounds/bg_bokeh.png'),
    StoryBg([Color(0xFF11998e), Color(0xFF38ef7d)],
        asset: 'assets/backgrounds/bg_flores.png'),
    // ----- grátis -----
    StoryBg([Color(0xFFFF8008), Color(0xFFFFC837)]),
    StoryBg([Color(0xFF2193B0), Color(0xFF6DD5ED)]),
    StoryBg([Color(0xFF11998E), Color(0xFF38EF7D)]),
    StoryBg([Color(0xFF0F2027), Color(0xFF2C5364)]),
    StoryBg([Color(0xFFEE0979), Color(0xFFFF6A00)]),
    StoryBg([Color(0xFF141E30), Color(0xFF243B55)]),
    // ----- premium (imagens personalizadas) -----
    StoryBg([Color(0xFF2193b0), Color(0xFF6dd5ed)],
        asset: 'assets/backgrounds/bg_pastel.png', premium: true),
    StoryBg([Color(0xFF0f2027), Color(0xFF2c5364)],
        asset: 'assets/backgrounds/bg_coracoes.png', premium: true),
    StoryBg([Color(0xFF141E30), Color(0xFF243B55)],
        asset: 'assets/backgrounds/bg_ceu.png', premium: true),
    StoryBg([Color(0xFF8E2DE2), Color(0xFF4A00E0)], premium: true),
    StoryBg([Color(0xFFf953c6), Color(0xFFb91d73)], premium: true),
    StoryBg([Color(0xFF00C9FF), Color(0xFF92FE9D)], premium: true),
    StoryBg([Color(0xFFFDC830), Color(0xFFF37335)], premium: true),
    StoryBg([Color(0xFF3a1c71), Color(0xFFd76d77), Color(0xFFffaf7b)],
        premium: true),
    StoryBg([Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
        premium: true),
    StoryBg([Color(0xFFff9966), Color(0xFFff5e62)], premium: true),
    StoryBg([Color(0xFF654ea3), Color(0xFFeaafc8)], premium: true),
    StoryBg([Color(0xFF1D976C), Color(0xFF93F9B9)], premium: true),
    StoryBg([Color(0xFF200122), Color(0xFF6F0000)], premium: true),
    StoryBg([Color(0xFF1A2980), Color(0xFF26D0CE)], premium: true),
    StoryBg([Color(0xFFCB356B), Color(0xFFBD3F32)], premium: true),
    StoryBg([Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        premium: true),
    StoryBg([Color(0xFFee9ca7), Color(0xFFffdde1)], premium: true),
  ];
}
