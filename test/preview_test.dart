import 'dart:io';
import 'dart:ui' as ui;
import 'package:dont_forget/app.dart';
import 'package:dont_forget/core/reminder_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_engine.dart';

void main() {
  testWidgets('render the real Flutter screens for visual review', (
    tester,
  ) async {
    final previousShadowFlag = debugDisableShadows;
    debugDisableShadows = false;
    try {
      await tester.runAsync(() async {
        final font = File('C:/Windows/Fonts/msyh.ttc');
        if (await font.exists()) {
          await (FontLoader('Roboto')..addFont(
                Future.value(ByteData.sublistView(await font.readAsBytes())),
              ))
              .load();
          await (FontLoader('Ahem')..addFont(
                Future.value(ByteData.sublistView(await font.readAsBytes())),
              ))
              .load();
        }
        final flutterRoot = Platform.environment['FLUTTER_ROOT'];
        final materialIcons = File(
          '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        );
        if (flutterRoot != null && await materialIcons.exists()) {
          await (FontLoader('MaterialIcons')..addFont(
                Future.value(
                  ByteData.sublistView(await materialIcons.readAsBytes()),
                ),
              ))
              .load();
        }
      });
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final directory = Directory('build/previews');
      await tester.runAsync(() => directory.create(recursive: true));
      const boundary = ValueKey('preview');
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundary),
          );
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      final engine = FakeEngine(withPlans: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [engineProvider.overrideWithValue(engine)],
          child: const RepaintBoundary(key: boundary, child: DontForgetApp()),
        ),
      );
      await capture('home-zh');
      await tester.tap(find.text('设置').last);
      await capture('settings-zh');
      await tester.tap(find.text('提醒').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建提醒').last);
      await capture('editor-zh');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            engineProvider.overrideWithValue(FakeEngine(ringing: true)),
          ],
          child: const RepaintBoundary(key: boundary, child: DontForgetApp()),
        ),
      );
      await capture('mission-zh');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDisableShadows = previousShadowFlag;
    }
  }, tags: 'preview');
}
