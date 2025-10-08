import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dotlottie_flutter_platform_interface.dart';

/// An implementation of [DotlottieFlutterPlatform] that uses method channels.
class MethodChannelDotlottieFlutter extends DotlottieFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dotlottie_flutter');

  MethodChannelDotlottieFlutter() {
    // THIS LINE IS CRITICAL - it connects _handleMethodCall to receive calls from native
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLoad':
        onLoad?.call();
        break;
      case 'onLoadError':
        onLoadError?.call();
        break;
      case 'onPlay':
        onPlay?.call();
        break;
      case 'onPause':
        onPause?.call();
        break;
      case 'onStop':
        onStop?.call();
        break;
      case 'onComplete':
        onComplete?.call();
        break;
      case 'onLoop':
        onLoop?.call();
        break;
      case 'onFrame':
        final frame = (call.arguments['frame'] as num).toDouble();
        onFrame?.call(frame);
        break;
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> createPlayer() async {
    print('🎯 Dart: Calling createPlayer via method channel');
    await methodChannel.invokeMethod<void>('createPlayer');
    print('🎯 Dart: createPlayer method channel call completed');
  }

  @override
  Future<void> loadAnimation({
    required String sourceType,
    required String source,
    bool autoplay = true,
    bool loop = true,
    double speed = 1.0,
  }) async {
    await methodChannel.invokeMethod<void>('loadAnimation', {
      'sourceType': sourceType,
      'source': source,
      'autoplay': autoplay,
      'loop': loop,
      'speed': speed,
    });
  }

  @override
  Future<void> play() async {
    await methodChannel.invokeMethod<void>('play');
  }

  @override
  Future<void> pause() async {
    await methodChannel.invokeMethod<void>('pause');
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> setSpeed(double speed) async {
    await methodChannel.invokeMethod<void>('setSpeed', {'speed': speed});
  }

  @override
  Future<void> setLoop(bool loop) async {
    await methodChannel.invokeMethod<void>('setLoop', {'loop': loop});
  }

  @override
  Future<double?> getCurrentFrame() async {
    return await methodChannel.invokeMethod<double>('setCurrentFrame');
  }

  @override
  Future<double?> getTotalFrames() async {
    return await methodChannel.invokeMethod<double>('getTotalFrames');
  }

  @override
  Future<bool?> isPlaying() async {
    return await methodChannel.invokeMethod<bool>('isPlaying');
  }

  @override
  Future<bool?> isPaused() async {
    return await methodChannel.invokeMethod<bool>('isPaused');
  }
}
