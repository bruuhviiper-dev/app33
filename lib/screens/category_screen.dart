import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/image_backgrounds.dart';
import '../data/models.dart';
import '../widgets/verse_tile.dart';
import 'create_screen.dart';

/// Frases de uma categoria. O usuário escolhe ver como TEXTO (lista, 1 card por
/// linha) ou como IMAGEM (grid de 2 cards, cada um editável). O banner fica no
/// shell (rodapé fixo) e a barra de navegação permanece visível.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final VerseCategory category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

enum _View { texto, imagem }

class _CategoryScreenState extends State<CategoryScreen> {
  _View _view = _View.texto;

  void _openEditor(String text, int bgIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateScreen(
        initialText: text,
        initialImageBg: bgIndex % ImageBackgrounds.all.length,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final verses = widget.category.verses;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.emoji}  ${widget.category.name}'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ---- Alternância Texto | Imagem ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: SegmentedButton<_View>(
                segments: const [
                  ButtonSegment(
                      value: _View.texto,
                      icon: Icon(Icons.view_agenda_rounded),
                      label: Text('Texto')),
                  ButtonSegment(
                      value: _View.imagem,
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Imagem')),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
                showSelectedIcon: false,
              ),
            ),
            Expanded(
              child: _view == _View.texto
                  ? ListView.builder(
                      padding: const EdgeInsets.only(top: 6, bottom: 24),
                      itemCount: verses.length,
                      itemBuilder: (context, i) => VerseTile(verse: verses[i]),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: verses.length,
                      itemBuilder: (context, i) => _ImageCard(
                        text: verses[i].text,
                        bg: ImageBackgrounds.all[i % ImageBackgrounds.all.length],
                        onTap: () => _openEditor(verses[i].text, i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de imagem (frase sobre um fundo bonito) com botão de EDITAR.
class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.text, required this.bg, required this.onTap});

  final String text;
  final String bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(bg, fit: BoxFit.cover),
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
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child:
                        Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
