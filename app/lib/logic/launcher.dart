import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

abstract class Launcher {
  Future<void> launch(Uri uri);
}

class UrlLauncher implements Launcher {
  @override
  Future<void> launch(Uri uri) async {
    await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
  }
}

final launcherProvider = Provider<Launcher>((ref) => UrlLauncher());
