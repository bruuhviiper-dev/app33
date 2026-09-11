import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Helper de compartilhamento/cópia (texto).
class ShareHelper {
  ShareHelper._();

  static Future<void> share(String text) async {
    await Share.share(text);
  }

  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
