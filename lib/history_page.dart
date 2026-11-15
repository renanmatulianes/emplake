import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game.dart';
import 'l10n/app_localizations.dart';
import 'math_engine.dart';
import 'repository.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late final Future<Profile> _future = ref.read(repoProvider).reload();
  Level _level = Level.easy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<Profile>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(l.loadError(cloudErrorText(l, cloudError(snap.error)))));
        if (!snap.hasData) return Loading(text: l.loading);
        final p = snap.data!;
        final items = p.solved[_level]!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
          children: [
            Text(l.historyTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(l.totalScore(p.score), style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final v in Level.values)
                ChoiceChip(
                  label: Text('${levelName(l, v)} · ${l.solvedCount(p.solved[v]!.length)}'),
                  selected: v == _level,
                  onSelected: (_) => setState(() => _level = v),
                ),
            ]),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(padding: const EdgeInsets.all(32), child: Text(l.historyEmpty, textAlign: TextAlign.center)),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final e in items)
                SizedBox(
                  width: 260,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.key, style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Math.tex(e.value, textStyle: TextStyle(fontSize: 20, color: theme.colorScheme.onSurface)),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
          ],
        );
      },
    );
  }
}
