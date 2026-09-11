import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// Banco de FRASES BONITAS (100% OFFLINE) carregado de assets/frases/*.json.
///
/// O conteúdo agora é DADO (JSON empacotado no APK), não código — dá pra crescer
/// para milhares de frases e dezenas de categorias só editando/adicionando JSON,
/// sem tocar na UI. Tudo é lido do bundle (sem rede), então a exibição nunca
/// depende de conexão.
///
/// Índice: `assets/frases/index.json` — [{id,name,emoji,gradient:[hex,hex],premium}]
/// Frases: `assets/frases/{id}.json` — ["frase 1", "frase 2", ...]
class VerseData {
  VerseData._();

  static List<VerseCategory> _categories = const [];
  static bool _loaded = false;

  /// Carrega todo o conteúdo do bundle. Chame UMA vez no startup (antes de
  /// abrir a home), assim as telas sempre encontram o conteúdo pronto.
  static Future<void> load() async {
    if (_loaded) return;
    final indexRaw = await rootBundle.loadString('assets/frases/index.json');
    final index = (json.decode(indexRaw) as List).cast<Map<String, dynamic>>();

    final cats = <VerseCategory>[];
    for (final meta in index) {
      final id = meta['id'] as String;
      List<Verse> verses = const [];
      try {
        final raw = await rootBundle.loadString('assets/frases/$id.json');
        final list = (json.decode(raw) as List);
        // Cada item pode ser String (só texto) ou {"t":inglês,"r":tradução}.
        verses = [
          for (final e in list)
            e is Map
                ? Verse(e['t'] as String, (e['r'] as String?) ?? '')
                : Verse(e as String)
        ];
      } catch (_) {
        // Categoria sem arquivo/parse inválido: entra vazia (nunca quebra a UI).
        verses = const [];
      }
      final grad = (meta['gradient'] as List).cast<String>();
      cats.add(VerseCategory(
        id: id,
        name: meta['name'] as String,
        emoji: meta['emoji'] as String,
        gradient: [_hex(grad[0]), _hex(grad[1])],
        premium: meta['premium'] as bool? ?? false,
        verses: verses,
      ));
    }
    _categories = cats;
    _loaded = true;
  }

  static Color _hex(String s) {
    final h = s.replaceAll('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }

  static List<VerseCategory> get categories => _categories;

  static List<Verse> get all => [for (final c in _categories) ...c.verses];

  static List<Verse> get freeVerses =>
      [for (final c in _categories) if (!c.premium) ...c.verses];

  /// Frase do dia determinística (muda a cada dia, estável no mesmo dia).
  /// Usada no card do topo e na notificação — mantém os dois em sincronia.
  static String ofDay([DateTime? date]) {
    final list = freeVerses.isNotEmpty ? freeVerses : all;
    if (list.isEmpty) return '';
    final d = date ?? DateTime.now();
    final dayIndex =
        DateTime(d.year, d.month, d.day).difference(DateTime(2020, 1, 1)).inDays;
    return list[(dayIndex.abs() * 7919) % list.length].text;
  }

  /// Verse do dia COMPLETO (inglês + tradução), em sincronia com [ofDay].
  static Verse verseOfDay([DateTime? date]) {
    final list = freeVerses.isNotEmpty ? freeVerses : all;
    if (list.isEmpty) return Verse(ofDay(date));
    final d = date ?? DateTime.now();
    final dayIndex =
        DateTime(d.year, d.month, d.day).difference(DateTime(2020, 1, 1)).inDays;
    return list[(dayIndex.abs() * 7919) % list.length];
  }

  static VerseCategory categoryById(String id) => _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => _categories.isNotEmpty
            ? _categories.first
            : const VerseCategory(
                id: '', name: '', emoji: '', gradient: [], verses: []),
      );
}
