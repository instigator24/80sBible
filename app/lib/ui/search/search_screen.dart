import 'package:flutter/material.dart';

import '../../data/models/passage.dart';
import '../../data/passage_repository.dart';
import '../../logic/search.dart';

class SearchScreen extends StatefulWidget {
  final PassageRepository repository;
  final void Function(String book, int chapter) onOpenPassage;

  const SearchScreen({
    super.key,
    required this.repository,
    required this.onOpenPassage,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  SearchTextMode _mode = SearchTextMode.slang;
  List<Passage> _results = <Passage>[];

  void _runSearch() {
    setState(() {
      _results = searchPassages(
        widget.repository.all,
        _controller.text,
        mode: _mode,
      );
    });
  }

  void _onModeChanged(Set<SearchTextMode> selection) {
    _mode = selection.first;
    _runSearch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SegmentedButton<SearchTextMode>(
            key: const Key('search-mode-toggle'),
            segments: const [
              ButtonSegment(
                value: SearchTextMode.slang,
                label: Text('80s'),
              ),
              ButtonSegment(
                value: SearchTextMode.web,
                label: Text('WEB'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: _onModeChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: TextField(
            key: const Key('search-field'),
            controller: _controller,
            onChanged: (_) => _runSearch(),
            decoration:
                const InputDecoration(hintText: 'Search reference or keyword'),
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? const Center(
                  key: Key('no-results-message'),
                  child: Text('No results'),
                )
              : ListView(
                  children: _results
                      .map((p) => ListTile(
                            key: Key('result-${p.id}'),
                            title: Text(p.reference),
                            subtitle: Text(
                              _mode == SearchTextMode.web
                                  ? p.webText
                                  : p.slangText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => widget.onOpenPassage(p.book, p.chapter),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
