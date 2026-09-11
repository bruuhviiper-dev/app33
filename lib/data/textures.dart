/// 60 texturas offline (papel, tecido, geométrico, ruído) para os cartões.
/// Assets leves (~19KB), embutidos no app — funcionam sem internet.
class Textures {
  Textures._();

  static List<String> get all => [
        for (var i = 1; i <= 60; i++)
          'assets/textures/tx${i.toString().padLeft(2, '0')}.jpg',
      ];
}
