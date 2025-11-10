import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dotlottie_flutter/dotlottie_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelDotLottieFlutter platform = MethodChannelDotLottieFlutter();
  const MethodChannel channel = MethodChannel('dotlottie_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
