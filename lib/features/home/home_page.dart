import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/reminder_engine.dart';
import '../../domain/models.dart';
import '../../shared/strings.dart';
import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import '../editor/reminder_editor.dart';

class HomePage extends StatefulWidget {
  final AppSnapshot snapshot;
  final VoidCallback onSettings;
  final ValueChanged<Occurrence> onResolve;
  const HomePage({
    super.key,
    required this.snapshot,
    required this.onSettings,
    required this.onResolve,
  });
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _pending = false;
  @override
  Widget build(BuildContext context) {
    final data = widget.snapshot;
    final next = data.occurrences.firstOrNull;
    final plans = [...data.plans]
      ..sort((a, b) {
        if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
        return (a.nextAt?.millisecondsSinceEpoch ?? 1 << 61).compareTo(
          b.nextAt?.millisecondsSinceEpoch ?? 1 << 61,
        );
      });
    final visible = _pending
        ? plans.where((plan) => plan.protected).toList()
        : plans;
    return RefreshIndicator(
      onRefresh: () => ProviderScope.containerOf(
        context,
      ).read(appControllerProvider).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 110),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.MMMMEEEEd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(DateTime.now()),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    context.l10n.tagline,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 21, height: 1.6),
                  ),
                  const SizedBox(height: 22),
                  if (!data.settings.hasPassword ||
                      data.permissions.needsAttention) ...[
                    _SetupNotice(
                      password: !data.settings.hasPassword,
                      onTap: widget.onSettings,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (next != null)
                    _NextCard(
                      occurrence: next,
                      onTap: () => _open(context, next.planId),
                    ),
                  if (plans.isEmpty)
                    EmptyContent(
                      icon: Icons.alarm_on_rounded,
                      title: context.l10n.noReminders,
                      body: context.l10n.noRemindersBody,
                      action: FilledButton.icon(
                        onPressed: () => _create(context),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(context.l10n.createReminder),
                      ),
                    ),
                  if (plans.isNotEmpty) ...[
                    SectionLabel(
                      context.l10n.plans,
                      trailing: SegmentedButton<bool>(
                        expandedInsets: EdgeInsets.zero,
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          minimumSize: WidgetStatePropertyAll(Size(0, 36)),
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 10),
                          ),
                          textStyle: WidgetStatePropertyAll(
                            TextStyle(fontSize: 12, fontFamily: 'Roboto'),
                          ),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(context.l10n.all),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(context.l10n.pending),
                          ),
                        ],
                        selected: {_pending},
                        onSelectionChanged: (value) =>
                            setState(() => _pending = value.first),
                      ),
                    ),
                    if (visible.isEmpty)
                      EmptyContent(
                        icon: Icons.done_all_rounded,
                        title: context.l10n.noPending,
                        body: context.l10n.noPendingBody,
                      ),
                    ...visible.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReminderCard(
                          plan: plan,
                          onTap: () => _open(context, plan.id),
                        ),
                      ),
                    ),
                  ],
                  SectionLabel(context.l10n.quickStart),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TemplateChip(
                        icon: Icons.wb_sunny_outlined,
                        label: context.l10n.wakeUp,
                        onTap: () => _create(context, 'alarm'),
                      ),
                      _TemplateChip(
                        icon: Icons.local_laundry_service_outlined,
                        label: context.l10n.laundry,
                        onTap: () => _create(context, 'laundry'),
                      ),
                      _TemplateChip(
                        icon: Icons.water_drop_outlined,
                        label: context.l10n.drinkWater,
                        onTap: () => _create(context, 'habit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _create(BuildContext context, [String? template]) => Navigator.push(
    context,
    appRoute((_) => ReminderEditor(template: template)),
  );
  void _open(BuildContext context, String id) {
    final occurrence = widget.snapshot.occurrenceFor(id);
    if (occurrence?.canResolve == true) {
      widget.onResolve(occurrence!);
      return;
    }
    if (occurrence?.status == 'reviewPending') {
      context.message(
        '${context.l10n.waitingReview} · ${context.scheduledLabel(occurrence!.nextAt)}',
      );
      return;
    }
    final plan = widget.snapshot.plans
        .where((plan) => plan.id == id)
        .firstOrNull;
    if (plan != null) {
      Navigator.push(context, appRoute((_) => ReminderEditor(reminder: plan)));
    }
  }
}

class _SetupNotice extends StatelessWidget {
  final bool password;
  final VoidCallback onTap;
  const _SetupNotice({required this.password, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.orange.withValues(alpha: .08),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppColors.orange,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                password ? context.l10n.setupPassword : context.l10n.setupTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.orange,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NextCard extends StatelessWidget {
  final Occurrence occurrence;
  final VoidCallback onTap;
  const _NextCard({required this.occurrence, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.night,
    borderRadius: BorderRadius.circular(26),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2B48C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.nextReminder,
                    style: const TextStyle(
                      color: Color(0xFFD5DED1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                Icon(
                  categoryIcon(occurrence.plan.category),
                  color: const Color(0xFFA8B9AB),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              DateFormat.Hm().format(occurrence.nextAt),
              style: const TextStyle(
                color: Color(0xFFFFF3DF),
                fontSize: 54,
                fontWeight: FontWeight.w300,
                height: 1.1,
                letterSpacing: -2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              occurrence.plan.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${context.scheduledLabel(occurrence.nextAt)} · ${context.statusLabel(occurrence.status)}',
                    style: const TextStyle(
                      color: Color(0xFFB9C9BA),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFF2B48C),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Countdown(at: occurrence.nextAt),
          ],
        ),
      ),
    ),
  );
}

class _Countdown extends StatefulWidget {
  final DateTime at;
  const _Countdown({required this.at});
  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = widget.at
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 9999999);
    final duration =
        '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Text(
      context.l10n.nextIn(duration),
      style: const TextStyle(
        color: Color(0xFF8FA896),
        fontSize: 11,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder plan;
  final VoidCallback onTap;
  const _ReminderCard({required this.plan, required this.onTap});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final categoryColor = AppColors.category(plan.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      categoryIcon(plan.category),
                      size: 21,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      plan.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: plan.enabled
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (plan.protected)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    )
                  else
                    Switch(
                      value: plan.enabled,
                      onChanged: (enabled) async {
                        try {
                          await ref.read(appControllerProvider).command(
                            'setEnabled',
                            {'id': plan.id, 'enabled': enabled},
                          );
                        } catch (error) {
                          if (context.mounted) {
                            context.message(
                              context.errorLabel(error),
                              error: true,
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    plan.nextAt == null
                        ? plan.time.format(context)
                        : DateFormat.Hm().format(plan.nextAt!),
                    style: TextStyle(
                      fontSize: 29,
                      height: 1.1,
                      fontWeight: FontWeight.w400,
                      color: plan.enabled
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      context.repeatLabel(plan),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  SoftPill(
                    plan.mission == 'qr'
                        ? context.l10n.qrMission
                        : context.l10n.mathMission,
                    color: categoryColor,
                    icon: plan.mission == 'qr'
                        ? Icons.qr_code_scanner_rounded
                        : Icons.calculate_outlined,
                  ),
                  if (plan.protected)
                    SoftPill(
                      context.statusLabel(plan.occurrenceStatus),
                      color: AppColors.orange,
                    )
                  else if (plan.reviewEnabled)
                    SoftPill(context.l10n.review, color: AppColors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TemplateChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onPressed: onTap,
    backgroundColor: Theme.of(context).colorScheme.surface,
    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
  );
}
