import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_theme.dart';
import '../data/image_backgrounds.dart';
import '../data/photo_backgrounds.dart';
import '../data/procedural_bg.dart';
import '../data/story_backgrounds.dart';
import '../data/textures.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';

/// Editor PRO: cria uma frase como imagem (formatos, fontes, cores, fundos,
/// texturas, fotos reais, sua foto, filtros, assinatura e salvar na galeria).
/// Tudo grátis.
class CreateScreen extends StatefulWidget {
  const CreateScreen({
    super.key,
    this.initialText,
    this.initialBg,
    this.initialImageBg,
    this.initialTexture,
    this.initialPhotoUrl,
    this.initialSeed,
  });

  /// Texto inicial — abre o editor já com a frase escolhida.
  final String? initialText;

  /// Fundo-gradiente inicial (índice em StoryBg.all).
  final int? initialBg;

  /// Fundo-imagem inicial (índice em ImageBackgrounds.all).
  final int? initialImageBg;

  /// Textura inicial (índice em Textures.all).
  final int? initialTexture;

  /// Foto real inicial (URL do photo_backgrounds).
  final String? initialPhotoUrl;

  /// Fundo PROCEDURAL inicial (seed em ProceduralPainter).
  final int? initialSeed;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _Format {
  const _Format(this.label, this.ratio);
  final String label;
  final double ratio;
}

class _CreateScreenState extends State<CreateScreen> {
  final _controller = TextEditingController();
  final _cardKey = GlobalKey();

  int _bg = 0;
  int _format = 0;
  int _font = 0;
  int _color = 0;
  String? _photoPath; // foto do usuário (galeria do celular)
  String? _photoUrl; // foto real (Unsplash)
  int? _imageBg; // fundo-imagem offline
  int? _texture; // textura offline
  int? _seed; // fundo procedural (gerado no aparelho)
  int _filter = 0; // filtro de cor
  bool _busy = false;

  static const _formats = [
    _Format('Story', 9 / 16),
    _Format('Quadrado', 1),
    _Format('Retrato', 4 / 5),
  ];

  static const _fonts = [
    'Lora',
    'Montserrat',
    'Poppins',
    'Pacifico',
    'Oswald',
    'Dancing Script',
    'Bebas Neue',
    'Playfair Display',
  ];

