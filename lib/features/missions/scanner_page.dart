import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/reminder_engine.dart';
import '../../shared/strings.dart';
import '../../shared/theme.dart';

class ScannerPage extends ConsumerStatefulWidget {
  final Future<void> Function(String)? onValue;
  const ScannerPage({super.key, this.onValue});
  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _busy = false;
  String? _error;
  // MobileScanner owns pause/resume handling; a second observer would race its controller.
  @override
  void dispose() {
    unawaited(_camera.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.of(Brightness.dark),
    child: Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        title: Text(context.l10n.scanTitle),
        backgroundColor: AppColors.night,
        actions: [
          IconButton(
            tooltip: context.l10n.torch,
            onPressed: () => _cameraAction(_camera.toggleTorch),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _camera,
                    onDetect: (capture) {
                      final code = capture.barcodes
                          .map((barcode) => barcode.rawValue)
                          .whereType<String>()
                          .where((value) => value.isNotEmpty)
                          .firstOrNull;
                      if (code != null) _detected(code);
                    },
                    errorBuilder: (context, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 50),
                            const SizedBox(height: 20),
                            Text(
                              error.errorCode ==
                                      MobileScannerErrorCode.permissionDenied
                                  ? context.l10n.cameraDenied
                                  : context.l10n.cameraError,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton(
                              onPressed: () => _cameraAction(() async {
                                await ref.read(engineProvider).invoke(
                                  'openPermission',
                                  {'kind': 'app'},
                                );
                              }),
                              child: Text(context.l10n.openSettings),
                            ),
                            TextButton(
                              onPressed: () => _cameraAction(_camera.start),
                              child: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      width: 245,
                      height: 245,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                  if (_busy) const CircularProgressIndicator(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Text(
                    context.l10n.scanHelp,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFCED9CC),
                      height: 1.7,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFB49D)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _detected(String code) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.onValue == null) {
        if (mounted) Navigator.pop(context, code);
        return;
      }
      await widget.onValue!(code);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = context.errorLabel(error));
      // Restart detection so a wrong code can be retried without leaving the camera.
      try {
        await _camera.stop();
        if (mounted &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          await _camera.start();
        }
      } catch (_) {
        /* The scanner widget reports camera/permission errors. */
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cameraAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.cameraError);
    }
  }
}
