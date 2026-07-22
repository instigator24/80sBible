import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_books.dart';
import '../../data/models/passage.dart';
import '../../data/passage_repository.dart';
import 'passage_card.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final PassageRepository repository;
  final String? initialBook;
  final int? initialChapter;

  const ReaderScreen({
    super.key,
    required this.repository,
    this.initialBook,
    this.initialChapter,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late String _selectedBook;
  int? _selectedChapter;

  @override
  void initState() {
    super.initState();
    final available = widget.repository.availableBooks;
    _selectedBook = widget.initialBook ??
        (available.isNotEmpty ? available.first : kAllBibleBooks.first);
    final chapters = widget.repository.chaptersFor(_selectedBook);
    _selectedChapter =
        widget.initialChapter ?? (chapters.isNotEmpty ? chapters.first : null);
  }

  void _onBookChanged(String book) {
    setState(() {
      _selectedBook = book;
      final chapters = widget.repository.chaptersFor(book);
      _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
    });
  }

  Future<void> _showBookPicker() async {
    // A plain DropdownButton lazily builds only the menu items near the
    // current selection (its menu is a sliver-backed ListView), so with all
    // 66 books listed, entries far from the selected book never get
    // inflated into the widget tree. A modal sheet with a plain Column
    // builds every item eagerly, so any book is always findable/tappable.
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: kAllBibleBooks
                .map(
                  (book) => ListTile(
                    title: Text(book),
                    selected: book == _selectedBook,
                    onTap: () => Navigator.of(context).pop(book),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    _onBookChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.repository.chaptersFor(_selectedBook);
    final passages = _selectedChapter != null
        ? widget.repository.passagesFor(_selectedBook, _selectedChapter!)
        : <Passage>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OutlinedButton(
                key: const Key('book-dropdown'),
                onPressed: _showBookPicker,
                child: Text(_selectedBook),
              ),
              const SizedBox(width: 12),
              if (chapters.isNotEmpty)
                DropdownButton<int>(
                  key: const Key('chapter-dropdown'),
                  value: _selectedChapter,
                  items: chapters
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text('Chapter $c')))
                      .toList(),
                  onChanged: (chapter) {
                    if (chapter != null) setState(() => _selectedChapter = chapter);
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: passages.isNotEmpty
              ? ListView(
                  children:
                      passages.map((p) => PassageCard(passage: p)).toList(),
                )
              : const Center(
                  key: Key('not-translated-message'),
                  child: Text('Not translated yet'),
                ),
        ),
      ],
    );
  }
}
