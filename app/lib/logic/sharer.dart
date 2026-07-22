import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract class Sharer {
  Future<void> shareText(String text);
  Future<void> shareImage(Uint8List pngBytes, {required String filename});
}

class SharePlusSharer implements Sharer {
  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Future<void> shareImage(Uint8List pngBytes, {required String filename}) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$filename').writeAsBytes(pngBytes);
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

final sharerProvider = Provider<Sharer>((ref) => SharePlusSharer());
