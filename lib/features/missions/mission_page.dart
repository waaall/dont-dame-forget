import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reminder_engine.dart';
import '../../domain/models.dart';
import '../../shared/strings.dart';
import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import 'scanner_page.dart';

const emergencyPledge = '我发誓我没忘，让我关上吧';

class MissionPage extends ConsumerStatefulWidget {
  final Occurrence occurrence;
  const MissionPage({super.key, required this.occurrence});
  @override
  ConsumerState<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends ConsumerState<MissionPage> {
  Map<String, dynamic>? _challenge;
  String _answer = '';
  String? _feedback;
  bool _busy = false, _leaving = false;
  late int _snooze = widget.occurrence.plan.snoozeMinutes;
  @override
  void initState() {
    super.initState();
    if (widget.occurrence.plan.mission == 'math') unawaited(_loadQuestion());
  }

  Future<void> _loadQuestion() async {
    try {
      final result = await ref.read(engineProvider).invoke('challenge', {
        'id': widget.occurrence.id,
      });
      if (mounted) {
        setState(() {
          _challenge = jsonMap(result);
          _feedback = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _feedback = context.errorLabel(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = widget.occurrence;
    final l = context.l10n;
    return PopScope(
      canPop: _leaving,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Theme(
          data: AppTheme.of(Brightness.dark),
          child: Scaffold(
            backgroundColor: AppColors.night,
            bottomNavigationBar: _snoozeFooter(context),
            body: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              categoryIcon(occurrence.plan.category),
                              color: const Color(0xFFFFB488),
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                occurrence.isReview
                                    ? l.reviewTime
                                    : l.timeToAct,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFD1B99C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          occurrence.plan.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFF8F5E9),
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        if (occurrence.plan.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              occurrence.plan.note,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFA7BCAC),
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ),
                        const SizedBox(height: 9),
                        Text(
                          occurrence.status == 'snoozed'
                              ? l.snoozedMission
                              : l.missionRequired,
                          style: const TextStyle(
                            color: Color(0xFF93AA99),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        if (occurrence.plan.mission == 'math')
                          _math(context)
                        else
                          _qr(context),
                        if (_feedback != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _feedback!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFB49D),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _snoozeFooter(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: context.l10n.holdSnooze(
                        context.durationLabel(_snooze),
                      ),
                      child: GestureDetector(
                        key: const ValueKey('hold-snooze'),
                        onLongPress: _busy ? null : _doSnooze,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 19,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: const Color(0xFF52685B)),
                            color: const Color(0xFF273B31),
                          ),
                          child: Text(
                            context.l10n.holdSnooze(
                              context.durationLabel(_snooze),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFE0E9D8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: context.l10n.chooseDuration,
                    onPressed: _busy
                        ? null
                        : () async {
                            final minutes = await chooseDuration(
                              context,
                              _snooze,
                            );
                            if (minutes != null && mounted) {
                              setState(() => _snooze = minutes);
                            }
                          },
                    icon: const Icon(
                      Icons.more_time_rounded,
                      color: Color(0xFFCBDAC6),
                      size: 23,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.holdHint,
                style: const TextStyle(color: Color(0xFF829A88), fontSize: 10),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _busy ? null : _emergency,
                child: Text(
                  context.l10n.emergency,
                  style: const TextStyle(
                    color: Color(0xFF9AAF9E),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _math(BuildContext context) {
    final question = _challenge;
    if (question == null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: _feedback == null
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: _loadQuestion,
                  child: Text(context.l10n.retry),
                ),
        ),
      );
    }
    final total = integer(question['total']);
    final done = integer(question['done']);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            total,
            (index) => Flexible(
              child: Container(
                width: 24,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index < done
                      ? const Color(0xFFFFB488)
                      : const Color(0xFF3B5142),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.mathProgress(done, total),
          style: const TextStyle(color: Color(0xFFA8BCA9), fontSize: 11),
        ),
        const SizedBox(height: 17),
        Text(
          '${question['expression']} = ?',
          style: const TextStyle(
            color: Color(0xFFFFF3DD),
            fontSize: 35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF263B30),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF536B59)),
          ),
          child: Text(
            _answer.isEmpty ? context.l10n.answerHint : _answer,
            style: TextStyle(
              fontSize: _answer.isEmpty ? 14 : 29,
              color: _answer.isEmpty ? const Color(0xFF839D8A) : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          4,
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: List.generate(3, (column) {
                final index = row * 3 + column;
                final digit = index < 9
                    ? '${index + 1}'
                    : index == 10
                    ? '0'
                    : '';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: column == 0 ? 0 : 7),
                    child: SizedBox(
                      height: 48,
                      child: index == 9
                          ? const SizedBox.shrink()
                          : Material(
                              color: const Color(0xFF24382D),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _busy
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _feedback = null;
                                          if (index == 11) {
                                            if (_answer.isNotEmpty) {
                                              _answer = _answer.substring(
                                                0,
                                                _answer.length - 1,
                                              );
                                            }
                                          } else if (_answer.length < 7) {
                                            _answer += digit;
                                          }
                                        });
                                      },
                                child: Center(
                                  child: index == 11
                                      ? Icon(
                                          Icons.backspace_outlined,
                                          semanticLabel:
                                              MaterialLocalizations.of(
                                                context,
                                              ).deleteButtonTooltip,
                                          size: 21,
                                          color: Color(0xFFD9E4D3),
                                        )
                                      : Text(
                                          digit,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: Color(0xFFF2F3E8),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy || _answer.isEmpty ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.checkAnswer),
          ),
        ),
      ],
    );
  }

  Widget _qr(BuildContext context) => Column(
    children: [
      Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFF283E31),
          borderRadius: BorderRadius.circular(29),
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          size: 76,
          color: Color(0xFFE5D5B9),
        ),
      ),
      if (widget.occurrence.plan.qrLabel.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text(
            widget.occurrence.plan.qrLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB9C9B6), fontSize: 14),
          ),
        ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final completed = await Navigator.push<bool>(
                    context,
                    appRoute(
                      (_) => ScannerPage(
                        onValue: (value) async {
                          await ref.read(appControllerProvider).command(
                            'scanCode',
                            {'id': widget.occurrence.id, 'value': value},
                          );
                        },
                      ),
                    ),
                  );
                  if (completed == true && mounted) _finish(false);
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
          label: Text(context.l10n.startScanning),
        ),
      ),
    ],
  );
  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final result = jsonMap(
        await ref.read(appControllerProvider).command('answerMath', {
          'id': widget.occurrence.id,
          'answer': _answer,
          'token': _challenge!['token'],
        }),
      );
      if (!mounted) return;
      if (result['completed'] == true) {
        _finish(false);
        return;
      }
      setState(() {
        _answer = '';
        if (result['correct'] == true) {
          _challenge = jsonMap(result['challenge']);
        } else {
          _feedback = context.l10n.wrongAnswer;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _feedback = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doSnooze() async {
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      await ref.read(appControllerProvider).command('snooze', {
        'id': widget.occurrence.id,
        'minutes': _snooze,
      });
      if (mounted) _leave();
    } catch (error) {
      if (mounted) setState(() => _feedback = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emergency() async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EmergencySheet(occurrenceId: widget.occurrence.id),
    );
    if (completed == true && mounted) _finish(true);
  }

  void _finish(bool skipped) {
    final next = ref
        .read(appControllerProvider)
        .snapshot
        ?.occurrences
        .where((item) => item.id == widget.occurrence.id)
        .firstOrNull;
    context.message(
      skipped
          ? context.l10n.emergencyCompleted
          : next?.status == 'reviewPending'
          ? context.l10n.followUpScheduled
          : context.l10n.missionCompleted,
    );
    HapticFeedback.heavyImpact();
    _leave();
  }

  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }
}

class EmergencySheet extends ConsumerStatefulWidget {
  final String occurrenceId;
  const EmergencySheet({super.key, required this.occurrenceId});
  @override
  ConsumerState<EmergencySheet> createState() => _EmergencySheetState();
}

class _EmergencySheetState extends ConsumerState<EmergencySheet> {
  final _phrase = TextEditingController(), _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _phrase.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      26,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.emergency,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.emergencyHelp,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.pledgeLabel, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 9),
        const Text(
          emergencyPledge,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('emergency-phrase'),
          controller: _phrase,
          enableInteractiveSelection: false,
          autocorrect: false,
          enableSuggestions: false,
          contextMenuBuilder: (_, _) => const SizedBox.shrink(),
          decoration: InputDecoration(labelText: context.l10n.pledgeLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('emergency-password'),
          controller: _password,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(labelText: context.l10n.password),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(context.l10n.confirmEmergency),
        ),
      ],
    ),
  );
  Future<void> _submit() async {
    if (_phrase.text != emergencyPledge) {
      setState(() => _error = context.l10n.errorOath);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(appControllerProvider).command('emergencyClose', {
        'id': widget.occurrenceId,
        'phrase': _phrase.text,
        'password': _password.text,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
