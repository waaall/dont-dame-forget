import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/reminder_engine.dart';
import 'domain/models.dart';
import 'features/home/home_page.dart';
import 'features/history/history_page.dart';
import 'features/settings/settings_page.dart';
import 'features/missions/mission_page.dart';
import 'features/editor/reminder_editor.dart';
import 'l10n/app_localizations.dart';
import 'shared/strings.dart';
import 'shared/theme.dart';
import 'shared/widgets.dart';

class DontForgetApp extends ConsumerWidget {
  const DontForgetApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appControllerProvider).snapshot?.settings ??
        const UserSettings();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.of(Brightness.light),
      darkTheme: AppTheme.of(Brightness.dark),
      themeMode: settings.themeMode,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  String? _missionId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appControllerProvider).refresh());
    }
  }

  void _considerAlarm(AppSnapshot snapshot) {
    if (_missionId != null) return;
    final ringing = snapshot.occurrences
        .where((item) => item.status == 'ringing')
        .firstOrNull;
    if (ringing == null) return;
    _openMission(ringing);
  }

  void _openMission(Occurrence occurrence) {
    if (_missionId != null) return;
    _missionId = occurrence.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(appRoute((_) => MissionPage(occurrence: occurrence)));
      _missionId = null;
      if (mounted) {
        await ref.read(appControllerProvider).refresh();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final snapshot = controller.snapshot;
    if (snapshot == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: controller.startupError == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(context.l10n.loading),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 54,
                            color: AppColors.orange,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.startupFailed,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.startupHelp,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: controller.refresh,
                            child: Text(context.l10n.retry),
                          ),
                          ExpansionTile(
                            title: Text(context.l10n.errorDetails),
                            children: [
                              SelectableText(
                                controller.startupError.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }
    _considerAlarm(snapshot);
    final pages = [
      HomePage(
        snapshot: snapshot,
        onSettings: () => setState(() => _tab = 2),
        onResolve: _openMission,
      ),
      HistoryPage(snapshot: snapshot),
      SettingsPage(snapshot: snapshot),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Flexible(
              child: Text(
                [
                  context.l10n.appName,
                  context.l10n.activity,
                  context.l10n.settings,
                ][_tab],
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: AppTheme.motion,
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      floatingActionButton: _tab == 0 && snapshot.plans.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                appRoute((_) => const ReminderEditor()),
              ),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.createReminder),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.notifications_none_rounded),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: context.l10n.reminders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_rounded),
            label: context.l10n.activity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            label: context.l10n.settings,
          ),
        ],
      ),
    );
  }
}
