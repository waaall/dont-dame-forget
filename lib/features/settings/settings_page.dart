import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reminder_engine.dart';
import '../../domain/models.dart';
import '../../shared/strings.dart';
import '../../shared/theme.dart';
import '../../shared/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appControllerProvider).snapshot;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : SettingsPage(snapshot: snapshot),
    );
  }
}

class SettingsPage extends ConsumerStatefulWidget {
  final AppSnapshot snapshot;
  const SettingsPage({super.key, required this.snapshot});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _testing = false;
  Future<void> _settings(Map<String, dynamic> data) async {
    try {
      await ref.read(appControllerProvider).command('saveSettings', data);
    } catch (error) {
      if (mounted) context.message(context.errorLabel(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.snapshot;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(context.l10n.preferences),
                ContentCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.translate_rounded,
                        title: context.l10n.language,
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: data.settings.language,
                            items: [
                              DropdownMenuItem(
                                value: 'system',
                                child: Text(context.l10n.system),
                              ),
                              DropdownMenuItem(
                                value: 'zh',
                                child: Text(context.l10n.chinese),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(context.l10n.english),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) _settings({'language': value});
                            },
                          ),
                        ),
                      ),
                      const Divider(indent: 18, endIndent: 18),
                      _SettingRow(
                        icon: Icons.brightness_6_outlined,
                        title: context.l10n.appearance,
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: data.settings.theme,
                            items: [
                              DropdownMenuItem(
                                value: 'system',
                                child: Text(context.l10n.system),
                              ),
                              DropdownMenuItem(
                                value: 'light',
                                child: Text(context.l10n.light),
                              ),
                              DropdownMenuItem(
                                value: 'dark',
                                child: Text(context.l10n.dark),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) _settings({'theme': value});
                            },
                          ),
                        ),
                      ),
                      const Divider(indent: 18, endIndent: 18),
                      _SettingRow(
                        icon: Icons.snooze_rounded,
                        title: context.l10n.snoozeDuration,
                        trailing: Text(
                          '${context.durationLabel(data.settings.defaultSnoozeMinutes)} ›',
                        ),
                        onTap: () async {
                          final minutes = await chooseDuration(
                            context,
                            data.settings.defaultSnoozeMinutes,
                          );
                          if (minutes != null) {
                            await _settings({'defaultSnoozeMinutes': minutes});
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SectionLabel(context.l10n.emergencyPassword),
                ContentCard(
                  padding: EdgeInsets.zero,
                  child: _SettingRow(
                    icon: Icons.lock_outline_rounded,
                    title: data.settings.hasPassword
                        ? context.l10n.changePassword
                        : context.l10n.setPassword,
                    subtitle: data.settings.hasPassword
                        ? context.l10n.passwordSet
                        : context.l10n.passwordSetupBody,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        showPasswordSetup(context, data.settings.hasPassword),
                  ),
                ),
                SectionLabel(context.l10n.reliability),
                Text(
                  context.l10n.reliabilityIntro,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ContentCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _PermissionRow(
                        kind: 'exact',
                        icon: Icons.alarm_on_rounded,
                        title: context.l10n.exactPermission,
                        body: context.l10n.exactHelp,
                        allowed: data.permissions.exact,
                      ),
                      const Divider(indent: 18, endIndent: 18),
                      _PermissionRow(
                        kind: 'notifications',
                        icon: Icons.notifications_outlined,
                        title: context.l10n.notificationPermission,
                        body: context.l10n.notificationHelp,
                        allowed: data.permissions.notifications,
                      ),
                      const Divider(indent: 18, endIndent: 18),
                      _PermissionRow(
                        kind: 'fullScreen',
                        icon: Icons.fullscreen_rounded,
                        title: context.l10n.fullScreenPermission,
                        body: context.l10n.fullScreenHelp,
                        allowed: data.permissions.fullScreen,
                      ),
                      const Divider(indent: 18, endIndent: 18),
                      _PermissionRow(
                        kind: 'battery',
                        icon: Icons.battery_saver_outlined,
                        title: context.l10n.batteryPermission,
                        body: context.l10n.batteryHelp,
                        allowed: data.permissions.battery,
                        recommendation: true,
                      ),
                      const Divider(indent: 18, endIndent: 18),
                      _PermissionRow(
                        kind: 'sound',
                        icon: Icons.volume_up_outlined,
                        title: context.l10n.soundSettings,
                        body:
                            '${context.l10n.soundHelp}\n${context.l10n.alarmVolume(data.permissions.alarmVolume)}',
                        allowed: data.permissions.alarmVolume > 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testing
                        ? null
                        : () async {
                            setState(() => _testing = true);
                            try {
                              await ref
                                  .read(appControllerProvider)
                                  .command('testReminder');
                              if (context.mounted) {
                                context.message(context.l10n.testScheduled);
                              }
                            } catch (error) {
                              if (context.mounted) {
                                context.message(
                                  context.errorLabel(error),
                                  error: true,
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _testing = false);
                            }
                          },
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 19,
                    ),
                    label: Text(context.l10n.quickTest),
                  ),
                ),
                SectionLabel(context.l10n.about),
                ContentCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.offline_bolt_outlined,
                        color: AppColors.green,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.localPrivacy,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.localPrivacyBody,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.version,
                              style: TextStyle(
                                fontSize: 11,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTheme.radius),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: trailing,
          ),
        ],
      ),
    ),
  );
}

class _PermissionRow extends ConsumerWidget {
  final String kind, title, body;
  final IconData icon;
  final bool allowed, recommendation;
  const _PermissionRow({
    required this.kind,
    required this.title,
    required this.body,
    required this.icon,
    required this.allowed,
    this.recommendation = false,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    onTap: () async {
      try {
        await ref.read(engineProvider).invoke('openPermission', {'kind': kind});
      } catch (error) {
        if (context.mounted) {
          context.message(context.errorLabel(error), error: true);
        }
      }
    },
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 9),
                SoftPill(
                  allowed
                      ? context.l10n.allowed
                      : recommendation
                      ? context.l10n.recommended
                      : context.l10n.needsAttention,
                  color: allowed ? AppColors.green : AppColors.orange,
                  icon: allowed ? Icons.check_rounded : Icons.settings_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    ),
  );
}

Future<bool?> showPasswordSetup(BuildContext context, bool hasPassword) =>
    showDialog<bool>(
      context: context,
      builder: (_) => _PasswordDialog(hasPassword: hasPassword),
    );

class _PasswordDialog extends ConsumerStatefulWidget {
  final bool hasPassword;
  const _PasswordDialog({required this.hasPassword});
  @override
  ConsumerState<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<_PasswordDialog> {
  final _current = TextEditingController(),
      _password = TextEditingController(),
      _repeat = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.hasPassword
          ? context.l10n.changePassword
          : context.l10n.setPassword,
    ),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.passwordHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (widget.hasPassword) ...[
              TextField(
                controller: _current,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.l10n.currentPassword,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _password,
              obscureText: true,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: context.l10n.newPassword,
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repeat,
              obscureText: true,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: context.l10n.repeatPassword,
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.l10n.saveChanges),
      ),
    ],
  );
  Future<void> _save() async {
    if (_password.text.length < 4) {
      setState(() => _error = context.l10n.errorPasswordLength);
      return;
    }
    if (_password.text != _repeat.text) {
      setState(() => _error = context.l10n.errorPasswordMatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(appControllerProvider).command('setPassword', {
        'currentPassword': _current.text,
        'password': _password.text,
      });
      if (mounted) {
        context.message(context.l10n.passwordSaved);
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
