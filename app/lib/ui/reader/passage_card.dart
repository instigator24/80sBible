import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/passage.dart';
import '../../logic/bookmarks_provider.dart';
import '../../logic/sharer.dart';
import '../../logic/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/arcade_cabinet.dart';
import '../theme/retro_theme.dart';
import '../theme/theme_decoration.dart';

class PassageCard extends ConsumerStatefulWidget {
  final Passage passage;

  const PassageCard({super.key, required this.passage});

  @override
  ConsumerState<PassageCard> createState() => _PassageCardState();
}

class _PassageCardState extends ConsumerState<PassageCard> {
  bool _showWeb = false;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final passage = widget.passage;
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.contains(passage.id);
    final themeId = ref.watch(themeProvider);

    return RepaintBoundary(
      key: _boundaryKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: themeId == AppThemeId.retroArcade
            ? _buildArcadeCabinet(context, passage, isBookmarked)
            : _buildDefaultCard(context, passage, isBookmarked, themeId),
      ),
    );
  }

  Widget _buildDefaultCard(
    BuildContext context,
    Passage passage,
    bool isBookmarked,
    AppThemeId themeId,
  ) {
    return Stack(
      children: [
        Positioned.fill(child: decorationForTheme(themeId)),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passage.reference,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showWeb ? passage.webText : passage.slangText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        key: const Key('toggle-web-slang'),
                        onPressed: () => setState(() => _showWeb = !_showWeb),
                        child: Text(_showWeb ? 'Show slang' : 'Show WEB'),
                      ),
                      IconButton(
                        key: const Key('bookmark-button'),
                        icon: Icon(
                          isBookmarked ? Icons.star : Icons.star_border,
                        ),
                        onPressed: () => ref
                            .read(bookmarksProvider.notifier)
                            .toggle(passage.id),
                      ),
                      IconButton(
                        key: const Key('share-text-button'),
                        icon: const Icon(Icons.share),
                        onPressed: () => ref.read(sharerProvider).shareText(
                              '${passage.reference}\n${passage.slangText}',
                            ),
                      ),
                      IconButton(
                        key: const Key('share-image-button'),
                        icon: const Icon(Icons.image),
                        onPressed: _shareAsImage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArcadeCabinet(
    BuildContext context,
    Passage passage,
    bool isBookmarked,
  ) {
    return ArcadeCabinet(
      title: passage.reference,
      screenChild: Text(
        _showWeb ? passage.webText : passage.slangText,
        style: const TextStyle(
          color: Color(0xFFDFFFE0),
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
      controls: [
        ArcadeButton(
          key: const Key('toggle-web-slang'),
          icon: _showWeb ? Icons.font_download : Icons.tv,
          color: RetroColors.yellow,
          tooltip: _showWeb ? 'Show slang' : 'Show WEB',
          onPressed: () => setState(() => _showWeb = !_showWeb),
        ),
        ArcadeButton(
          key: const Key('bookmark-button'),
          icon: isBookmarked ? Icons.star : Icons.star_border,
          color: RetroColors.red,
          tooltip: 'Bookmark',
          onPressed: () =>
              ref.read(bookmarksProvider.notifier).toggle(passage.id),
        ),
        ArcadeButton(
          key: const Key('share-text-button'),
          icon: Icons.share,
          color: RetroColors.blue,
          tooltip: 'Share text',
          onPressed: () => ref
              .read(sharerProvider)
              .shareText('${passage.reference}\n${passage.slangText}'),
        ),
        ArcadeButton(
          key: const Key('share-image-button'),
          icon: Icons.image,
          color: RetroColors.green,
          tooltip: 'Share image',
          onPressed: _shareAsImage,
        ),
      ],
    );
  }

  Future<void> _shareAsImage() async {
    // RenderRepaintBoundary.toImage() asserts !debugNeedsPaint. Called
    // synchronously from a tap handler, the button's own ink-splash visual
    // feedback hasn't painted yet, so defer the capture to the end of the
    // current frame (post-frame callbacks run after paint completes).
    // scheduleFrame() ensures a frame actually happens rather than relying
    // on incidental animation-driven frames (e.g. the button's ink splash).
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    WidgetsBinding.instance.scheduleFrame();
    await completer.future;
    if (!mounted) return;

    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    if (!mounted) {
      image.dispose();
      return;
    }

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (!mounted) return;
      await ref
          .read(sharerProvider)
          .shareImage(bytes, filename: '${widget.passage.id}.png');
    } finally {
      image.dispose();
    }
  }
}
