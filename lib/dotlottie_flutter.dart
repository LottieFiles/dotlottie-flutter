import 'dotlottie_flutter_platform_interface.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DotLottieView extends StatefulWidget {
  final bool? autoplay;
  final bool? loop;
  final int? loopCount;
  final String? mode; // 'forward', 'reverse', 'bounce', 'reverseBounce'
  final double? speed;
  final bool? useFrameInterpolation;
  final List<num>? segment;
  final String? backgroundColor;
  // final Layout layout;
  final String? marker;
  final String? themeId;
  final String? stateMachineId;
  final String? animationId;

  final String sourceType; // 'url', 'asset', or 'json'
  final String source;

  final int? width;
  final int? height;
  final Function(DotLottieViewController)? onViewCreated;

  // Event callbacks
  final VoidCallback? onComplete;
  final VoidCallback? onLoad;
  final VoidCallback? onLoadError;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final Function(double frameNo)? onFrame;
  final Function(double frameNo)? onRender;
  final Function(int loopCount)? onLoop;

  const DotLottieView({
    super.key,
    required this.sourceType,
    required this.source,
    this.autoplay = true,
    this.loop = true,
    this.speed = 1.0,
    this.mode = 'forward',
    this.useFrameInterpolation = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.onViewCreated,
    this.onComplete,
    this.onLoad,
    this.onLoadError,
    this.onPlay,
    this.onPause,
    this.onStop,
    this.onFrame,
    this.onRender,
    this.onLoop,
    this.loopCount,
    this.segment,
    this.marker,
    this.themeId,
    this.stateMachineId,
    this.animationId,
  });

  @override
  State<DotLottieView> createState() => _DotLottieViewState();
}

