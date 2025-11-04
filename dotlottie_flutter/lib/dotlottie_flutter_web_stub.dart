// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'dotlottie_flutter_platform_interface.dart';

/// Stub implementation for non-web platforms
class DotLottieFlutterWeb extends DotLottieFlutterPlatform {
  /// Constructs a DotLottieFlutterWeb
  DotLottieFlutterWeb();

  static void registerWith(Registrar registrar) {
    // This should never be called on non-web platforms
    throw UnsupportedError(
      'DotLottieFlutterWeb is not supported on this platform.',
    );
  }

  @override
  Future<String?> getPlatformVersion() async {
    throw UnsupportedError(
      'getPlatformVersion is not supported on this platform.',
    );
  }
}
