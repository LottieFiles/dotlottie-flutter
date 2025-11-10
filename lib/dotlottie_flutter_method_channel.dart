import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dotlottie_flutter_platform_interface.dart';

/// An implementation of [DotLottieFlutterPlatform] that uses method channels.
class MethodChannelDotLottieFlutter extends DotLottieFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dotlottie_flutter');

  MethodChannelDotLottieFlutter() {
    // THIS LINE IS CRITICAL - it connects _handleMethodCall to receive calls from native
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onComplete':
        onComplete?.call();
        break;
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
      case 'onFrame':
        final frame = (call.arguments['frameNo'] as num).toDouble();
        onFrame?.call(frame);
        break;
      case 'onRender':
        final frame = (call.arguments['frameNo'] as num).toDouble();
        onFrame?.call(frame);
        break;
      case 'onLoop':
        final loopCount = (call.arguments['loopCount'] as num).toInt();
        onLoop?.call(loopCount);
        break;
    }
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

  // Playback control methods
  @override
  Future<bool?> play() async {
    return await methodChannel.invokeMethod<bool>('play');
  }

  @override
  Future<bool?> playFromFrame(double frame) async {
    return await methodChannel.invokeMethod<bool>('playFromFrame', {
      'frame': frame,
    });
  }

  @override
  Future<bool?> playFromProgress(double progress) async {
    return await methodChannel.invokeMethod<bool>('playFromProgress', {
      'progress': progress,
    });
  }

  @override
  Future<bool?> pause() async {
    return await methodChannel.invokeMethod<bool>('pause');
  }

  @override
  Future<bool?> stop() async {
    return await methodChannel.invokeMethod<bool>('stop');
  }

  // Animation properties getters
  @override
  Future<bool?> isPlaying() async {
    return await methodChannel.invokeMethod<bool>('isPlaying');
  }

  @override
  Future<bool?> isPaused() async {
    return await methodChannel.invokeMethod<bool>('isPaused');
  }

  @override
  Future<bool?> isStopped() async {
    return await methodChannel.invokeMethod<bool>('isStopped');
  }

  @override
  Future<bool?> isLoaded() async {
    return await methodChannel.invokeMethod<bool>('isLoaded');
  }

  @override
  Future<double?> currentFrame() async {
    return await methodChannel.invokeMethod<double>('currentFrame');
  }

  @override
  Future<double?> totalFrames() async {
    return await methodChannel.invokeMethod<double>('totalFrames');
  }

  @override
  Future<double?> currentProgress() async {
    return await methodChannel.invokeMethod<double>('currentProgress');
  }

  @override
  Future<double?> duration() async {
    return await methodChannel.invokeMethod<double>('duration');
  }

  @override
  Future<int?> loopCount() async {
    return await methodChannel.invokeMethod<int>('loopCount');
  }

  @override
  Future<double?> speed() async {
    return await methodChannel.invokeMethod<double>('speed');
  }

  @override
  Future<bool?> loop() async {
    return await methodChannel.invokeMethod<bool>('loop');
  }

  @override
  Future<bool?> autoplay() async {
    return await methodChannel.invokeMethod<bool>('autoplay');
  }

  @override
  Future<bool?> useFrameInterpolation() async {
    return await methodChannel.invokeMethod<bool>('useFrameInterpolation');
  }

  @override
  Future<List<double>?> segments() async {
    final result = await methodChannel.invokeMethod('segments');
    if (result is List) {
      return result.cast<double>();
    }
    return null;
  }

  @override
  Future<String?> mode() async {
    return await methodChannel.invokeMethod<String>('mode');
  }

  // Animation control setters
  @override
  Future<void> setSpeed(double speed) async {
    await methodChannel.invokeMethod<void>('setSpeed', {'speed': speed});
  }

  @override
  Future<void> setLoop(bool loop) async {
    await methodChannel.invokeMethod<void>('setLoop', {'loop': loop});
  }

  @override
  Future<bool?> setFrame(double frame) async {
    return await methodChannel.invokeMethod<bool>('setFrame', {'frame': frame});
  }

  @override
  Future<bool?> setProgress(double progress) async {
    return await methodChannel.invokeMethod<bool>('setProgress', {
      'progress': progress,
    });
  }

  @override
  Future<void> setSegments(double start, double end) async {
    await methodChannel.invokeMethod<void>('setSegments', {
      'start': start,
      'end': end,
    });
  }

  @override
  Future<void> setMode(String mode) async {
    await methodChannel.invokeMethod<void>('setMode', {'mode': mode});
  }

  @override
  Future<void> setFrameInterpolation(bool useFrameInterpolation) async {
    await methodChannel.invokeMethod<void>('setFrameInterpolation', {
      'useFrameInterpolation': useFrameInterpolation,
    });
  }

  @override
  Future<void> setAutoplay(bool autoplay) async {
    await methodChannel.invokeMethod<void>('setAutoplay', {
      'autoplay': autoplay,
    });
  }

  @override
  Future<void> setBackgroundColor(String color) async {
    await methodChannel.invokeMethod<void>('setBackgroundColor', {
      'color': color,
    });
  }

  // Theme methods
  @override
  Future<bool?> setTheme(String themeId) async {
    return await methodChannel.invokeMethod<bool>('setTheme', {
      'themeId': themeId,
    });
  }

  @override
  Future<bool?> setThemeData(String themeData) async {
    return await methodChannel.invokeMethod<bool>('setThemeData', {
      'themeData': themeData,
    });
  }

  @override
  Future<bool?> resetTheme() async {
    return await methodChannel.invokeMethod<bool>('resetTheme');
  }

  @override
  Future<String?> activeThemeId() async {
    return await methodChannel.invokeMethod<String>('activeThemeId');
  }

  // Animation loading methods
  @override
  Future<void> loadAnimationById(String animationId) async {
    await methodChannel.invokeMethod<void>('loadAnimationById', {
      'animationId': animationId,
    });
  }

  @override
  Future<String?> activeAnimationId() async {
    return await methodChannel.invokeMethod<String>('activeAnimationId');
  }

  // Marker methods
  @override
  Future<void> setMarker(String marker) async {
    await methodChannel.invokeMethod<void>('setMarker', {'marker': marker});
  }

  @override
  Future<List<Map<String, dynamic>>?> markers() async {
    final result = await methodChannel.invokeMethod('markers');
    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Slots methods
  @override
  Future<bool?> setSlots(String slots) async {
    return await methodChannel.invokeMethod<bool>('setSlots', {'slots': slots});
  }

  // Resize method
  @override
  Future<void> resize(int width, int height) async {
    await methodChannel.invokeMethod<void>('resize', {
      'width': width,
      'height': height,
    });
  }

  // Layer methods
  @override
  Future<List<double>?> getLayerBounds(String layerName) async {
    final result = await methodChannel.invokeMethod('getLayerBounds', {
      'layerName': layerName,
    });
    if (result is List) {
      return result.cast<double>();
    }
    return null;
  }

  // State machine methods
  @override
  Future<bool?> stateMachineLoad(String stateMachineId) async {
    return await methodChannel.invokeMethod<bool>('stateMachineLoad', {
      'stateMachineId': stateMachineId,
    });
  }

  @override
  Future<bool?> stateMachineLoadData(String data) async {
    return await methodChannel.invokeMethod<bool>('stateMachineLoadData', {
      'data': data,
    });
  }

  @override
  Future<bool?> stateMachineStart() async {
    return await methodChannel.invokeMethod<bool>('stateMachineStart');
  }

  @override
  Future<bool?> stateMachineStop() async {
    return await methodChannel.invokeMethod<bool>('stateMachineStop');
  }

  @override
  Future<void> stateMachinePostEvent(String event) async {
    await methodChannel.invokeMethod<void>('stateMachinePostEvent', {
      'event': event,
    });
  }

  @override
  Future<void> stateMachineFire(String event) async {
    await methodChannel.invokeMethod<void>('stateMachineFire', {
      'event': event,
    });
  }

  @override
  Future<bool?> stateMachineSetNumericInput(String key, double value) async {
    return await methodChannel.invokeMethod<bool>(
      'stateMachineSetNumericInput',
      {'key': key, 'value': value},
    );
  }

  @override
  Future<bool?> stateMachineSetStringInput(String key, String value) async {
    return await methodChannel.invokeMethod<bool>(
      'stateMachineSetStringInput',
      {'key': key, 'value': value},
    );
  }

  @override
  Future<bool?> stateMachineSetBooleanInput(String key, bool value) async {
    return await methodChannel.invokeMethod<bool>(
      'stateMachineSetBooleanInput',
      {'key': key, 'value': value},
    );
  }

  @override
  Future<double?> stateMachineGetNumericInput(String key) async {
    return await methodChannel.invokeMethod<double>(
      'stateMachineGetNumericInput',
      {'key': key},
    );
  }

  @override
  Future<String?> stateMachineGetStringInput(String key) async {
    return await methodChannel.invokeMethod<String>(
      'stateMachineGetStringInput',
      {'key': key},
    );
  }

  @override
  Future<bool?> stateMachineGetBooleanInput(String key) async {
    return await methodChannel.invokeMethod<bool>(
      'stateMachineGetBooleanInput',
      {'key': key},
    );
  }

  @override
  Future<Map<String, String>?> stateMachineGetInputs() async {
    final result = await methodChannel.invokeMethod('stateMachineGetInputs');
    if (result is Map) {
      return result.cast<String, String>();
    }
    return null;
  }

  @override
  Future<String?> stateMachineCurrentState() async {
    return await methodChannel.invokeMethod<String>('stateMachineCurrentState');
  }

  @override
  Future<List<String>?> stateMachineFrameworkSetup() async {
    final result = await methodChannel.invokeMethod(
      'stateMachineFrameworkSetup',
    );
    if (result is List) {
      return result.cast<String>();
    }
    return null;
  }

  @override
  Future<String?> getStateMachine(String id) async {
    return await methodChannel.invokeMethod<String>('getStateMachine', {
      'id': id,
    });
  }

  // Manifest method
  @override
  Future<Map<String, dynamic>?> manifest() async {
    final result = await methodChannel.invokeMethod('manifest');
    if (result is Map) {
      return result.cast<String, dynamic>();
    }
    return null;
  }

  // Error methods
  @override
  Future<bool?> error() async {
    return await methodChannel.invokeMethod<bool>('error');
  }

  @override
  Future<String?> errorMessage() async {
    return await methodChannel.invokeMethod<String>('errorMessage');
  }

  // Render methods
  @override
  Future<bool?> render() async {
    return await methodChannel.invokeMethod<bool>('render');
  }

  // @override
  // Future<dynamic> frameImage() async {
  //   return await methodChannel.invokeMethod('frameImage');
  // }
}
