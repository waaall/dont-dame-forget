import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';

abstract class ReminderEngine {
  Stream<void> get changes;
  Future<dynamic> invoke(
    String method, [
    Map<String, dynamic> arguments = const {},
  ]);
  Future<AppSnapshot> snapshot() async =>
      AppSnapshot.fromJson(jsonMap(await invoke('snapshot')));
}

class AndroidReminderEngine extends ReminderEngine {
  static const _methods = MethodChannel('dont_forget/engine');
  static const _events = EventChannel('dont_forget/events');
  @override
  Stream<void> get changes => _events.receiveBroadcastStream().map((_) {});
  @override
  Future<dynamic> invoke(
    String method, [
    Map<String, dynamic> arguments = const {},
  ]) => _methods.invokeMethod<dynamic>(method, arguments);
}

final engineProvider = Provider<ReminderEngine>(
  (ref) => AndroidReminderEngine(),
);
final appControllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => AppController(ref.watch(engineProvider)),
);

class AppController extends ChangeNotifier {
  final ReminderEngine engine;
  AppSnapshot? snapshot;
  Object? startupError;
  StreamSubscription<void>? _subscription;
  bool _disposed = false;
  bool _again = false;
  Future<void>? _loading;
  AppController(this.engine) {
    _subscription = engine.changes.listen(
      (_) => unawaited(refresh()),
      onError: (Object _) {},
    );
    unawaited(refresh());
  }
  Future<void> refresh() {
    if (_loading != null) {
      _again = true;
      return _loading!;
    }
    final completer = Completer<void>();
    _loading = completer.future;
    () async {
      do {
        _again = false;
        try {
          final next = await engine.snapshot();
          if (!_disposed) {
            snapshot = next;
            startupError = null;
          }
        } catch (error) {
          if (!_disposed) startupError = error;
        }
        if (!_disposed) notifyListeners();
      } while (_again && !_disposed);
      _loading = null;
      completer.complete();
    }();
    return completer.future;
  }

  Future<dynamic> command(
    String method, [
    Map<String, dynamic> arguments = const {},
  ]) async {
    final result = await engine.invoke(method, arguments);
    await refresh();
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
