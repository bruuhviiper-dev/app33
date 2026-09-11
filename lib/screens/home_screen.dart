import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_palettes.dart';
import '../data/app_theme.dart';
import '../data/models.dart';
import '../data/story_backgrounds.dart';
import '../data/verses.dart';
import '../services/app_state.dart';
import '../widgets/share_helper.dart';
import '../widgets/verse_image.dart';
import 'category_screen.dart';
import 'create_screen.dart';
import 'messages_screen.dart';
import 'store_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frases em Inglês'),
        titleSpacing: 12,
        actions: [
          if (!state.adsRemoved)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoreScreen()),
                ),
                icon: const Icon(Icons.block_rounded, size: 16),
                label: const Text('Remover anúncio'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cores e tema',
            icon: const Icon(Icons.palette_rounded),
            onPressed: () => _showThemePicker(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: _MessageOfDay(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Text('Categorias',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: state.categorySingleColumn
                      ? 'Ver em 2 colunas'
                      : 'Ver em 1 coluna',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(state.categorySingleColumn
                      ? Icons.grid_view_rounded
                      : Icons.view_agenda_rounded),
                  onPressed: () =>
                      context.read<AppState>().toggleCategoryColumns(),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: state.categorySingleColumn ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: state.categorySingleColumn ? 2.5 : 1.05,
            children: [
              for (final c in VerseData.categories)
                _CategoryTile(
                    category: c, locked: state.isCategoryLocked(c.premium)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seletor de temas (cores do app) — todos GRÁTIS. Aplica na hora.
void _showThemePicker(BuildContext context) {
  final state = context.read<AppState>();
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_rounded, size: 20),
                const SizedBox(width: 8),
                Text('Escolha o tema',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Personalize as cores do app — tudo grátis.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey)),
            const SizedBox(height: 8),
            Consumer<AppState>(
              builder: (c, s, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(s.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded),
                title: const Text('Modo escuro'),
                value: s.isDark,
                onChanged: (_) => s.toggleTheme(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final p in AppPalettes.all)
                  GestureDetector(
                    onTap: () {
                      context.read<AppState>().setPalette(p.id);
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: p.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: state.palette.id == p.id
                                  ? p.accent
                                  : Colors.black12,
                              width: state.palette.id == p.id ? 4 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: p.accent.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: state.palette.id == p.id
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 26)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 72,
                          child: Text(p.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _MessageOfDay extends StatefulWidget {
  @override
  State<_MessageOfDay> createState() => _MessageOfDayState();
}

class _MessageOfDayState extends State<_MessageOfDay> {
  final _key = GlobalKey();
  final _rng = Random();
  bool _busy = false;

  // Frase do dia (mesma lógica da notificação) + estilo dinâmico por sessão.
  // "Surpreenda-me" sorteia uma nova frase bonita e um novo estilo de cartão.
  Verse _msg = Verse(VerseData.ofDay());
  List<Color> _gradient =
      StoryBg.all[Random().nextInt(StoryBg.all.length)].colors;

  void _shuffle() {
    final list = VerseData.freeVerses;
    if (list.isEmpty) return;
    setState(() {
      _msg = list[_rng.nextInt(list.length)];
      _gradient = StoryBg.all[_rng.nextInt(StoryBg.all.length)].colors;
    });
  }

  void _openEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateScreen(initialText: _msg.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final share = '${_msg.text}\n\n🕊 Frases em Inglês';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('FRASE DO DIA',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      fontSize: 12)),
              const Spacer(),
              TextButton.icon(
                onPressed: _shuffle,
                icon: const Icon(Icons.shuffle_rounded, size: 18),
                label: const Text('Surpreenda-me'),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _openEditor,
          child: Container(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: _gradient.last.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: VerseImageCard(
              verse: _msg,
              gradient: _gradient,
              captureKey: _key,
            ),
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              ),
              icon: const Icon(Icons.forum_rounded, size: 18),
              label: const Text('Ver mais'),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Copiar',
              icon: const Icon(Icons.copy_rounded),
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
              icon: const Icon(Icons.image_rounded),
              onPressed: _openEditor,
            ),
            IconButton(
              tooltip: 'Compartilhar imagem',
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.share_rounded),
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await shareVerseImage(_key);
                      if (mounted) setState(() => _busy = false);
                    },
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.locked = false});
  final VerseCategory category;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final grad = category.gradient;
    const nameShadow = [
      Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 1)),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.gradient(grad),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: grad.last.withValues(alpha: 0.38),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => locked
                  ? const StoreScreen()
                  : CategoryScreen(category: category),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -14,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 92,
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: Text(category.emoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                        const Spacer(),
                        Icon(
                          locked
                              ? Icons.lock_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 19,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          shadows: nameShadow,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
