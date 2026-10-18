import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/reminder_engine.dart';
import '../../domain/models.dart';
import '../../shared/strings.dart';
import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import '../missions/scanner_page.dart';
import '../settings/settings_page.dart';

class ReminderEditor extends ConsumerStatefulWidget {
  final Reminder? reminder;
  final String? template;
  const ReminderEditor({super.key, this.reminder, this.template});
  @override
  ConsumerState<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<ReminderEditor> {
  final _name = TextEditingController(),
      _note = TextEditingController(),
      _codeLabel = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  String _category = 'todo', _mission = 'math', _difficulty = 'easy', _qr = '';
  int _mathCount = 3, _snooze = 10, _reviewMinutes = 10;
  bool _repeating = false,
      _review = false,
      _vibrate = true,
      _busy = false,
      _initialized = false;
  Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  String? _error;
  @override
  void initState() {
    super.initState();
    final next = DateTime.now().add(const Duration(minutes: 5));
    _date = next;
    _time = TimeOfDay.fromDateTime(next);
    _snooze =
        ref
            .read(appControllerProvider)
            .snapshot
            ?.settings
            .defaultSnoozeMinutes ??
        10;
    final plan = widget.reminder;
    if (plan != null) {
      _name.text = plan.title;
      _note.text = plan.note;
      _codeLabel.text = plan.qrLabel;
      _date = DateTime.parse(plan.date);
      _time = plan.time;
      _category = plan.category;
      _mission = plan.mission;
      _difficulty = plan.difficulty;
      _qr = plan.qrValue;
      _mathCount = plan.mathCount;
      _snooze = plan.snoozeMinutes;
      _reviewMinutes = plan.reviewMinutes;
      _repeating = plan.repeating;
      _review = plan.reviewEnabled;
      _vibrate = plan.vibrate;
      _days = plan.days.toSet();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.reminder != null) return;
    switch (widget.template) {
      case 'alarm':
        _name.text = context.l10n.wakeUp;
        _category = 'alarm';
        _repeating = true;
        _time = const TimeOfDay(hour: 7, minute: 0);
      case 'laundry':
        _name.text = context.l10n.laundry;
        _category = 'todo';
        _mission = 'qr';
        _date = DateTime.now().add(const Duration(minutes: 30));
        _time = TimeOfDay.fromDateTime(_date);
      case 'habit':
        _name.text = context.l10n.drinkWater;
        _category = 'habit';
        _repeating = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _codeLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reminder == null ? l.createReminder : l.editReminder,
        ),
        actions: [
          if (widget.reminder != null)
            IconButton(
              tooltip: l.delete,
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _name,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: l.nameLabel,
                            hintText: l.nameHint,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _note,
                          maxLength: 300,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l.noteLabel,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: ['alarm', 'todo', 'habit', 'other']
                              .map(
                                (category) => ChoiceChip(
                                  avatar: Icon(
                                    categoryIcon(category),
                                    size: 16,
                                  ),
                                  label: Text(context.categoryLabel(category)),
                                  selected: _category == category,
                                  onSelected: (_) =>
                                      setState(() => _category = category),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  SectionLabel(l.schedule),
                  ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final value = await showTimePicker(
                                context: context,
                                initialTime: _time,
                              );
                              if (value != null) setState(() => _time = value);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 7,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 19,
                                      color: AppColors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            _repeatChip(
                              l.once,
                              !_repeating,
                              () => setState(() => _repeating = false),
                            ),
                            _repeatChip(
                              l.everyDay,
                              _repeating && _days.length == 7,
                              () => setState(() {
                                _repeating = true;
                                _days = {1, 2, 3, 4, 5, 6, 7};
                              }),
                            ),
                            _repeatChip(
                              l.weekdays,
                              _repeating &&
                                  _days.length == 5 &&
                                  _days.every((day) => day <= 5),
                              () => setState(() {
                                _repeating = true;
                                _days = {1, 2, 3, 4, 5};
                              }),
                            ),
                            _repeatChip(
                              l.custom,
                              _repeating &&
                                  _days.length != 7 &&
                                  !(_days.length == 5 &&
                                      _days.every((day) => day <= 5)),
                              () => setState(() {
                                _repeating = true;
                                if (_days.length == 7) {
                                  _days = {DateTime.now().weekday};
                                }
                              }),
                            ),
                          ],
                        ),
                        if (_repeating) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: List.generate(7, (index) {
                              final day = index + 1;
                              return FilterChip(
                                label: Text(
                                  DateFormat.E(
                                    Localizations.localeOf(
                                      context,
                                    ).toLanguageTag(),
                                  ).format(DateTime(2026, 10, 12 + index)),
                                ),
                                selected: _days.contains(day),
                                showCheckmark: false,
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    _days.add(day);
                                  } else {
                                    _days.remove(day);
                                  }
                                }),
                              );
                            }),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final today = DateUtils.dateOnly(DateTime.now());
                              final value = await showDatePicker(
                                context: context,
                                initialDate: _date.isBefore(today)
                                    ? today
                                    : _date,
                                firstDate: today,
                                lastDate: today.add(const Duration(days: 3650)),
                              );
                              if (value != null) setState(() => _date = value);
                            },
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 17,
                            ),
                            label: Text(
                              DateFormat.yMMMd(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).format(_date),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SectionLabel(l.mission),
                  ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'math',
                              icon: const Icon(Icons.calculate_outlined),
                              label: Text(l.mathMission),
                            ),
                            ButtonSegment(
                              value: 'qr',
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: Text(l.qrMission),
                            ),
                          ],
                          selected: {_mission},
                          onSelectionChanged: (selection) =>
                              setState(() => _mission = selection.first),
                          showSelectedIcon: false,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _mission == 'math'
                              ? l.mathDescription
                              : l.qrDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_mission == 'math') ...[
                          Wrap(
                            spacing: 8,
                            children: ['easy', 'medium', 'hard']
                                .map(
                                  (difficulty) => ChoiceChip(
                                    label: Text(switch (difficulty) {
                                      'easy' => l.easy,
                                      'medium' => l.medium,
                                      _ => l.hard,
                                    }),
                                    selected: _difficulty == difficulty,
                                    onSelected: (_) => setState(
                                      () => _difficulty = difficulty,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.questionCount,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                onPressed: _mathCount > 1
                                    ? () => setState(() => _mathCount--)
                                    : null,
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                              ),
                              Text(
                                '$_mathCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                onPressed: _mathCount < 10
                                    ? () => setState(() => _mathCount++)
                                    : null,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    _PracticeDialog(difficulty: _difficulty),
                              ),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: Text(l.tryMission),
                            ),
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: () async {
                              final code = await Navigator.push<String>(
                                context,
                                appRoute((_) => const ScannerPage()),
                              );
                              if (code != null) setState(() => _qr = code);
                            },
                            icon: Icon(
                              _qr.isEmpty
                                  ? Icons.qr_code_scanner_rounded
                                  : Icons.check_circle_outline_rounded,
                            ),
                            label: Text(
                              _qr.isEmpty ? l.registerCode : l.changeCode,
                            ),
                          ),
                          if (_qr.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              l.codeRegistered,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 13),
                          TextField(
                            controller: _codeLabel,
                            maxLength: 80,
                            decoration: InputDecoration(
                              labelText: l.codeLabel,
                              hintText: l.codeLabelHint,
                              counterText: '',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SectionLabel(l.snooze),
                  ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l.snoozeDuration,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Text(
                            '${context.durationLabel(_snooze)} ›',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () async {
                            final value = await chooseDuration(
                              context,
                              _snooze,
                            );
                            if (value != null) setState(() => _snooze = value);
                          },
                        ),
                        Text(
                          l.snoozeHelp,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionLabel(l.review),
                  ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l.review,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            l.reviewHelp,
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _review,
                          onChanged: (value) => setState(() => _review = value),
                        ),
                        if (_review)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l.reviewDuration,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Text(
                              '${context.durationLabel(_reviewMinutes)} ›',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            onTap: () async {
                              final value = await chooseDuration(
                                context,
                                _reviewMinutes,
                              );
                              if (value != null) {
                                setState(() => _reviewMinutes = value);
                              }
                            },
                          ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l.vibrate,
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: _vibrate,
                          onChanged: (value) =>
                              setState(() => _vibrate = value),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(l.save),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _repeatChip(String label, bool selected, VoidCallback onTap) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
  Future<void> _save() async {
    final l = context.l10n;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l.errorTitle);
      return;
    }
    if (_repeating && _days.isEmpty) {
      setState(() => _error = l.errorDays);
      return;
    }
    if (_mission == 'qr' && _qr.isEmpty) {
      setState(() => _error = l.errorQrRequired);
      return;
    }
    final snapshot = ref.read(appControllerProvider).snapshot!;
    if (!snapshot.settings.hasPassword) {
      final saved = await showPasswordSetup(context, false);
      if (saved != true || !mounted) return;
    }
    if (!ref.read(appControllerProvider).snapshot!.permissions.ready) {
      await Navigator.push(context, appRoute((_) => const SettingsScreen()));
      if (!mounted) return;
      await ref.read(appControllerProvider).refresh();
      if (!ref.read(appControllerProvider).snapshot!.permissions.ready) {
        if (mounted) setState(() => _error = context.l10n.setupBody);
        return;
      }
    }
    final plan = Reminder(
      id: widget.reminder?.id ?? '',
      title: _name.text.trim(),
      note: _note.text.trim(),
      category: _category,
      mission: _mission,
      difficulty: _difficulty,
      qrValue: _qr,
      qrLabel: _codeLabel.text.trim(),
      date: DateFormat('yyyy-MM-dd').format(_date),
      hour: _time.hour,
      minute: _time.minute,
      mathCount: _mathCount,
      snoozeMinutes: _snooze,
      reviewMinutes: _reviewMinutes,
      enabled: true,
      repeating: _repeating,
      reviewEnabled: _review,
      vibrate: _vibrate,
      days: (_days.toList()..sort()),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(appControllerProvider)
          .command('saveReminder', plan.toJson());
      if (mounted) {
        context.message(context.l10n.saved);
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteTitle),
        content: Text(context.l10n.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(appControllerProvider).command('deleteReminder', {
        'id': widget.reminder!.id,
      });
      if (mounted) {
        context.message(context.l10n.deleted);
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PracticeDialog extends StatefulWidget {
  final String difficulty;
  const _PracticeDialog({required this.difficulty});
  @override
  State<_PracticeDialog> createState() => _PracticeDialogState();
}

class _PracticeDialogState extends State<_PracticeDialog> {
  final _answer = TextEditingController();
  late final int _a =
      Random().nextInt(widget.difficulty == 'easy' ? 10 : 60) + 2;
  late final int _b =
      Random().nextInt(widget.difficulty == 'hard' ? 12 : 8) + 2;
  String? _feedback;
  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.previewMission),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.previewBody,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text(
          '$_a ${widget.difficulty == 'easy' ? '+' : '×'} $_b = ?',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _answer,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.answerHint),
        ),
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_feedback!),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.done),
      ),
      FilledButton(
        onPressed: () {
          final expected = widget.difficulty == 'easy' ? _a + _b : _a * _b;
          setState(
            () => _feedback = int.tryParse(_answer.text) == expected
                ? context.l10n.practiceCorrect
                : context.l10n.wrongAnswer,
          );
        },
        child: Text(context.l10n.checkAnswer),
      ),
    ],
  );
}
