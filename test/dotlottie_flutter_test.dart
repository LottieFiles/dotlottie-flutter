import 'package:flutter_test/flutter_test.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:dotlottie_flutter/dotlottie_flutter_platform_interface.dart';
import 'package:dotlottie_flutter/dotlottie_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDotLottieFlutterPlatform
    with MockPlatformInterfaceMixin
    implements DotLottieFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DotLottieFlutterPlatform initialPlatform =
      DotLottieFlutterPlatform.instance;

  test('$MethodChannelDotLottieFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDotLottieFlutter>());
  });
}
