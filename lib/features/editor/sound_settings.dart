import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reminder_engine.dart';
import '../../core/route_observer.dart';
import '../../domain/models.dart';
import '../../shared/strings.dart';
import '../../shared/widgets.dart';

class SoundSettings extends ConsumerStatefulWidget {
  final ReminderSound value;
  final ValueChanged<ReminderSound> onChanged;
  final bool vibrate;
  final ValueChanged<bool> onVibrateChanged;
  const SoundSettings({
    super.key,
    required this.value,
    required this.onChanged,
    required this.vibrate,
    required this.onVibrateChanged,
  });
  @override
  ConsumerState<SoundSettings> createState() => _SoundSettingsState();
}

class _SoundSettingsState extends ConsumerState<SoundSettings>
    with WidgetsBindingObserver, RouteAware {
  late final ReminderEngine _engine;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _engine = ref.read(engineProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    unawaited(_stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_stop());
  }

  Future<void> _stop() async {
    try {
      await _engine.invoke('stopSoundPreview');
    } catch (_) {
      /* Native onPause also stops previews. */
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    unawaited(_stop());
    super.dispose();
  }

  Future<void> _change(ReminderSound sound) async {
    await _stop();
    if (mounted) widget.onChanged(sound);
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _engine.invoke('pickSound', {
        'soundUri': widget.value.uri,
      });
      if (result != null && mounted) {
        final data = jsonMap(result);
        widget.onChanged(
          widget.value.copyWith(
            uri: data['soundUri'] as String,
            name: data['soundName'] as String,
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview(bool playing) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(appControllerProvider)
          .command(
            playing ? 'stopSoundPreview' : 'previewSound',
            widget.value.toJson(),
          );
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSystemSound() async {
    try {
      await _engine.invoke('openPermission', {'kind': 'sound'});
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(appControllerProvider).snapshot;
    final playing = state?.soundPreviewPlaying ?? false;
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l.soundAndVibration),
        ContentCard(
          semanticContainer: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                key: const ValueKey('choose-sound'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.alarmSound),
                subtitle: Text(
                  value.uri.isEmpty
                      ? l.systemDefaultSound
                      : (value.name.isEmpty ? l.selectedSound : value.name),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy ? null : _pick,
              ),
              if (value.uri.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _change(
                            const ReminderSound().copyWith(
                              volumePercent: value.volumePercent,
                              fadeInSeconds: value.fadeInSeconds,
                            ),
                          ),
                    child: Text(l.useDefaultSound),
                  ),
                ),
              const Divider(),
              Text(l.reminderVolume(value.volumePercent)),
              Slider(
                key: const ValueKey('sound-volume'),
                value: value.volumePercent.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                label: '${value.volumePercent}%',
                semanticFormatterCallback: (volume) =>
                    l.reminderVolume(volume.round()),
                onChanged: _busy
                    ? null
                    : (volume) {
                        unawaited(
                          _change(
                            value.copyWith(volumePercent: volume.round()),
                          ),
                        );
                      },
              ),
              Text(
                l.volumeLimitHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (state?.permissions.alarmVolume == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.alarmVolumeZero,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openSystemSound,
                  icon: const Icon(Icons.volume_up_outlined, size: 18),
                  label: Text(
                    l.alarmVolume(state?.permissions.alarmVolume ?? 0),
                  ),
                ),
              ),
              const Divider(),
              Text(l.fadeIn),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [0, 15, 30, 60, 120]
                    .map(
                      (seconds) => ChoiceChip(
                        key: ValueKey('sound-fade-$seconds'),
                        label: Text(
                          seconds == 0 ? l.fadeOff : l.soundSeconds(seconds),
                        ),
                        selected: value.fadeInSeconds == seconds,
                        onSelected: _busy
                            ? null
                            : (_) => _change(
                                value.copyWith(fadeInSeconds: seconds),
                              ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('preview-sound'),
                onPressed: _busy ? null : () => _preview(playing),
                icon: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(playing ? l.stopSoundPreview : l.previewSound),
              ),
              Text(
                l.soundPreviewHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if ((state?.soundPreviewFallback ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.soundFallbackHelp),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.vibrate),
                value: widget.vibrate,
                onChanged: widget.onVibrateChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
