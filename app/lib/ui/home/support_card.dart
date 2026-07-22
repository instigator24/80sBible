import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/launcher.dart';
import '../../logic/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/arcade_cabinet.dart';
import '../theme/retro_theme.dart';

// Dummy placeholders until real accounts are wired up.
const _paypalUrl = 'https://paypal.me/slangbibledev';
const _venmoUrl = 'https://venmo.com/u/slangbibledev';
const _bitcoinAddress = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

const _welcomeTitle = "Welcome to the '80s, Dudes and Dudettes!";
const _welcomeBody =
    "You've stepped into the totally tubular 1980s slang paraphrase of "
    'Scripture. The New Testament is fully groovy and ready to read. The '
    'Old Testament is still in the works, so check back as more books '
    'drop.';
const _supportPrompt =
    'Want to help keep this project rolling? Buy me a cup of coffee:';

class SupportCard extends ConsumerWidget {
  const SupportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.read(launcherProvider);
    final themeId = ref.watch(themeProvider);

    // Matches PassageCard's outer padding (16 symmetric + 6 inset) so both
    // cards line up at the same width.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: themeId == AppThemeId.retroArcade
          ? _buildArcadeCabinet(context, launcher)
          : _buildDefaultCard(context, launcher),
    );
  }

  Widget _buildDefaultCard(BuildContext context, Launcher launcher) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _welcomeTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(_welcomeBody),
              const SizedBox(height: 12),
              const Text(_supportPrompt),
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('support-paypal-button'),
                      onPressed: () =>
                          launcher.launch(Uri.parse(_paypalUrl)),
                      icon: const Icon(Icons.attach_money),
                      label: const Text('PayPal'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('support-venmo-button'),
                      onPressed: () =>
                          launcher.launch(Uri.parse(_venmoUrl)),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Venmo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Bitcoin', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _bitcoinAddress,
                      key: const Key('support-bitcoin-address'),
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: const Key('support-bitcoin-copy-button'),
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy address',
                    onPressed: () => _copyBitcoinAddress(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArcadeCabinet(BuildContext context, Launcher launcher) {
    const screenTextStyle = TextStyle(
      color: Color(0xFFDFFFE0),
      fontFamily: 'monospace',
      height: 1.5,
    );

    return ArcadeCabinet(
      title: _welcomeTitle,
      screenChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(_welcomeBody, style: screenTextStyle),
          const SizedBox(height: 12),
          const Text(_supportPrompt, style: screenTextStyle),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('support-paypal-button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RetroColors.cream,
                    side: const BorderSide(color: RetroColors.cream),
                  ),
                  onPressed: () => launcher.launch(Uri.parse(_paypalUrl)),
                  icon: const Icon(Icons.attach_money),
                  label: const Text('PayPal'),
                ),
                OutlinedButton.icon(
                  key: const Key('support-venmo-button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RetroColors.cream,
                    side: const BorderSide(color: RetroColors.cream),
                  ),
                  onPressed: () => launcher.launch(Uri.parse(_venmoUrl)),
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Venmo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bitcoin',
            style: screenTextStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _bitcoinAddress,
                  key: const Key('support-bitcoin-address'),
                  style: screenTextStyle.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const Key('support-bitcoin-copy-button'),
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: RetroColors.cream,
                ),
                tooltip: 'Copy address',
                onPressed: () => _copyBitcoinAddress(context),
              ),
            ],
          ),
        ],
      ),
      controls: const [],
    );
  }

  Future<void> _copyBitcoinAddress(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _bitcoinAddress));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitcoin address copied')),
      );
    }
  }
}