class _DotLottieViewState extends State<DotLottieView> {
  DotLottieViewController? _controller;
  MethodChannel? _methodChannel;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebView();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return _buildAndroidView();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildIOSView();
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return _buildMacOSView();
    }
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Text('Platform not supported')),
    );
  }

  Widget _buildWebView() {
    return HtmlElementView(
      viewType: 'dotlottie_view',
      onPlatformViewCreated: (int viewId) async {
        print('🔴 Flutter: Platform view created with id: $viewId');
        _onPlatformViewCreated(viewId);

        // For web, send initialization after a short delay to ensure view is ready
        await Future.delayed(const Duration(milliseconds: 150));

        if (_controller != null && mounted) {
          print('🔴 Flutter: Sending initialize command');
          try {
            await _controller!._channel.invokeMethod('initialize', {
              'autoplay': widget.autoplay,
              'loop': widget.loop,
              'loopCount': widget.loopCount,
              'mode': widget.mode,
              'speed': widget.speed,
              'useFrameInterpolation': widget.useFrameInterpolation,
              if (widget.segment != null) 'segment': widget.segment,
              if (widget.backgroundColor != null)
                'backgroundColor': widget.backgroundColor,
              if (widget.marker != null) 'marker': widget.marker,
              if (widget.themeId != null) 'themeId': widget.themeId,
              if (widget.stateMachineId != null)
                'stateMachineId': widget.stateMachineId,
              if (widget.animationId != null) 'animationId': widget.animationId,
              'sourceType': widget.sourceType,
              'source': widget.source,
              if (widget.width != null) 'width': widget.width,
              if (widget.height != null) 'height': widget.height,
            });
            print('🔴 Flutter: Initialize command sent successfully');
          } catch (e) {
            print('🔴 Flutter: Error sending initialize: $e');
          }
        }
      },
    );
  }

  Widget _buildAndroidView() {
    final creationParams = _getCreationParams();

    return AndroidView(
      viewType: 'dotlottie_view',
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  Widget _buildIOSView() {
    final creationParams = _getCreationParams();

    return UiKitView(
      viewType: 'dotlottie_view',
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  Widget _buildMacOSView() {
    final creationParams = _getCreationParams();

    return AppKitView(
      viewType: 'dotlottie_view',
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  Map<String, dynamic> _getCreationParams() {
    return {
      'autoplay': widget.autoplay,
      'loop': widget.loop,
      'loopCount': widget.loopCount,
      'mode': widget.mode,
      'speed': widget.speed,
      'useFrameInterpolation': widget.useFrameInterpolation,
      if (widget.segment != null) 'segment': widget.segment,
      if (widget.backgroundColor != null)
        'backgroundColor': widget.backgroundColor,
      if (widget.marker != null) 'marker': widget.marker,
      if (widget.themeId != null) 'themeId': widget.themeId,
      if (widget.stateMachineId != null)
        'stateMachineId': widget.stateMachineId,
      if (widget.animationId != null) 'animationId': widget.animationId,
      'sourceType': widget.sourceType,
      'source': widget.source,
      if (widget.width != null) 'width': widget.width,
      if (widget.height != null) 'height': widget.height,
    };
  }

  void _onPlatformViewCreated(int viewId) {
    print('🔴 Flutter: _onPlatformViewCreated called with id: $viewId');

    // Set up method channel for this view
    _methodChannel = MethodChannel('dotlottie_view_$viewId');
    _methodChannel!.setMethodCallHandler(_handleMethodCall);

    // Create controller
    _controller = DotLottieViewController._(viewId);

    // Call onViewCreated callback
    if (widget.onViewCreated != null) {
      widget.onViewCreated!(_controller!);
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (!mounted) return;

    switch (call.method) {
      case 'onComplete':
        print('🔴 Flutter: onComplete event received');
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
        break;

      case 'onLoad':
        print('🔴 Flutter: onLoad event received');
        if (widget.onLoad != null) {
          widget.onLoad!();
        }
        break;

      case 'onLoadError':
        print('🔴 Flutter: onLoadError event received');
        if (widget.onLoadError != null) {
          widget.onLoadError!();
        }
        break;

      case 'onPlay':
        print('🔴 Flutter: onPlay event received');
        if (widget.onPlay != null) {
          widget.onPlay!();
        }
        break;

      case 'onPause':
        print('🔴 Flutter: onPause event received');
        if (widget.onPause != null) {
          widget.onPause!();
        }
        break;

      case 'onFrame':
        final frameNo = (call.arguments as num).toDouble();
        // print('🔴 Flutter: onFrame event received (frame: $frameNo)');
        if (widget.onFrame != null) {
          widget.onFrame!(frameNo);
        }
        break;

      case 'onRender':
        final frameNo = (call.arguments as num).toDouble();
        // print('🔴 Flutter: onRender event received (frame: $frameNo)');
        if (widget.onRender != null) {
          widget.onRender!(frameNo);
        }
        break;

      case 'onStop':
        print('🔴 Flutter: onStop event received');
        if (widget.onStop != null) {
          widget.onStop!();
        }
        break;

      case 'onLoop':
        final loopCount = call.arguments as int;
        print('🔴 Flutter: onLoop event received (count: $loopCount)');
        if (widget.onLoop != null) {
          widget.onLoop!(loopCount);
        }
        break;

      default:
        print('🔴 Flutter: Unknown method call: ${call.method}');
    }
  }

  @override
  void dispose() {
    _methodChannel?.setMethodCallHandler(null);
    _controller?.dispose();
    super.dispose();
  }
}

class DotLottieViewController {
  final int _viewId;
  late final MethodChannel _channel;

  DotLottieViewController._(this._viewId) {
    _channel = MethodChannel('dotlottie_view_$_viewId');
  }

  // Playback control methods
  Future<bool?> play() async {
    try {
      return await _channel.invokeMethod<bool>('play');
    } catch (e) {
      debugPrint('Error calling play: $e');
      return false;
    }
  }

  Future<bool?> playFromFrame(double frame) async {
    try {
      return await _channel.invokeMethod<bool>('playFromFrame', {
        'frame': frame,
      });
    } catch (e) {
      debugPrint('Error calling playFromFrame: $e');
      return false;
    }
  }

  Future<bool?> playFromProgress(double progress) async {
    try {
      return await _channel.invokeMethod<bool>('playFromProgress', {
        'progress': progress,
      });
    } catch (e) {
      debugPrint('Error calling playFromProgress: $e');
      return false;
    }
  }

  Future<bool?> pause() async {
    try {
      return await _channel.invokeMethod<bool>('pause');
    } catch (e) {
      debugPrint('Error calling pause: $e');
      return false;
    }
  }

  Future<bool?> stop() async {
    try {
      return await _channel.invokeMethod<bool>('stop');
    } catch (e) {
      debugPrint('Error calling stop: $e');
      return false;
    }
  }

  // Animation properties getters
  Future<bool?> isPlaying() async {
    try {
      return await _channel.invokeMethod<bool>('isPlaying');
    } catch (e) {
      debugPrint('Error calling isPlaying: $e');
      return false;
    }
  }

  Future<bool?> isPaused() async {
    try {
      return await _channel.invokeMethod<bool>('isPaused');
    } catch (e) {
      debugPrint('Error calling isPaused: $e');
      return false;
    }
  }

  Future<bool?> isStopped() async {
    try {
      return await _channel.invokeMethod<bool>('isStopped');
    } catch (e) {
      debugPrint('Error calling isStopped: $e');
      return false;
    }
  }

  Future<bool?> isLoaded() async {
    try {
      return await _channel.invokeMethod<bool>('isLoaded');
    } catch (e) {
      debugPrint('Error calling isLoaded: $e');
      return false;
    }
  }

  Future<double?> currentFrame() async {
    try {
      return await _channel.invokeMethod<double>('currentFrame');
    } catch (e) {
      debugPrint('Error calling currentFrame: $e');
      return null;
    }
  }

  Future<double?> totalFrames() async {
    try {
      return await _channel.invokeMethod<double>('totalFrames');
    } catch (e) {
      debugPrint('Error calling totalFrames: $e');
      return null;
    }
  }

  Future<double?> currentProgress() async {
    try {
      return await _channel.invokeMethod<double>('currentProgress');
    } catch (e) {
      debugPrint('Error calling currentProgress: $e');
      return null;
    }
  }

  Future<double?> duration() async {
    try {
      return await _channel.invokeMethod<double>('duration');
    } catch (e) {
      debugPrint('Error calling duration: $e');
      return null;
    }
  }

  Future<int?> loopCount() async {
    try {
      return await _channel.invokeMethod<int>('loopCount');
    } catch (e) {
      debugPrint('Error calling loopCount: $e');
      return null;
    }
  }

  Future<double?> speed() async {
    try {
      return await _channel.invokeMethod<double>('speed');
    } catch (e) {
      debugPrint('Error calling speed: $e');
      return null;
    }
  }

  Future<bool?> loop() async {
    try {
      return await _channel.invokeMethod<bool>('loop');
    } catch (e) {
      debugPrint('Error calling loop: $e');
      return false;
    }
  }

  Future<bool?> autoplay() async {
    try {
      return await _channel.invokeMethod<bool>('autoplay');
    } catch (e) {
      debugPrint('Error calling autoplay: $e');
      return false;
    }
  }

  Future<bool?> useFrameInterpolation() async {
    try {
      return await _channel.invokeMethod<bool>('useFrameInterpolation');
    } catch (e) {
      debugPrint('Error calling useFrameInterpolation: $e');
      return false;
    }
  }

  Future<List<double>?> segments() async {
    try {
      final result = await _channel.invokeMethod('segments');
      if (result is List) {
        return result.cast<double>();
      }
      return null;
    } catch (e) {
      debugPrint('Error calling segments: $e');
      return null;
    }
  }

  Future<String?> mode() async {
    try {
      return await _channel.invokeMethod<String>('mode');
    } catch (e) {
      debugPrint('Error calling mode: $e');
      return null;
    }
  }

  // Animation control setters
  Future<void> setSpeed(double speed) async {
    try {
      await _channel.invokeMethod('setSpeed', {'speed': speed});
    } catch (e) {
      debugPrint('Error calling setSpeed: $e');
    }
  }

  Future<void> setLoop(bool loop) async {
    try {
      await _channel.invokeMethod('setLoop', {'loop': loop});
    } catch (e) {
      debugPrint('Error calling setLoop: $e');
    }
  }

  Future<bool?> setFrame(double frame) async {
    try {
      return await _channel.invokeMethod<bool>('setFrame', {'frame': frame});
    } catch (e) {
      debugPrint('Error calling setFrame: $e');
      return false;
    }
  }

  Future<bool?> setProgress(double progress) async {
    try {
      return await _channel.invokeMethod<bool>('setProgress', {
        'progress': progress,
      });
    } catch (e) {
      debugPrint('Error calling setProgress: $e');
      return false;
    }
  }

  Future<void> setSegments(double start, double end) async {
    try {
      await _channel.invokeMethod('setSegments', {'start': start, 'end': end});
    } catch (e) {
      debugPrint('Error calling setSegments: $e');
    }
  }

  Future<void> setMarker(String marker) async {
    try {
      await _channel.invokeMethod('setMarker', {'marker': marker});
    } catch (e) {
      debugPrint('Error calling setMarker: $e');
    }
  }

  Future<void> setMode(String mode) async {
    try {
      await _channel.invokeMethod('setMode', {'mode': mode});
    } catch (e) {
      debugPrint('Error calling setMode: $e');
    }
  }

  Future<void> setFrameInterpolation(bool useFrameInterpolation) async {
    try {
      await _channel.invokeMethod('setFrameInterpolation', {
        'useFrameInterpolation': useFrameInterpolation,
      });
    } catch (e) {
      debugPrint('Error calling setFrameInterpolation: $e');
    }
  }

  // Theme methods
  Future<bool?> setTheme(String themeId) async {
    try {
      return await _channel.invokeMethod<bool>('setTheme', {
        'themeId': themeId,
      });
    } catch (e) {
      debugPrint('Error calling setTheme: $e');
      return false;
    }
  }

  Future<bool?> setThemeData(String themeData) async {
    try {
      return await _channel.invokeMethod<bool>('setThemeData', {
        'themeData': themeData,
      });
    } catch (e) {
      debugPrint('Error calling setThemeData: $e');
      return false;
    }
  }

  Future<bool?> resetTheme() async {
    try {
      return await _channel.invokeMethod<bool>('resetTheme');
    } catch (e) {
      debugPrint('Error calling resetTheme: $e');
      return false;
    }
  }

  Future<String?> activeThemeId() async {
    try {
      return await _channel.invokeMethod<String>('activeThemeId');
    } catch (e) {
      debugPrint('Error calling activeThemeId: $e');
      return null;
    }
  }

  // Animation loading methods
  Future<void> loadAnimation(String animationId) async {
    try {
      await _channel.invokeMethod('loadAnimation', {
        'animationId': animationId,
      });
    } catch (e) {
      debugPrint('Error calling loadAnimation: $e');
    }
  }

  Future<String?> activeAnimationId() async {
    try {
      return await _channel.invokeMethod<String>('activeAnimationId');
    } catch (e) {
      debugPrint('Error calling activeAnimationId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> markers() async {
    try {
      final result = await _channel.invokeMethod('markers');
      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      debugPrint('Error calling markers: $e');
      return null;
    }
  }

  // Slots methods
  Future<bool?> setSlots(String slots) async {
    try {
      return await _channel.invokeMethod<bool>('setSlots', {'slots': slots});
    } catch (e) {
      debugPrint('Error calling setSlots: $e');
      return false;
    }
  }

  // Resize method
  Future<void> resize(int width, int height) async {
    try {
      await _channel.invokeMethod('resize', {'width': width, 'height': height});
    } catch (e) {
      debugPrint('Error calling resize: $e');
    }
  }

  // Layer methods
  Future<List<double>?> getLayerBounds(String layerName) async {
    try {
      final result = await _channel.invokeMethod('getLayerBounds', {
        'layerName': layerName,
      });
      if (result is List) {
        return result.cast<double>();
      }
      return null;
    } catch (e) {
      debugPrint('Error calling getLayerBounds: $e');
      return null;
    }
  }

  // State machine methods
  Future<bool?> stateMachineLoad(String stateMachineId) async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineLoad', {
        'stateMachineId': stateMachineId,
      });
    } catch (e) {
      debugPrint('Error calling stateMachineLoad: $e');
      return false;
    }
  }

  Future<bool?> stateMachineLoadData(String data) async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineLoadData', {
        'data': data,
      });
    } catch (e) {
      debugPrint('Error calling stateMachineLoadData: $e');
      return false;
    }
  }

  Future<bool?> stateMachineStart() async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineStart');
    } catch (e) {
      debugPrint('Error calling stateMachineStart: $e');
      return false;
    }
  }

  Future<bool?> stateMachineStop() async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineStop');
    } catch (e) {
      debugPrint('Error calling stateMachineStop: $e');
      return false;
    }
  }

  Future<void> stateMachineFire(String event) async {
    try {
      await _channel.invokeMethod('stateMachineFire', {'event': event});
    } catch (e) {
      debugPrint('Error calling stateMachineFire: $e');
    }
  }

  Future<bool?> stateMachineSetNumericInput(String key, double value) async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineSetNumericInput', {
        'key': key,
        'value': value,
      });
    } catch (e) {
      debugPrint('Error calling stateMachineSetNumericInput: $e');
      return false;
    }
  }

  Future<bool?> stateMachineSetStringInput(String key, String value) async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineSetStringInput', {
        'key': key,
        'value': value,
      });
    } catch (e) {
      debugPrint('Error calling stateMachineSetStringInput: $e');
      return false;
    }
  }

  Future<bool?> stateMachineSetBooleanInput(String key, bool value) async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineSetBooleanInput', {
        'key': key,
        'value': value,
      });
    } catch (e) {
      debugPrint('Error calling stateMachineSetBooleanInput: $e');
      return false;
    }
  }

  Future<double?> stateMachineGetNumericInput(String key) async {
    try {
      return await _channel.invokeMethod<double>(
        'stateMachineGetNumericInput',
        {'key': key},
      );
    } catch (e) {
      debugPrint('Error calling stateMachineGetNumericInput: $e');
      return null;
    }
  }

  Future<String?> stateMachineGetStringInput(String key) async {
    try {
      return await _channel.invokeMethod<String>('stateMachineGetStringInput', {
        'key': key,
      });
    } catch (e) {
      debugPrint('Error calling stateMachineGetStringInput: $e');
      return null;
    }
  }

  Future<bool?> stateMachineGetBooleanInput(String key) async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineGetBooleanInput', {
        'key': key,
      });
    } catch (e) {
      debugPrint('Error calling stateMachineGetBooleanInput: $e');
      return null;
    }
  }

  Future<Map<String, String>?> stateMachineGetInputs() async {
    try {
      final result = await _channel.invokeMethod('stateMachineGetInputs');
      if (result is Map) {
        return result.cast<String, String>();
      }
      return null;
    } catch (e) {
      debugPrint('Error calling stateMachineGetInputs: $e');
      return null;
    }
  }

  Future<String?> stateMachineCurrentState() async {
    try {
      return await _channel.invokeMethod<String>('stateMachineCurrentState');
    } catch (e) {
      debugPrint('Error calling stateMachineCurrentState: $e');
      return null;
    }
  }

  Future<String?> getStateMachine(String id) async {
    try {
      return await _channel.invokeMethod<String>('getStateMachine', {'id': id});
    } catch (e) {
      debugPrint('Error calling getStateMachine: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> manifest() async {
    try {
      final result = await _channel.invokeMethod('manifest');
      if (result is Map) {
        return result.cast<String, dynamic>();
      }
      return null;
    } catch (e) {
      debugPrint('Error calling manifest: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error calling dispose: $e');
    }
  }
}

class DotLottieFlutter {
  void Function()? onComplete;
  void Function()? onLoad;
  void Function()? onLoadError;
  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onStop;
  void Function(double frameNo)? onFrame;
  void Function(double frameNo)? onRender;
  void Function(int loopCount)? onLoop;

  DotLottieFlutter() {
    DotLottieFlutterPlatform.instance.setEventHandlers(
      onComplete: () => onComplete?.call(),
      onLoad: () => onLoad?.call(),
      onLoadError: () => onLoadError?.call(),
      onPlay: () => onPlay?.call(),
      onPause: () => onPause?.call(),
      onStop: () => onStop?.call(),
      onFrame: (frameNo) => onFrame?.call(frameNo),
      onRender: (frameNo) => onRender?.call(frameNo),
      onLoop: (loopCount) => onLoop?.call(loopCount),
    );
  }

  Future<void> createPlayer() async {
    return DotLottieFlutterPlatform.instance.createPlayer();
  }

  // Playback control methods
  Future<bool?> play() async {
    return DotLottieFlutterPlatform.instance.play();
  }

  Future<bool?> pause() async {
    return DotLottieFlutterPlatform.instance.pause();
  }

  Future<bool?> stop() async {
    return DotLottieFlutterPlatform.instance.stop();
  }

  // Animation properties getters
  Future<bool?> isPlaying() async {
    return DotLottieFlutterPlatform.instance.isPlaying();
  }

  Future<bool?> isPaused() async {
    return DotLottieFlutterPlatform.instance.isPaused();
  }

  Future<bool?> isStopped() async {
    return DotLottieFlutterPlatform.instance.isStopped();
  }

  Future<bool?> isLoaded() async {
    return DotLottieFlutterPlatform.instance.isLoaded();
  }

  Future<double?> currentFrame() async {
    return DotLottieFlutterPlatform.instance.currentFrame();
  }

  Future<double?> totalFrames() async {
    return DotLottieFlutterPlatform.instance.totalFrames();
  }

  Future<double?> duration() async {
    return DotLottieFlutterPlatform.instance.duration();
  }

  Future<int?> loopCount() async {
    return DotLottieFlutterPlatform.instance.loopCount();
  }

  Future<double?> speed() async {
    return DotLottieFlutterPlatform.instance.speed();
  }

  Future<bool?> loop() async {
    return DotLottieFlutterPlatform.instance.loop();
  }

  Future<bool?> autoplay() async {
    return DotLottieFlutterPlatform.instance.autoplay();
  }

  Future<bool?> useFrameInterpolation() async {
    return DotLottieFlutterPlatform.instance.useFrameInterpolation();
  }

  Future<List<double>?> segments() async {
    return DotLottieFlutterPlatform.instance.segments();
  }

  Future<String?> mode() async {
    return DotLottieFlutterPlatform.instance.mode();
  }

  // Animation control setters
  Future<void> setSpeed(double speed) async {
    return DotLottieFlutterPlatform.instance.setSpeed(speed);
  }

  Future<void> setLoop(bool loop) async {
    return DotLottieFlutterPlatform.instance.setLoop(loop);
  }

  Future<bool?> setFrame(double frame) async {
    return DotLottieFlutterPlatform.instance.setFrame(frame);
  }

  Future<bool?> setProgress(double progress) async {
    return DotLottieFlutterPlatform.instance.setProgress(progress);
  }

  Future<void> setSegment(double start, double end) async {
    return DotLottieFlutterPlatform.instance.setSegment(start, end);
  }

  Future<void> setMode(String mode) async {
    return DotLottieFlutterPlatform.instance.setMode(mode);
  }

  Future<void> setFrameInterpolation(bool useFrameInterpolation) async {
    return DotLottieFlutterPlatform.instance.setFrameInterpolation(
      useFrameInterpolation,
    );
  }

  Future<void> setBackgroundColor(String color) async {
    return DotLottieFlutterPlatform.instance.setBackgroundColor(color);
  }

  // Theme methods
  Future<bool?> setTheme(String themeId) async {
    return DotLottieFlutterPlatform.instance.setTheme(themeId);
  }

  Future<bool?> setThemeData(String themeData) async {
    return DotLottieFlutterPlatform.instance.setThemeData(themeData);
  }

  Future<bool?> resetTheme() async {
    return DotLottieFlutterPlatform.instance.resetTheme();
  }

  Future<String?> activeThemeId() async {
    return DotLottieFlutterPlatform.instance.activeThemeId();
  }

  Future<String?> activeAnimationId() async {
    return DotLottieFlutterPlatform.instance.activeAnimationId();
  }

  Future<List<Map<String, dynamic>>?> markers() async {
    return DotLottieFlutterPlatform.instance.markers();
  }

  Future<bool?> setSlots(String slots) async {
    return DotLottieFlutterPlatform.instance.setSlots(slots);
  }

  Future<void> resize(int width, int height) async {
    return DotLottieFlutterPlatform.instance.resize(width, height);
  }

  Future<List<double>?> getLayerBounds(String layerName) async {
    return DotLottieFlutterPlatform.instance.getLayerBounds(layerName);
  }

  // State machine methods
  Future<bool?> stateMachineLoad(String stateMachineId) async {
    return DotLottieFlutterPlatform.instance.stateMachineLoad(stateMachineId);
  }

  Future<bool?> stateMachineLoadData(String data) async {
    return DotLottieFlutterPlatform.instance.stateMachineLoadData(data);
  }

  Future<bool?> stateMachineStart() async {
    return DotLottieFlutterPlatform.instance.stateMachineStart();
  }

  Future<bool?> stateMachineStop() async {
    return DotLottieFlutterPlatform.instance.stateMachineStop();
  }

  Future<void> stateMachineFire(String event) async {
    return DotLottieFlutterPlatform.instance.stateMachineFire(event);
  }

  Future<bool?> stateMachineSetNumericInput(String key, double value) async {
    return DotLottieFlutterPlatform.instance.stateMachineSetNumericInput(
      key,
      value,
    );
  }

  Future<bool?> stateMachineSetStringInput(String key, String value) async {
    return DotLottieFlutterPlatform.instance.stateMachineSetStringInput(
      key,
      value,
    );
  }

  Future<bool?> stateMachineSetBooleanInput(String key, bool value) async {
    return DotLottieFlutterPlatform.instance.stateMachineSetBooleanInput(
      key,
      value,
    );
  }

  Future<double?> stateMachineGetNumericInput(String key) async {
    return DotLottieFlutterPlatform.instance.stateMachineGetNumericInput(key);
  }

  Future<String?> stateMachineGetStringInput(String key) async {
    return DotLottieFlutterPlatform.instance.stateMachineGetStringInput(key);
  }

  Future<bool?> stateMachineGetBooleanInput(String key) async {
    return DotLottieFlutterPlatform.instance.stateMachineGetBooleanInput(key);
  }

  Future<Map<String, String>?> stateMachineGetInputs() async {
    return DotLottieFlutterPlatform.instance.stateMachineGetInputs();
  }

  Future<String?> stateMachineCurrentState() async {
    return DotLottieFlutterPlatform.instance.stateMachineCurrentState();
  }

  Future<String?> getStateMachine(String id) async {
    return DotLottieFlutterPlatform.instance.getStateMachine(id);
  }

  Future<Map<String, dynamic>?> manifest() async {
    return DotLottieFlutterPlatform.instance.manifest();
  }
}