  // Fontes livres (as 4 primeiras). As demais fazem parte do "Pack Criativos+",
  // liberado por 24h assistindo um vídeo (opt-in, nada bloqueante).
  static const _freeFontCount = 4;
  // Quantos fundos Criativos aparecem sem o pack (com o pack, o dobro).
  static const _freeCriativos = 60;
  static const _colors = [
    Colors.white,
    Colors.black,
    Color(0xFFFFE066),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFC026D3),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.trim().isNotEmpty) {
      _controller.text = widget.initialText!.trim();
    }
    if (widget.initialBg != null &&
        widget.initialBg! >= 0 &&
        widget.initialBg! < StoryBg.all.length) {
      _bg = widget.initialBg!;
    }
    if (widget.initialImageBg != null) _imageBg = widget.initialImageBg;
    if (widget.initialTexture != null) _texture = widget.initialTexture;
    if (widget.initialPhotoUrl != null) _photoUrl = widget.initialPhotoUrl;
    if (widget.initialSeed != null) _seed = widget.initialSeed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Uint8List?> _capture() async {
    // Garante que a foto de rede esteja carregada antes de capturar.
    if (_photoUrl != null) {
      try {
        await precacheImage(CachedNetworkImageProvider(_photoUrl!), context);
        await WidgetsBinding.instance.endOfFrame;
      } catch (_) {}
    }
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 3.5);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _shareImage(bool noWatermark) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/frase_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: noWatermark ? '' : 'Feito no app Frases em Inglês 🕊');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      await Gal.putImageBytes(bytes, album: 'Frases em Inglês');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem salva na galeria! 📥')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível salvar.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) {
      setState(() {
        _photoPath = x.path;
        _photoUrl = null;
        _imageBg = null;
        _texture = null;
      });
    }
  }

  Future<void> _editSignature(AppState s) async {
    final c = TextEditingController(text: s.customSignature);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sua assinatura'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: '@seu_perfil ou seu nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (v != null) s.setCustomSignature(v);
  }

  TextStyle _font_(Color color) => GoogleFonts.getFont(
        _fonts[_font],
        color: color,
        fontSize: 22,
        height: 1.4,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 2)),
        ],
      );

  /// Limpa qualquer fundo-imagem/foto/procedural (volta pro gradiente).
  void _clearImages() {
    _photoPath = null;
    _photoUrl = null;
    _imageBg = null;
    _texture = null;
    _seed = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pro = state.hasTemporaryPro; // Pack Criativos+ ativo (24h)?
    final bg = StoryBg.all[_bg];
    final color = _colors[_color];
    final filterColor = CardFilters.color(_filter);
    final text = _controller.text.trim().isEmpty
        ? 'Escreva a sua frase aqui...'
        : _controller.text.trim();

    // Prioridade do fundo: foto do usuário > foto real > fundo-imagem > textura.
    DecorationImage? bgImage;
    final bool hasPhotoOverlay = _photoPath != null || _photoUrl != null;
    if (_photoPath != null) {
      bgImage =
          DecorationImage(image: FileImage(File(_photoPath!)), fit: BoxFit.cover);
    } else if (_photoUrl != null) {
      bgImage = DecorationImage(
          image: CachedNetworkImageProvider(_photoUrl!), fit: BoxFit.cover);
    } else if (_imageBg != null) {
      bgImage = DecorationImage(
          image: AssetImage(ImageBackgrounds.all[_imageBg!]), fit: BoxFit.cover);
    } else if (_texture != null) {
      bgImage = DecorationImage(
          image: AssetImage(Textures.all[_texture!]), fit: BoxFit.cover);
    }

    final sig = state.customSignature.isNotEmpty
        ? state.customSignature
        : (state.canRemoveWatermark ? '' : '🕊 Frases em Inglês');

    return Scaffold(
      appBar: AppBar(title: const Text('Criar (Editor)')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 28 + MediaQuery.of(context).padding.bottom),
        children: [
          // ---- Pré-visualização (vira a imagem) ----
          Center(
            child: SizedBox(
              width: 280,
              child: AspectRatio(
                aspectRatio: _formats[_format].ratio,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: (bgImage == null && _seed == null)
                          ? AppTheme.gradient(bg.colors)
                          : null,
                      image: bgImage,
                    ),
                    child: Stack(
                      children: [
                        if (_seed != null)
                          Positioned.fill(
                              child: CustomPaint(
                                  painter: ProceduralPainter(_seed!))),
                        if (hasPhotoOverlay)
                          Container(color: Colors.black.withValues(alpha: 0.28)),
                        if (filterColor != null)
                          Positioned.fill(child: Container(color: filterColor)),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Text(text,
                                textAlign: TextAlign.center, style: _font_(color)),
                          ),
                        ),
                        if (sig.isNotEmpty)
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Text(sig,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: color.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Escreva a sua frase...',
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          _label(context, 'Formato'),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _formats.length; i++)
                ChoiceChip(
                  label: Text(_formats[i].label),
                  selected: _format == i,
                  onSelected: (_) => setState(() => _format = i),
                ),
            ],
          ),
          const SizedBox(height: 14),

          _label(context, 'Fontes'),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fonts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final sel = _font == i;
                final locked = i >= _freeFontCount && !pro;
                return ActionChip(
                  avatar: locked
                      ? const Icon(Icons.play_circle_fill_rounded, size: 18)
                      : null,
                  label: Text('Aa',
                      style: GoogleFonts.getFont(_fonts[i],
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
                  backgroundColor: sel
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  onPressed: () => locked
                      ? _offerRewarded()
                      : setState(() => _font = i),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          _label(context, 'Cor do texto'),
          Row(
            children: [
              for (var i = 0; i < _colors.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _colors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _color == i
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black26,
                            width: _color == i ? 3 : 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ---- Fundos (gradientes) ----
          _label(context, 'Fundos'),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: StoryBg.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final b = StoryBg.all[i];
                final sel = !hasPhotoOverlay &&
                    _imageBg == null &&
                    _texture == null &&
                    _seed == null &&
                    _bg == i;
                return GestureDetector(
                  onTap: () => setState(() {
                    _bg = i;
                    _clearImages();
                  }),
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient(b.colors),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ---- Criativos (fundos procedurais, gerados no aparelho) ----
          Row(
            children: [
              Text('Criativos', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {
                  _clearImages();
                  _seed = math.Random().nextInt(ProceduralBg.variety);
                }),
                icon: const Icon(Icons.shuffle_rounded, size: 18),
                label: const Text('Surpreenda'),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pro ? _freeCriativos * 2 : _freeCriativos + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                // Tile de "desbloquear +" (só quando o pack não está ativo).
                if (!pro && i == _freeCriativos) {
                  return GestureDetector(
                    onTap: _offerRewarded,
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill_rounded, size: 20),
                          SizedBox(height: 2),
                          Text('+ mais',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                }
                final sel = _seed == i;
                return GestureDetector(
                  onTap: () => setState(() {
                    _clearImages();
                    _seed = i;
                  }),
                  child: Container(
                    width: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3),
                    ),
                    child: CustomPaint(painter: ProceduralPainter(i)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ---- Fundos-imagem (offline) ----
          _label(context, 'Fundos-imagem'),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ImageBackgrounds.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final sel = _imageBg == i;
                return GestureDetector(
                  onTap: () => setState(() {
                    _clearImages();
                    _imageBg = i;
                  }),
                  child: Container(
                    width: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3),
                      image: DecorationImage(
                          image: AssetImage(ImageBackgrounds.all[i]),
                          fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ---- Texturas (offline) ----
          _label(context, 'Texturas'),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Textures.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final sel = _texture == i;
                return GestureDetector(
                  onTap: () => setState(() {
                    _clearImages();
                    _texture = i;
                  }),
                  child: Container(
                    width: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3),
                      image: DecorationImage(
                          image: AssetImage(Textures.all[i]), fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ---- Fotos reais (Unsplash, grátis) ----
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('Fotos reais',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('GRÁTIS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoBackgrounds.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final pb = photoBackgrounds[i];
                final sel = _photoUrl == pb.full;
                return GestureDetector(
                  onTap: () => setState(() {
                    _clearImages();
                    _photoUrl = pb.full;
                  }),
                  child: Container(
                    width: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: pb.thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                          Icons.wifi_off_rounded,
                          size: 16,
                          color: Colors.black38),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ---- Filtro de cor ----
          _label(context, 'Filtro'),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < CardFilters.names.length; i++)
                ChoiceChip(
                  label: Text(CardFilters.names[i]),
                  selected: _filter == i,
                  onSelected: (_) => setState(() => _filter = i),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Ações ----
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Sua foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editSignature(state),
                  icon: const Icon(Icons.draw_rounded),
                  label: const Text('Assinatura'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : () => _shareImage(state.canRemoveWatermark),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_rounded),
            label: const Text('Compartilhar imagem'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _saveGallery,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Salvar na galeria (HD)'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              final t = _controller.text.trim();
              if (t.isNotEmpty) {
                Share.share('$t\n\n🕊 Frases em Inglês');
              }
            },
            icon: const Icon(Icons.text_fields_rounded),
            label: const Text('Compartilhar texto'),
          ),
        ],
      ),
    );
  }

  /// Oferece liberar o "Pack Criativos+" (fontes premium + mais fundos) por 24h
  /// assistindo um vídeo. Opt-in, aberto só quando o usuário toca num item.
  void _offerRewarded() {
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
                  const Icon(Icons.auto_awesome_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text('Pack Criativos+',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                  'Libere as fontes premium e o dobro de fundos Criativos por 24h. '
                  'É grátis: basta assistir um vídeo rápido. Sem assinatura.',
                  style: TextStyle(fontSize: 13.5, height: 1.4)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await AdsService.instance.showRewarded(() {
                      context
                          .read<AppState>()
                          .grantTemporaryPro(const Duration(hours: 24));
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Liberado por 24h! Aproveite 🎉'
                              : 'Vídeo indisponível agora, tente em instantes.')));
                  },
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text('Assistir vídeo (grátis)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall),
      );
}
