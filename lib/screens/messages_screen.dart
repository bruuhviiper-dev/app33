import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/verses.dart';
import '../services/app_state.dart';
import '../widgets/share_helper.dart';
import 'create_screen.dart';

/// Lista "infinita" de frases geradas (sem IA, offline). O banner fica no shell
/// (rodapé fixo), sem duplicar.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final verses = VerseData.all;
    final itemCount = verses.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Frases em Inglês')),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
        itemCount: itemCount,
        itemBuilder: (context, i) {
          final verse = verses[i];
          final text = verse.text;
          final share = '$text\n\n🕊 Frases em Inglês';
          final fav = state.isFavorite(verse.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: GoogleFonts.lora(fontSize: 16, height: 1.5)),
                  if (verse.reference.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('🇧🇷 ${verse.reference}',
                          style: GoogleFonts.lora(
                              fontSize: 13.5,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        tooltip: fav ? 'Desfavoritar' : 'Favoritar',
                        icon: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: fav ? const Color(0xFFE11D48) : null),
                        onPressed: () =>
                            context.read<AppState>().toggleFavorite(verse),
                      ),
                      IconButton(
                        tooltip: 'Copiar',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () async {
                          await ShareHelper.copy(share);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copiado!')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Criar imagem',
                        icon: const Icon(Icons.image_rounded, size: 20),
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) => CreateScreen(initialText: text))),
                      ),
                      IconButton(
                        tooltip: 'Compartilhar',
                        icon: const Icon(Icons.share_rounded, size: 20),
                        onPressed: () => ShareHelper.share(share),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
