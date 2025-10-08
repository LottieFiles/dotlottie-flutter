import 'package:flutter_test/flutter_test.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:dotlottie_flutter/dotlottie_flutter_platform_interface.dart';
import 'package:dotlottie_flutter/dotlottie_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDotlottieFlutterPlatform
    with MockPlatformInterfaceMixin
    implements DotlottieFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DotlottieFlutterPlatform initialPlatform = DotlottieFlutterPlatform.instance;

  test('$MethodChannelDotlottieFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDotlottieFlutter>());
  });

  test('getPlatformVersion', () async {
    DotlottieFlutter dotlottieFlutterPlugin = DotlottieFlutter();
    MockDotlottieFlutterPlatform fakePlatform = MockDotlottieFlutterPlatform();
    DotlottieFlutterPlatform.instance = fakePlatform;

    expect(await dotlottieFlutterPlugin.getPlatformVersion(), '42');
  });
}
