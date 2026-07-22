import 'package:flutter/material.dart';

import '../../data/passage_repository.dart';
import '../../logic/verse_of_the_day.dart';
import '../reader/passage_card.dart';
import 'support_card.dart';

class HomeScreen extends StatelessWidget {
  final PassageRepository repository;
  final void Function(String book, int chapter) onOpenPassage;
  final DateTime? today;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.onOpenPassage,
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    final all = repository.all;
    if (all.isEmpty) {
      return const Center(child: Text('No content available yet'));
    }

    final verse = pickVerseOfTheDay(all, today ?? DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verse of the Day',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('verse-of-the-day-card'),
            onTap: () => onOpenPassage(verse.book, verse.chapter),
            child: PassageCard(passage: verse),
          ),
          const SupportCard(),
        ],
      ),
    );
  }
}
