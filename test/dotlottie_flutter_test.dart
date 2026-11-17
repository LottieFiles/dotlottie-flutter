import 'package:dotlottie_flutter/dotlottie_flutter_method_channel.dart';
import 'package:dotlottie_flutter/dotlottie_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DotLottieFlutterPlatform initialPlatform =
      DotLottieFlutterPlatform.instance;

  test('$MethodChannelDotLottieFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDotLottieFlutter>());
  });
}
