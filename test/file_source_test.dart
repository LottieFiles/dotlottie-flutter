import 'dart:convert';
import 'dart:io';

import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creation params the native side received for each platform view.
final List<Map<Object?, Object?>> _created = [];

Future<Object?> _platformViews(MethodCall call) async {
  if (call.method == 'create') {
    final args = call.arguments as Map<Object?, Object?>;
    final params = args['params'] as Uint8List;
    _created.add(const StandardMessageCodec()
        .decodeMessage(ByteData.sublistView(params)) as Map<Object?, Object?>);
  }
  return null;
}

/// Lets the real file read finish. Each step of the read (open, length, read,
/// close) completes on the real event loop but continues in the fake-async test
/// zone, so the two have to be advanced in turn.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}

void main() {
  late Directory dir;

  setUp(() {
    _created.clear();
    dir = Directory.systemTemp.createTempSync('dotlottie_file_source');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, _platformViews);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
    dir.deleteSync(recursive: true);
  });

  Widget view(String path, {VoidCallback? onLoadError}) => Directionality(
        textDirection: TextDirection.ltr,
        child: DotLottieView(
          sourceType: 'file',
          source: path,
          onLoadError: onLoadError,
        ),
      );

  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets('a .json file reaches the native view as json', (tester) async {
    final file = File('${dir.path}/anim.JSON')..writeAsStringSync('{"v":"5"}');

    await tester.pumpWidget(view(file.path));
    await _settle(tester);

    expect(_created, hasLength(1));
    expect(_created.single['sourceType'], 'json');
    expect(_created.single['source'], '{"v":"5"}');
  }, variant: iOS);

  testWidgets('any other file reaches the native view as bytes',
      (tester) async {
    final bytes = Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 0xff]);
    final file = File('${dir.path}/anim.lottie')..writeAsBytesSync(bytes);

    await tester.pumpWidget(view(file.path));
    await _settle(tester);

    expect(_created, hasLength(1));
    expect(_created.single['sourceType'], 'data');
    expect(_created.single['source'], bytes);
  }, variant: iOS);

  testWidgets('a missing file reports onLoadError and creates no view',
      (tester) async {
    var errors = 0;

    await tester.pumpWidget(
        view('${dir.path}/missing.lottie', onLoadError: () => errors++));
    await _settle(tester);

    expect(errors, 1);
    expect(_created, isEmpty);
  }, variant: iOS);

  testWidgets('a missing asset reports onLoadError', (tester) async {
    var errors = 0;

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: DotLottieView(
        sourceType: 'asset',
        source: 'does-not-exist.lottie',
        onLoadError: () => errors++,
      ),
    ));
    await _settle(tester);

    expect(errors, 1);
    expect(_created, isEmpty);
  }, variant: iOS);

  testWidgets('switching to a readable file loads it', (tester) async {
    final file = File('${dir.path}/b.json')
      ..writeAsStringSync(jsonEncode({'v': '5'}));
    var errors = 0;

    await tester.pumpWidget(
        view('${dir.path}/missing.json', onLoadError: () => errors++));
    await _settle(tester);
    await tester.pumpWidget(view(file.path, onLoadError: () => errors++));
    await _settle(tester);

    expect(errors, 1);
    expect(_created.single['source'], '{"v":"5"}');
  }, variant: iOS);
}
