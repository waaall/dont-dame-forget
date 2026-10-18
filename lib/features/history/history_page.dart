import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models.dart';
import '../../shared/strings.dart';
import '../../shared/theme.dart';
import '../../shared/widgets.dart';

class HistoryPage extends StatelessWidget {
  final AppSnapshot snapshot;
  const HistoryPage({super.key, required this.snapshot});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.activityTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(height: 1.6),
                ),
                SectionLabel(context.l10n.lastSevenDays),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: context.l10n.completed,
                        value: snapshot.weeklyStats['completed'] ?? 0,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(
                        label: context.l10n.snoozes,
                        value: snapshot.weeklyStats['snoozed'] ?? 0,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(
                        label: context.l10n.skipped,
                        value: snapshot.weeklyStats['skipped'] ?? 0,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
                SectionLabel(context.l10n.recentActivity),
                if (snapshot.history.isEmpty)
                  EmptyContent(
                    icon: Icons.history_rounded,
                    title: context.l10n.noActivity,
                    body: context.l10n.noActivityBody,
                  ),
                ...snapshot.history.map((event) {
                  final color = switch (event.kind) {
                    'completed' => AppColors.green,
                    'skipped' => AppColors.purple,
                    _ => AppColors.orange,
                  };
                  final icon = switch (event.kind) {
                    'completed' => Icons.check_rounded,
                    'skipped' => Icons.lock_open_rounded,
                    'snoozed' => Icons.snooze_rounded,
                    'reviewScheduled' => Icons.update_rounded,
                    _ => Icons.notifications_outlined,
                  };
                  final label = switch (event.kind) {
                    'completed' => context.l10n.eventCompleted,
                    'skipped' => context.l10n.eventSkipped,
                    'snoozed' =>
                      '${context.l10n.eventSnoozed} · ${context.durationLabel(event.minutes ?? 10)}',
                    'reviewScheduled' =>
                      '${context.l10n.eventReview} · ${context.durationLabel(event.minutes ?? 10)}',
                    'soundFallback' => context.l10n.eventSound,
                    _ => context.l10n.eventRinging,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ContentCard(
                      padding: const EdgeInsets.all(17),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(icon, size: 19, color: color),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  DateFormat.MMMd(
                                    Localizations.localeOf(
                                      context,
                                    ).toLanguageTag(),
                                  ).add_Hm().format(event.at),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => ContentCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
