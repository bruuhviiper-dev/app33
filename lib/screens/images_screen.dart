import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/image_backgrounds.dart';
import '../data/photo_backgrounds.dart';
import '../data/procedural_bg.dart';
import '../data/textures.dart';
import '../data/verses.dart';
import 'create_screen.dart';

/// Galeria de imagens prontas (frase sobre um fundo bonito), com FILTROS por
/// tipo: Fundos, Texturas e Fotos reais. Cada card tem um botão de EDITAR no
/// canto que abre o editor já com a frase + a imagem escolhida.
class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

enum _Kind { fundos, texturas, fotos, criativos }

class _ImagesScreenState extends State<ImagesScreen> {
  _Kind _kind = _Kind.fundos;

  int get _count => switch (_kind) {
        _Kind.fundos => ImageBackgrounds.all.length,
        _Kind.texturas => Textures.all.length,
        _Kind.fotos => photoBackgrounds.length,
        _Kind.criativos => ProceduralBg.variety,
      };

  // Frases curadas (grátis) para as prévias.
  List<String> get _phrases =>
      [for (final v in VerseData.freeVerses) v.text];

  void _openEditor(String text, int i) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => switch (_kind) {
        _Kind.fundos => CreateScreen(initialText: text, initialImageBg: i),
        _Kind.texturas => CreateScreen(initialText: text, initialTexture: i),
        _Kind.fotos =>
          CreateScreen(initialText: text, initialPhotoUrl: photoBackgrounds[i].full),
        _Kind.criativos => CreateScreen(initialText: text, initialSeed: i),
      },
    ));
  }

  Widget _bg(int i) {
    switch (_kind) {
      case _Kind.criativos:
        return CustomPaint(painter: ProceduralPainter(i), size: Size.infinite);
      case _Kind.fundos:
        return Image.asset(ImageBackgrounds.all[i], fit: BoxFit.cover);
      case _Kind.texturas:
        return Image.asset(Textures.all[i], fit: BoxFit.cover);
      case _Kind.fotos:
        return CachedNetworkImage(
          imageUrl: photoBackgrounds[i].thumb,
          fit: BoxFit.cover,
          placeholder: (_, _) => const ColoredBox(
            color: Colors.black12,
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          errorWidget: (_, _, _) => const ColoredBox(
            color: Colors.black12,
            child: Icon(Icons.wifi_off_rounded, color: Colors.black38),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phrases = _phrases;
    return Scaffold(
      appBar: AppBar(title: const Text('Imagens')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ---- Filtros por tipo (rola na horizontal: nunca estoura) ----
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                children: [
                  for (final k in _Kind.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(switch (k) {
                          _Kind.fundos => 'Fundos',
                          _Kind.texturas => 'Texturas',
                          _Kind.fotos => 'Fotos',
                          _Kind.criativos => 'Criativos',
                        }),
                        selected: _kind == k,
                        onSelected: (_) => setState(() => _kind = k),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: _count,
                itemBuilder: (context, i) {
                  final text = phrases[i % phrases.length];
                  return Material(
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openEditor(text, i),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _bg(i),
                          // escurece p/ legibilidade
                          Container(color: Colors.black.withValues(alpha: 0.28)),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                text,
                                textAlign: TextAlign.center,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lora(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  shadows: const [
                                    Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // ---- Botão EDITAR no canto ----
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _openEditor(text, i),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
