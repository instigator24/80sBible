import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/neon_theme.dart';
import '../theme/pastel_theme.dart';
import '../theme/retro_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _labels = {
    AppThemeId.pastel: 'Preppy Pastel',
    AppThemeId.neon: 'Neon Synthwave',
    AppThemeId.retroArcade: 'Retro Arcade',
  };

  static const _swatchColors = {
    AppThemeId.pastel: PastelColors.lavender,
    AppThemeId.neon: NeonColors.pink,
    AppThemeId.retroArcade: RetroColors.red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeProvider);

    return ListView(
      children: AppThemeId.values.map((id) {
        return ListTile(
          key: Key('theme-option-${id.name}'),
          leading: Container(
            key: Key('theme-swatch-${id.name}'),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _swatchColors[id],
              shape: BoxShape.circle,
            ),
          ),
          title: Text(_labels[id]!),
          trailing: selected == id
              ? const Icon(Icons.check, key: Key('theme-selected-check'))
              : null,
          onTap: () => ref.read(themeProvider.notifier).select(id),
        );
      }).toList(),
    );
  }
}
