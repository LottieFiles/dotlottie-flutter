import 'dotlottie_flutter_platform_interface.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';

import 'src/desktop/dotlottie_desktop_player_stub.dart'
    if (dart.library.ffi) 'src/desktop/dotlottie_desktop_player.dart';

/// Maps a Flutter [BoxFit] to the fit string understood by the native players.
/// Returns `null` when [fit] is `null`. `scaleDown` has no native equivalent and
/// is approximated by `contain`.
String? _boxFitToFitString(BoxFit? fit) {
  switch (fit) {
    case BoxFit.contain:   return 'contain';
    case BoxFit.cover:     return 'cover';
    case BoxFit.fill:      return 'fill';
    case BoxFit.fitWidth:  return 'fitWidth';
    case BoxFit.fitHeight: return 'fitHeight';
    case BoxFit.none:      return 'none';
    case BoxFit.scaleDown: return 'contain';
    case null:             return null;
  }
}

/// A Flutter widget that renders a dotLottie or Lottie animation.
///
/// Supports loading animations from a URL, an asset file, or a raw JSON string.
/// Use [onViewCreated] to obtain a [DotLottieViewController] for programmatic
/// playback control after the native view is ready.
///
/// ```dart
/// DotLottieView(
///   sourceType: 'url',
///   source: 'https://example.com/animation.lottie',
///   autoplay: true,
///   loop: true,
///   onViewCreated: (controller) => _controller = controller,
/// )
/// ```
class DotLottieView extends StatefulWidget {
  /// Whether the animation starts playing immediately after loading.
  final bool? autoplay;

  /// Whether the animation loops indefinitely.
  final bool? loop;

  /// Number of times to loop before stopping. Ignored when [loop] is `true`.
  final int? loopCount;

  /// Playback direction. One of `'forward'`, `'reverse'`, `'bounce'`, or `'reverseBounce'`.
  final String? mode;

  /// Playback speed multiplier. `1.0` is normal speed.
  final double? speed;

  /// Whether to interpolate frames between keyframes for smoother playback.
  final bool? useFrameInterpolation;

  /// Frame range to play, expressed as `[startFrame, endFrame]`.
  final List<num>? segment;

  /// Background color as a hex string, e.g. `'#FF0000'`.
  final String? backgroundColor;

  /// How the animation should be inscribed into the space allocated during layout.
  final BoxFit? fit;

  /// Named marker to seek to on load.
  final String? marker;

  /// ID of the theme to apply from the dotLottie file.
  final String? themeId;

  /// ID of the state machine to activate on load.
  final String? stateMachineId;

  /// ID of the animation to display when the file contains multiple animations.
  final String? animationId;

  /// How [source] is interpreted. One of `'url'`, `'asset'`, or `'json'`.
  final String sourceType;

  /// The animation source — a URL, asset path relative to `assets/`, or raw JSON string.
  final String source;

  /// Enables GPU-accelerated OpenGL rendering on Android via [DotLottieGLAnimation].
  ///
  /// The underlying Android API is marked experimental and may change in future
  /// releases of the dotlottie-android library. Has no effect on non-Android platforms.
  final bool useOpenGL;

  /// Explicit width in logical pixels. When `null` the widget expands to fill available space.
  final int? width;

  /// Explicit height in logical pixels. When `null` the widget expands to fill available space.
  final int? height;

  /// Called once the native platform view is ready, providing a [DotLottieViewController].
  final Function(DotLottieViewController)? onViewCreated;

  /// Called when the animation finishes playing (non-looping only).
  final VoidCallback? onComplete;

  /// Called when the animation has been loaded and is ready to play.
  final VoidCallback? onLoad;

  /// Called when the animation fails to load.
  final VoidCallback? onLoadError;

  /// Called when playback starts or resumes.
  final VoidCallback? onPlay;

  /// Called when playback is paused.
  final VoidCallback? onPause;

  /// Called when playback is stopped.
  final VoidCallback? onStop;

  /// Called on every frame advance with the current frame number.
  final Function(double frameNo)? onFrame;

  /// Called each time a frame is rendered with the rendered frame number.
  final Function(double frameNo)? onRender;

  /// Called each time a loop completes with the current loop count.
  final Function(int loopCount)? onLoop;

  /// Called when a boolean state machine input changes value.
  final Function(String inputName, bool oldValue, bool newValue)?
  stateMachineOnBooleanInputValueChange;

  /// Called when the state machine encounters an error.
  final Function(String message)? stateMachineOnError;

  /// Called when a numeric state machine input changes value.
  final Function(String inputName, double oldValue, double newValue)?
  stateMachineOnNumericInputValueChange;

  /// Called when the state machine starts.
  final VoidCallback? stateMachineOnStart;

  /// Called when the state machine stops.
  final VoidCallback? stateMachineOnStop;

  /// Called when a trigger input is fired by name.
  final Function(String inputName)? stateMachineOnInputFired;

  /// Called when a string state machine input changes value.
  final Function(String inputName, String oldValue, String newValue)?
  stateMachineOnStringInputValueChange;

  /// Called when the state machine emits a custom event string.
  final Function(String message)? stateMachineOnCustomEvent;

  /// Called when the state machine transitions into a new state.
  final Function(String enteringState)? stateMachineOnStateEntered;

  /// Called when the state machine exits a state.
  final Function(String leavingState)? stateMachineOnStateExit;

  /// Called when the state machine transitions between states.
  final Function(String previousState, String newState)?
  stateMachineOnTransition;

  /// Creates a [DotLottieView].
  ///
  /// [sourceType] and [source] are required. All other parameters are optional
  /// and mirror the dotLottie player configuration options.
  const DotLottieView({
    super.key,
    required this.sourceType,
    required this.source,
    this.autoplay = false,
    this.loop = false,
    this.speed = 1.0,
    this.mode = 'forward',
    this.useFrameInterpolation = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.fit,
    this.useOpenGL = false,
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
    this.stateMachineOnBooleanInputValueChange,
    this.stateMachineOnError,
    this.stateMachineOnNumericInputValueChange,
    this.stateMachineOnStart,
    this.stateMachineOnStop,
    this.stateMachineOnInputFired,
    this.stateMachineOnStringInputValueChange,
    this.stateMachineOnCustomEvent,
    this.stateMachineOnStateEntered,
    this.stateMachineOnStateExit,
    this.stateMachineOnTransition,
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
  late Future<Map<String, dynamic>> _creationParamsFuture;
  int _platformViewGeneration = 0;

  @override
  void initState() {
    super.initState();
    _creationParamsFuture = _getCreationParams();
  }

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      _platformViewGeneration++;
      _creationParamsFuture = _getCreationParams();
    });
  }

  @override
  void didUpdateWidget(DotLottieView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.sourceType != widget.sourceType) {
      setState(() {
        _platformViewGeneration++;
        _creationParamsFuture = _getCreationParams();
      });
    } else if (oldWidget.fit != widget.fit && widget.fit != null) {
      // A live fit change doesn't require rebuilding the platform view — push it
      // to the native player via setLayout so it takes effect on the next frame.
      _controller?.setLayout(widget.fit!);
    }
  }

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
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
               defaultTargetPlatform == TargetPlatform.linux) {
      return _buildDesktopView();
    }
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Text('Platform not supported')),
    );
  }

  Widget _buildAndroidView() {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_platformViewGeneration),
      future: _creationParamsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        // The GL renderer uses TextureView, which renders to its own SurfaceTexture
        // via OpenGL. Flutter's default TLHC mode captures platform view content via
        // the Canvas pipeline and misses TextureView's GL output on the first frame.
        // Hybrid Composition (HC) embeds the view directly in Android's real view
        // hierarchy, where TextureView renders correctly.
        if (widget.useOpenGL) {
          return PlatformViewLink(
            viewType: 'dotlottie_view',
            surfaceFactory: (context, controller) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers:
                    const <Factory<OneSequenceGestureRecognizer>>{},
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              );
            },
            onCreatePlatformView: (params) {
              return PlatformViewsService.initExpensiveAndroidView(
                id: params.id,
                viewType: 'dotlottie_view',
                layoutDirection: TextDirection.ltr,
                creationParams: snapshot.data,
                creationParamsCodec: const StandardMessageCodec(),
              )
                ..addOnPlatformViewCreatedListener(
                    params.onPlatformViewCreated)
                ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
                ..create();
            },
          );
        }

        return AndroidView(
          viewType: 'dotlottie_view',
          creationParams: snapshot.data,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        );
      },
    );
  }

  Widget _buildWebView() {
    return HtmlElementView(
      key: ValueKey(_platformViewGeneration),
      viewType: 'dotlottie_view',
      onPlatformViewCreated: (int viewId) async {
        _onPlatformViewCreated(viewId);

        // For web, send initialization after a short delay to ensure view is ready
        await Future.delayed(const Duration(milliseconds: 150));

        if (_controller != null && mounted) {
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
          } catch (e) {
            debugPrint('🔴 Flutter: Error sending initialize: $e');
          }
        }
      },
    );
  }

  Widget _buildIOSView() {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_platformViewGeneration),
      future: _creationParamsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        return UiKitView(
          viewType: 'dotlottie_view',
          creationParams: snapshot.data,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        );
      },
    );
  }

  Widget _buildMacOSView() {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_platformViewGeneration),
      future: _creationParamsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        return AppKitView(
          viewType: 'dotlottie_view',
          creationParams: snapshot.data,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        );
      },
    );
  }

  Widget _buildDesktopView() {
    return LayoutBuilder(
      key: ValueKey(_platformViewGeneration),
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;
        return _DotLottieDesktopWidget(
          sourceType: widget.sourceType,
          source: widget.source,
          autoplay: widget.autoplay ?? false,
          loop: widget.loop ?? false,
          loopCount: widget.loopCount ?? 0,
          speed: widget.speed ?? 1.0,
          mode: widget.mode ?? 'forward',
          useFrameInterpolation: widget.useFrameInterpolation ?? false,
          logicalWidth: w,
          logicalHeight: h,
          devicePixelRatio: dpr,
          onViewCreated: widget.onViewCreated,
          onLoad: widget.onLoad,
          onLoadError: widget.onLoadError,
          onPlay: widget.onPlay,
          onPause: widget.onPause,
          onStop: widget.onStop,
          onComplete: widget.onComplete,
          onFrame: widget.onFrame,
          onRender: widget.onRender,
          onLoop: widget.onLoop,
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCreationParams() async {
    Map<String, dynamic> params = {
      'autoplay': widget.autoplay,
      'loop': widget.loop,
      'loopCount': widget.loopCount,
      'mode': widget.mode,
      'speed': widget.speed,
      'useFrameInterpolation': widget.useFrameInterpolation,
      if (widget.segment != null) 'segment': widget.segment,
      if (widget.backgroundColor != null)
        'backgroundColor': widget.backgroundColor,
      if (widget.fit != null) 'fit': _boxFitToFitString(widget.fit),
      if (widget.marker != null) 'marker': widget.marker,
      if (widget.themeId != null) 'themeId': widget.themeId,
      if (widget.stateMachineId != null)
        'stateMachineId': widget.stateMachineId,
      if (widget.animationId != null) 'animationId': widget.animationId,
      if (widget.width != null) 'width': widget.width,
      if (widget.height != null) 'height': widget.height,
      if (widget.useOpenGL && defaultTargetPlatform == TargetPlatform.android)
        'useOpenGL': true,
    };

    // Handle asset loading
    if (widget.sourceType == 'asset') {
      final ByteData data = await rootBundle.load('assets/${widget.source}');
      final Uint8List bytes = data.buffer.asUint8List();

      // Check if it's a JSON file
      if (widget.source.toLowerCase().endsWith('.json')) {
        // Convert bytes to string for JSON
        final String jsonString = utf8.decode(bytes);
        params['sourceType'] = 'json';
        params['source'] = jsonString;
      } else {
        // It's a .lottie file (binary)
        params['sourceType'] = 'data';
        params['source'] = bytes;
      }
    } else {
      params['sourceType'] = widget.sourceType;
      params['source'] = widget.source;
    }

    return params;
  }

  void _onPlatformViewCreated(int viewId) {
    // Tear down old channel and tell old native view to clean up (important for
    // macOS which holds a strong factory reference and won't self-dispose).
    _methodChannel?.setMethodCallHandler(null);
    _controller?.dispose();

    _methodChannel = MethodChannel('dotlottie_view_$viewId');
    _methodChannel!.setMethodCallHandler(_handleMethodCall);
    _controller = DotLottieViewController._(viewId);

    if (widget.onViewCreated != null) {
      widget.onViewCreated!(_controller!);
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (!mounted) return;

    switch (call.method) {
      case 'onComplete':
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
        break;

      case 'onLoad':
        if (widget.onLoad != null) {
          widget.onLoad!();
        }
        break;

      case 'onLoadError':
        if (widget.onLoadError != null) {
          widget.onLoadError!();
        }
        break;

      case 'onPlay':
        if (widget.onPlay != null) {
          widget.onPlay!();
        }
        break;

      case 'onPause':
        if (widget.onPause != null) {
          widget.onPause!();
        }
        break;

      case 'onFrame':
        final frameNo = (call.arguments as num).toDouble();
        if (widget.onFrame != null) {
          widget.onFrame!(frameNo);
        }
        break;

      case 'onRender':
        final frameNo = (call.arguments as num).toDouble();
        if (widget.onRender != null) {
          widget.onRender!(frameNo);
        }
        break;

      case 'onStop':
        if (widget.onStop != null) {
          widget.onStop!();
        }
        break;

      case 'onLoop':
        final loopCount = call.arguments as int;
        if (widget.onLoop != null) {
          widget.onLoop!(loopCount);
        }
        break;

      case 'stateMachineOnBooleanInputValueChange':
        if (widget.stateMachineOnBooleanInputValueChange != null) {
          final args = call.arguments as Map;
          widget.stateMachineOnBooleanInputValueChange!(
            args['inputName'] as String,
            args['oldValue'] as bool,
            args['newValue'] as bool,
          );
        }
        break;
      case 'stateMachineOnError':
        final message = call.arguments as String;
        if (widget.stateMachineOnError != null) {
          widget.stateMachineOnError!(message);
        }
        break;
      case 'stateMachineOnNumericInputValueChange':
        final args = call.arguments as Map;
        if (widget.stateMachineOnNumericInputValueChange != null) {
          widget.stateMachineOnNumericInputValueChange!(
            args['inputName'] as String,
            (args['oldValue'] as num).toDouble(),
            (args['newValue'] as num).toDouble(),
          );
        }
        break;
      case 'stateMachineOnStart':
        if (widget.stateMachineOnStart != null) {
          widget.stateMachineOnStart!();
        }
        break;
      case 'stateMachineOnStop':
        if (widget.stateMachineOnStop != null) {
          widget.stateMachineOnStop!();
        }
        break;
      case 'stateMachineOnInputFired':
        final inputName = call.arguments as String;
        if (widget.stateMachineOnInputFired != null) {
          widget.stateMachineOnInputFired!(inputName);
        }
        break;
      case 'stateMachineOnStringInputValueChange':
        final args = call.arguments as Map;
        if (widget.stateMachineOnStringInputValueChange != null) {
          widget.stateMachineOnStringInputValueChange!(
            args['inputName'] as String,
            args['oldValue'] as String,
            args['newValue'] as String,
          );
        }
        break;
      case 'stateMachineOnCustomEvent':
        final message = call.arguments as String;
        if (widget.stateMachineOnCustomEvent != null) {
          widget.stateMachineOnCustomEvent!(message);
        }
        break;
      case 'stateMachineOnStateEntered':
        final enteringState = call.arguments as String;
        if (widget.stateMachineOnStateEntered != null) {
          widget.stateMachineOnStateEntered!(enteringState);
        }
        break;
      case 'stateMachineOnStateExit':
        final leavingState = call.arguments as String;
        if (widget.stateMachineOnStateExit != null) {
          widget.stateMachineOnStateExit!(leavingState);
        }
        break;
      case 'stateMachineOnTransition':
        try {
          final args = call.arguments as Map;
          if (widget.stateMachineOnTransition != null) {
            widget.stateMachineOnTransition!(
              args['previousState'] as String,
              args['newState'] as String,
            );
          }
        } catch (e) {
          debugPrint('Error in stateMachineOnTransition: $e');
        }

      default:
        {}
    }
  }

  @override
  void dispose() {
    _methodChannel?.setMethodCallHandler(null);
    _controller?.dispose();
    super.dispose();
  }
}

/// Controls a [DotLottieView] after the native platform view has been created.
///
/// Obtain an instance via [DotLottieView.onViewCreated]. All methods are
/// asynchronous and communicate with the native player over a [MethodChannel].
class DotLottieViewController {
  final int _viewId;
  late final MethodChannel _channel;

  DotLottieViewController._(this._viewId) {
    _channel = MethodChannel('dotlottie_view_$_viewId');
  }

  /// Starts or resumes playback. Returns `true` on success.
  Future<bool?> play() async {
    try {
      return await _channel.invokeMethod<bool>('play');
    } catch (e) {
      debugPrint('Error calling play: $e');
      return false;
    }
  }

  /// Pauses playback at the current frame. Returns `true` on success.
  Future<bool?> pause() async {
    try {
      return await _channel.invokeMethod<bool>('pause');
    } catch (e) {
      debugPrint('Error calling pause: $e');
      return false;
    }
  }

  /// Stops playback and resets to the first frame. Returns `true` on success.
  Future<bool?> stop() async {
    try {
      return await _channel.invokeMethod<bool>('stop');
    } catch (e) {
      debugPrint('Error calling stop: $e');
      return false;
    }
  }

  /// Returns `true` if the animation is currently playing.
  Future<bool?> isPlaying() async {
    try {
      return await _channel.invokeMethod<bool>('isPlaying');
    } catch (e) {
      debugPrint('Error calling isPlaying: $e');
      return false;
    }
  }

  /// Returns `true` if the animation is paused.
  Future<bool?> isPaused() async {
    try {
      return await _channel.invokeMethod<bool>('isPaused');
    } catch (e) {
      debugPrint('Error calling isPaused: $e');
      return false;
    }
  }

  /// Returns `true` if the animation is stopped.
  Future<bool?> isStopped() async {
    try {
      return await _channel.invokeMethod<bool>('isStopped');
    } catch (e) {
      debugPrint('Error calling isStopped: $e');
      return false;
    }
  }

  /// Returns `true` if an animation has been successfully loaded.
  Future<bool?> isLoaded() async {
    try {
      return await _channel.invokeMethod<bool>('isLoaded');
    } catch (e) {
      debugPrint('Error calling isLoaded: $e');
      return false;
    }
  }

  /// Returns the current playback position as a frame number.
  Future<double?> currentFrame() async {
    try {
      return await _channel.invokeMethod<double>('currentFrame');
    } catch (e) {
      debugPrint('Error calling currentFrame: $e');
      return null;
    }
  }

  /// Returns the total number of frames in the animation.
  Future<double?> totalFrames() async {
    try {
      return await _channel.invokeMethod<double>('totalFrames');
    } catch (e) {
      debugPrint('Error calling totalFrames: $e');
      return null;
    }
  }

  /// Returns the current playback position as a value between `0.0` and `1.0`.
  Future<double?> currentProgress() async {
    try {
      return await _channel.invokeMethod<double>('currentProgress');
    } catch (e) {
      debugPrint('Error calling currentProgress: $e');
      return null;
    }
  }

  /// Returns the total duration of the animation in seconds.
  Future<double?> duration() async {
    try {
      return await _channel.invokeMethod<double>('duration');
    } catch (e) {
      debugPrint('Error calling duration: $e');
      return null;
    }
  }

  /// Returns how many times the animation has looped since playback started.
  Future<int?> loopCount() async {
    try {
      return await _channel.invokeMethod<int>('loopCount');
    } catch (e) {
      debugPrint('Error calling loopCount: $e');
      return null;
    }
  }

  /// Returns the current playback speed multiplier.
  Future<double?> speed() async {
    try {
      return await _channel.invokeMethod<double>('speed');
    } catch (e) {
      debugPrint('Error calling speed: $e');
      return null;
    }
  }

  /// Returns `true` if the animation is set to loop.
  Future<bool?> loop() async {
    try {
      return await _channel.invokeMethod<bool>('loop');
    } catch (e) {
      debugPrint('Error calling loop: $e');
      return false;
    }
  }

  /// Returns `true` if the animation is configured to play automatically on load.
  Future<bool?> autoplay() async {
    try {
      return await _channel.invokeMethod<bool>('autoplay');
    } catch (e) {
      debugPrint('Error calling autoplay: $e');
      return false;
    }
  }

  /// Returns `true` if frame interpolation is enabled.
  Future<bool?> useFrameInterpolation() async {
    try {
      return await _channel.invokeMethod<bool>('useFrameInterpolation');
    } catch (e) {
      debugPrint('Error calling useFrameInterpolation: $e');
      return false;
    }
  }

  /// Returns the active frame segment as `[startFrame, endFrame]`.
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

  /// Returns the current playback mode string (e.g. `'forward'`, `'reverse'`).
  Future<String?> mode() async {
    try {
      return await _channel.invokeMethod<String>('mode');
    } catch (e) {
      debugPrint('Error calling mode: $e');
      return null;
    }
  }

  /// Sets the playback speed multiplier.
  Future<void> setSpeed(double speed) async {
    try {
      await _channel.invokeMethod('setSpeed', {'speed': speed});
    } catch (e) {
      debugPrint('Error calling setSpeed: $e');
    }
  }

  /// Enables or disables looping.
  Future<void> setLoop(bool loop) async {
    try {
      await _channel.invokeMethod('setLoop', {'loop': loop});
    } catch (e) {
      debugPrint('Error calling setLoop: $e');
    }
  }

  /// Seeks to a specific frame number. Returns `true` on success.
  Future<bool?> setFrame(double frame) async {
    try {
      return await _channel.invokeMethod<bool>('setFrame', {'frame': frame});
    } catch (e) {
      debugPrint('Error calling setFrame: $e');
      return false;
    }
  }

  /// Seeks to a normalized progress position between `0.0` and `1.0`. Returns `true` on success.
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

  /// Constrains playback to the frame range `[start, end]`.
  Future<void> setSegments(double start, double end) async {
    try {
      await _channel.invokeMethod('setSegments', {'start': start, 'end': end});
    } catch (e) {
      debugPrint('Error calling setSegments: $e');
    }
  }

  /// Seeks to the named marker defined in the animation file.
  Future<void> setMarker(String marker) async {
    try {
      await _channel.invokeMethod('setMarker', {'marker': marker});
    } catch (e) {
      debugPrint('Error calling setMarker: $e');
    }
  }

  /// Sets the playback direction mode. Accepted values: `'forward'`, `'reverse'`, `'bounce'`, `'reverseBounce'`.
  Future<void> setMode(String mode) async {
    try {
      await _channel.invokeMethod('setMode', {'mode': mode});
    } catch (e) {
      debugPrint('Error calling setMode: $e');
    }
  }

  /// Enables or disables between-frame interpolation.
  Future<void> setFrameInterpolation(bool useFrameInterpolation) async {
    try {
      await _channel.invokeMethod('setFrameInterpolation', {
        'useFrameInterpolation': useFrameInterpolation,
      });
    } catch (e) {
      debugPrint('Error calling setFrameInterpolation: $e');
    }
  }

  /// Applies the theme with the given [themeId] from the dotLottie file. Returns `true` on success.
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

  /// Applies a theme from a raw theme data string. Returns `true` on success.
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

  /// Resets the theme to the animation's default. Returns `true` on success.
  Future<bool?> resetTheme() async {
    try {
      return await _channel.invokeMethod<bool>('resetTheme');
    } catch (e) {
      debugPrint('Error calling resetTheme: $e');
      return false;
    }
  }

  /// Returns the ID of the currently active theme, or `null` if none is applied.
  Future<String?> activeThemeId() async {
    try {
      return await _channel.invokeMethod<String>('activeThemeId');
    } catch (e) {
      debugPrint('Error calling activeThemeId: $e');
      return null;
    }
  }

  /// Loads the animation identified by [animationId] from a multi-animation dotLottie file.
  Future<void> loadAnimation(String animationId) async {
    try {
      await _channel.invokeMethod('loadAnimation', {
        'animationId': animationId,
      });
    } catch (e) {
      debugPrint('Error calling loadAnimation: $e');
    }
  }

  /// Returns the ID of the currently displayed animation.
  Future<String?> activeAnimationId() async {
    try {
      return await _channel.invokeMethod<String>('activeAnimationId');
    } catch (e) {
      debugPrint('Error calling activeAnimationId: $e');
      return null;
    }
  }

  /// Returns the list of named markers defined in the animation.
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

  /// Applies dynamic slot data to the animation. Returns `true` on success.
  Future<bool?> setSlots(String slots) async {
    try {
      return await _channel.invokeMethod<bool>('setSlots', {'slots': slots});
    } catch (e) {
      debugPrint('Error calling setSlots: $e');
      return false;
    }
  }

  /// Resizes the animation canvas to the given [width] and [height] in pixels.
  Future<void> resize(int width, int height) async {
    try {
      await _channel.invokeMethod('resize', {'width': width, 'height': height});
    } catch (e) {
      debugPrint('Error calling resize: $e');
    }
  }

  /// Updates how the animation is fitted and aligned within the view at runtime.
  ///
  /// [fit] controls scaling (mapped from [BoxFit]); [alignment] positions the
  /// animation within any leftover space and defaults to [Alignment.center].
  /// The change takes effect on the next rendered frame without recreating the
  /// view. This is invoked automatically when [DotLottieView.fit] changes.
  Future<void> setLayout(
    BoxFit fit, {
    Alignment alignment = Alignment.center,
  }) async {
    try {
      await _channel.invokeMethod('setLayout', {
        'fit': _boxFitToFitString(fit),
        // Native players expect alignment in the 0..1 range, whereas Flutter's
        // Alignment is -1..1; convert here.
        'alignX': (alignment.x + 1) / 2,
        'alignY': (alignment.y + 1) / 2,
      });
    } catch (e) {
      debugPrint('Error calling setLayout: $e');
    }
  }

  /// Loads the state machine identified by [stateMachineId]. Returns `true` on success.
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

  /// Loads a state machine from a raw JSON [data] string. Returns `true` on success.
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

  /// Starts the loaded state machine. Returns `true` on success.
  Future<bool?> stateMachineStart() async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineStart');
    } catch (e) {
      debugPrint('Error calling stateMachineStart: $e');
      return false;
    }
  }

  /// Stops the running state machine. Returns `true` on success.
  Future<bool?> stateMachineStop() async {
    try {
      return await _channel.invokeMethod<bool>('stateMachineStop');
    } catch (e) {
      debugPrint('Error calling stateMachineStop: $e');
      return false;
    }
  }

  /// Fires a trigger [event] on the active state machine.
  Future<void> stateMachineFire(String event) async {
    try {
      await _channel.invokeMethod('stateMachineFire', {'event': event});
    } catch (e) {
      debugPrint('Error calling stateMachineFire: $e');
    }
  }

  /// Sets a numeric input on the active state machine. Returns `true` on success.
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

  /// Sets a string input on the active state machine. Returns `true` on success.
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

  /// Sets a boolean input on the active state machine. Returns `true` on success.
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

  /// Returns the current numeric value of the named state machine input.
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

  /// Returns the current string value of the named state machine input.
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

  /// Returns the current boolean value of the named state machine input.
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

  /// Returns a map of all current state machine input names to their type strings.
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

  /// Returns the name of the state machine's current active state.
  Future<String?> stateMachineCurrentState() async {
    try {
      return await _channel.invokeMethod<String>('stateMachineCurrentState');
    } catch (e) {
      debugPrint('Error calling stateMachineCurrentState: $e');
      return null;
    }
  }

  /// Returns the raw JSON definition of the state machine with the given [id].
  Future<String?> getStateMachine(String id) async {
    try {
      return await _channel.invokeMethod<String>('getStateMachine', {'id': id});
    } catch (e) {
      debugPrint('Error calling getStateMachine: $e');
      return null;
    }
  }

  /// Returns the dotLottie file manifest, including animation and theme metadata.
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

  /// Releases native resources held by this controller.
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error calling dispose: $e');
    }
  }
}

/// Low-level API for controlling a dotLottie player via the platform interface.
///
/// This class wraps [DotLottieFlutterPlatform] and provides callback-based
/// event handling for playback and state machine events. For widget-based usage,
/// prefer [DotLottieView] with [DotLottieViewController].
class DotLottieFlutter {
  /// Called when the animation finishes playing (non-looping).
  void Function()? onComplete;

  /// Called when the animation has loaded successfully.
  void Function()? onLoad;

  /// Called when the animation fails to load.
  void Function()? onLoadError;

  /// Called when playback starts or resumes.
  void Function()? onPlay;

  /// Called when playback is paused.
  void Function()? onPause;

  /// Called when playback is stopped.
  void Function()? onStop;

  /// Called on every frame advance with the current frame number.
  void Function(double frameNo)? onFrame;

  /// Called each time a frame is rendered with the rendered frame number.
  void Function(double frameNo)? onRender;

  /// Called each time a loop completes with the current loop count.
  void Function(int loopCount)? onLoop;

  /// Called when a boolean state machine input changes value.
  void Function(String inputName, bool oldValue, bool newValue)?
  stateMachineOnBooleanInputValueChange;

  /// Called when the state machine encounters an error.
  void Function(String message)? stateMachineOnError;

  /// Called when a numeric state machine input changes value.
  void Function(String inputName, double oldValue, double newValue)?
  stateMachineOnNumericInputValueChange;

  /// Called when the state machine starts.
  void Function()? stateMachineOnStart;

  /// Called when the state machine stops.
  void Function()? stateMachineOnStop;

  /// Called when a trigger input is fired by name.
  void Function(String inputName)? stateMachineOnInputFired;

  /// Called when a string state machine input changes value.
  void Function(String inputName, String oldValue, String newValue)?
  stateMachineOnStringInputValueChange;

  /// Called when the state machine emits a custom event string.
  void Function(String message)? stateMachineOnCustomEvent;

  /// Called when the state machine transitions into a new state.
  void Function(String enteringState)? stateMachineOnStateEntered;

  /// Called when the state machine exits a state.
  void Function(String leavingState)? stateMachineOnStateExit;

  /// Called when the state machine transitions between states.
  void Function(String previousState, String newState)?
  stateMachineOnTransition;

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

    DotLottieFlutterPlatform.instance.setStateMachineEventHandlers(
      stateMachineOnBooleanInputValueChange: (inputName, oldValue, newValue) =>
          stateMachineOnBooleanInputValueChange?.call(
            inputName,
            oldValue,
            newValue,
          ),
      stateMachineOnError: (message) => stateMachineOnError?.call(message),
      stateMachineOnNumericInputValueChange: (inputName, oldValue, newValue) =>
          stateMachineOnNumericInputValueChange?.call(
            inputName,
            oldValue,
            newValue,
          ),
      stateMachineOnStart: () => stateMachineOnStart?.call(),
      stateMachineOnStop: () => stateMachineOnStop?.call(),
      stateMachineOnInputFired: (inputName) =>
          stateMachineOnInputFired?.call(inputName),
      stateMachineOnStringInputValueChange: (inputName, oldValue, newValue) =>
          stateMachineOnStringInputValueChange?.call(
            inputName,
            oldValue,
            newValue,
          ),
      stateMachineOnCustomEvent: (message) =>
          stateMachineOnCustomEvent?.call(message),
      stateMachineOnStateEntered: (enteringState) =>
          stateMachineOnStateEntered?.call(enteringState),
      stateMachineOnStateExit: (leavingState) =>
          stateMachineOnStateExit?.call(leavingState),
      stateMachineOnTransition: (previousState, newState) =>
          stateMachineOnTransition?.call(previousState, newState),
    );
  }

  /// Initializes the native dotLottie player instance.
  Future<void> createPlayer() async {
    return DotLottieFlutterPlatform.instance.createPlayer();
  }

  /// Starts or resumes playback. Returns `true` on success.
  Future<bool?> play() async {
    return DotLottieFlutterPlatform.instance.play();
  }

  /// Pauses playback. Returns `true` on success.
  Future<bool?> pause() async {
    return DotLottieFlutterPlatform.instance.pause();
  }

  /// Stops playback and resets to the first frame. Returns `true` on success.
  Future<bool?> stop() async {
    return DotLottieFlutterPlatform.instance.stop();
  }

  /// Returns `true` if the animation is currently playing.
  Future<bool?> isPlaying() async {
    return DotLottieFlutterPlatform.instance.isPlaying();
  }

  /// Returns `true` if the animation is paused.
  Future<bool?> isPaused() async {
    return DotLottieFlutterPlatform.instance.isPaused();
  }

  /// Returns `true` if the animation is stopped.
  Future<bool?> isStopped() async {
    return DotLottieFlutterPlatform.instance.isStopped();
  }

  /// Returns `true` if an animation has been successfully loaded.
  Future<bool?> isLoaded() async {
    return DotLottieFlutterPlatform.instance.isLoaded();
  }

  /// Returns the current playback position as a frame number.
  Future<double?> currentFrame() async {
    return DotLottieFlutterPlatform.instance.currentFrame();
  }

  /// Returns the total number of frames in the animation.
  Future<double?> totalFrames() async {
    return DotLottieFlutterPlatform.instance.totalFrames();
  }

  /// Returns the total duration of the animation in seconds.
  Future<double?> duration() async {
    return DotLottieFlutterPlatform.instance.duration();
  }

  /// Returns how many times the animation has looped since playback started.
  Future<int?> loopCount() async {
    return DotLottieFlutterPlatform.instance.loopCount();
  }

  /// Returns the current playback speed multiplier.
  Future<double?> speed() async {
    return DotLottieFlutterPlatform.instance.speed();
  }

  /// Returns `true` if the animation is set to loop.
  Future<bool?> loop() async {
    return DotLottieFlutterPlatform.instance.loop();
  }

  /// Returns `true` if the animation is configured to play automatically on load.
  Future<bool?> autoplay() async {
    return DotLottieFlutterPlatform.instance.autoplay();
  }

  /// Returns `true` if frame interpolation is enabled.
  Future<bool?> useFrameInterpolation() async {
    return DotLottieFlutterPlatform.instance.useFrameInterpolation();
  }

  /// Returns the active frame segment as `[startFrame, endFrame]`.
  Future<List<double>?> segments() async {
    return DotLottieFlutterPlatform.instance.segments();
  }

  /// Returns the current playback mode string.
  Future<String?> mode() async {
    return DotLottieFlutterPlatform.instance.mode();
  }

  /// Sets the playback speed multiplier.
  Future<void> setSpeed(double speed) async {
    return DotLottieFlutterPlatform.instance.setSpeed(speed);
  }

  /// Enables or disables looping.
  Future<void> setLoop(bool loop) async {
    return DotLottieFlutterPlatform.instance.setLoop(loop);
  }

  /// Seeks to a specific frame number. Returns `true` on success.
  Future<bool?> setFrame(double frame) async {
    return DotLottieFlutterPlatform.instance.setFrame(frame);
  }

  /// Seeks to a normalized progress position between `0.0` and `1.0`. Returns `true` on success.
  Future<bool?> setProgress(double progress) async {
    return DotLottieFlutterPlatform.instance.setProgress(progress);
  }

  /// Constrains playback to the frame range `[start, end]`.
  Future<void> setSegment(double start, double end) async {
    return DotLottieFlutterPlatform.instance.setSegment(start, end);
  }

  /// Sets the playback direction mode.
  Future<void> setMode(String mode) async {
    return DotLottieFlutterPlatform.instance.setMode(mode);
  }

  /// Enables or disables between-frame interpolation.
  Future<void> setFrameInterpolation(bool useFrameInterpolation) async {
    return DotLottieFlutterPlatform.instance.setFrameInterpolation(
      useFrameInterpolation,
    );
  }

  /// Sets the background color as a hex string, e.g. `'#FF0000'`.
  Future<void> setBackgroundColor(String color) async {
    return DotLottieFlutterPlatform.instance.setBackgroundColor(color);
  }

  /// Applies the theme with the given [themeId]. Returns `true` on success.
  Future<bool?> setTheme(String themeId) async {
    return DotLottieFlutterPlatform.instance.setTheme(themeId);
  }

  /// Applies a theme from a raw theme data string. Returns `true` on success.
  Future<bool?> setThemeData(String themeData) async {
    return DotLottieFlutterPlatform.instance.setThemeData(themeData);
  }

  /// Resets the theme to the animation's default. Returns `true` on success.
  Future<bool?> resetTheme() async {
    return DotLottieFlutterPlatform.instance.resetTheme();
  }

  /// Returns the ID of the currently active theme.
  Future<String?> activeThemeId() async {
    return DotLottieFlutterPlatform.instance.activeThemeId();
  }

  /// Returns the ID of the currently displayed animation.
  Future<String?> activeAnimationId() async {
    return DotLottieFlutterPlatform.instance.activeAnimationId();
  }

  /// Returns the list of named markers defined in the animation.
  Future<List<Map<String, dynamic>>?> markers() async {
    return DotLottieFlutterPlatform.instance.markers();
  }

  /// Applies dynamic slot data to the animation. Returns `true` on success.
  Future<bool?> setSlots(String slots) async {
    return DotLottieFlutterPlatform.instance.setSlots(slots);
  }

  /// Resizes the animation canvas to [width] × [height] pixels.
  Future<void> resize(int width, int height) async {
    return DotLottieFlutterPlatform.instance.resize(width, height);
  }

  /// Loads the state machine identified by [stateMachineId]. Returns `true` on success.
  Future<bool?> stateMachineLoad(String stateMachineId) async {
    return DotLottieFlutterPlatform.instance.stateMachineLoad(stateMachineId);
  }

  /// Loads a state machine from a raw JSON string. Returns `true` on success.
  Future<bool?> stateMachineLoadData(String data) async {
    return DotLottieFlutterPlatform.instance.stateMachineLoadData(data);
  }

  /// Starts the loaded state machine. Returns `true` on success.
  Future<bool?> stateMachineStart() async {
    return DotLottieFlutterPlatform.instance.stateMachineStart();
  }

  /// Stops the running state machine. Returns `true` on success.
  Future<bool?> stateMachineStop() async {
    return DotLottieFlutterPlatform.instance.stateMachineStop();
  }

  /// Fires a named trigger [event] on the active state machine.
  Future<void> stateMachineFire(String event) async {
    return DotLottieFlutterPlatform.instance.stateMachineFire(event);
  }

  /// Sets a numeric input on the active state machine. Returns `true` on success.
  Future<bool?> stateMachineSetNumericInput(String key, double value) async {
    return DotLottieFlutterPlatform.instance.stateMachineSetNumericInput(
      key,
      value,
    );
  }

  /// Sets a string input on the active state machine. Returns `true` on success.
  Future<bool?> stateMachineSetStringInput(String key, String value) async {
    return DotLottieFlutterPlatform.instance.stateMachineSetStringInput(
      key,
      value,
    );
  }

  /// Sets a boolean input on the active state machine. Returns `true` on success.
  Future<bool?> stateMachineSetBooleanInput(String key, bool value) async {
    return DotLottieFlutterPlatform.instance.stateMachineSetBooleanInput(
      key,
      value,
    );
  }

  /// Returns the current numeric value of the named state machine input.
  Future<double?> stateMachineGetNumericInput(String key) async {
    return DotLottieFlutterPlatform.instance.stateMachineGetNumericInput(key);
  }

  /// Returns the current string value of the named state machine input.
  Future<String?> stateMachineGetStringInput(String key) async {
    return DotLottieFlutterPlatform.instance.stateMachineGetStringInput(key);
  }

  /// Returns the current boolean value of the named state machine input.
  Future<bool?> stateMachineGetBooleanInput(String key) async {
    return DotLottieFlutterPlatform.instance.stateMachineGetBooleanInput(key);
  }

  /// Returns a map of all state machine input names to their type strings.
  Future<Map<String, String>?> stateMachineGetInputs() async {
    return DotLottieFlutterPlatform.instance.stateMachineGetInputs();
  }

  /// Returns the name of the state machine's current active state.
  Future<String?> stateMachineCurrentState() async {
    return DotLottieFlutterPlatform.instance.stateMachineCurrentState();
  }

  /// Returns the raw JSON definition of the state machine with the given [id].
  Future<String?> getStateMachine(String id) async {
    return DotLottieFlutterPlatform.instance.getStateMachine(id);
  }

  /// Returns the dotLottie file manifest, including animation and theme metadata.
  Future<Map<String, dynamic>?> manifest() async {
    return DotLottieFlutterPlatform.instance.manifest();
  }
}

// ---------------------------------------------------------------------------
// Desktop (Windows / Linux) — FFI-based controller
// ---------------------------------------------------------------------------

/// A [DotLottieViewController] backed by the dotlottie-rs C FFI on Windows and Linux.
///
/// Obtained via [DotLottieView.onViewCreated] when running on a desktop platform.
/// All methods are synchronous internally but return futures to match the shared
/// interface.
class DotLottieDesktopViewController extends DotLottieViewController {
  final DotLottieFfiPlayer _ffi;

  DotLottieDesktopViewController._(this._ffi) : super._(-1);

  @override
  Future<bool?> play() async => _ffi.play();

  @override
  Future<bool?> pause() async => _ffi.pause();

  @override
  Future<bool?> stop() async => _ffi.stop();

  @override
  Future<bool?> isPlaying() async => _ffi.isPlaying();

  @override
  Future<bool?> isPaused() async => _ffi.isPaused();

  @override
  Future<bool?> isStopped() async => _ffi.isStopped();

  @override
  Future<bool?> isLoaded() async => _ffi.isLoaded();

  @override
  Future<double?> currentFrame() async => _ffi.currentFrame();

  @override
  Future<double?> totalFrames() async => _ffi.totalFrames();

  @override
  Future<double?> duration() async => _ffi.duration();

  @override
  Future<int?> loopCount() async => _ffi.loopCount();

  // Config setters — wired to FFI
  @override
  Future<void> setSpeed(double speed) async => _ffi.setSpeed(speed);
  @override
  Future<void> setLoop(bool loop) async => _ffi.setLoop(loop);
  @override
  Future<void> setMode(String mode) async => _ffi.setMode(mode);
  @override
  Future<void> setFrameInterpolation(bool useFrameInterpolation) async =>
      _ffi.setFrameInterpolation(useFrameInterpolation);

  // Progress — computed from frame position
  @override
  Future<double?> currentProgress() async {
    final total = _ffi.totalFrames();
    return total > 0 ? _ffi.currentFrame() / total : 0.0;
  }

  // Seek
  @override
  Future<bool?> setFrame(double frame) async => _ffi.seekFrame(frame);
  @override
  Future<bool?> setProgress(double progress) async {
    final total = _ffi.totalFrames();
    if (total <= 0) return false;
    return _ffi.seekFrame(progress.clamp(0.0, 1.0) * total);
  }

  // Manifest
  @override
  Future<Map<String, dynamic>?> manifest() async {
    final json = _ffi.getManifest();
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>?;
  }

  // Getters with no C API equivalent — return null silently
  @override Future<double?> speed() async => null;
  @override Future<bool?> loop() async => null;
  @override Future<bool?> autoplay() async => null;
  @override Future<bool?> useFrameInterpolation() async => null;
  @override Future<String?> mode() async => null;

  // Segments
  @override Future<List<double>?> segments() async => _ffi.getSegment();
  @override Future<void> setSegments(double start, double end) async =>
      _ffi.setSegment(start, end);

  // Markers
  @override Future<void> setMarker(String marker) async =>
      _ffi.setMarker(marker);
  @override Future<List<Map<String, dynamic>>?> markers() async =>
      _ffi.getMarkers();

  // Multi-animation
  @override Future<void> loadAnimation(String animationId) async =>
      _ffi.loadAnimation(animationId);
  @override Future<String?> activeAnimationId() async =>
      _ffi.getAnimationId();

  // Themes
  @override Future<bool?> setTheme(String themeId) async =>
      _ffi.setTheme(themeId);
  @override Future<bool?> setThemeData(String themeData) async =>
      _ffi.setThemeData(themeData);
  @override Future<bool?> resetTheme() async => _ffi.resetTheme();
  @override Future<String?> activeThemeId() async => _ffi.activeThemeId();

  @override Future<void> resize(int width, int height) async {}
  @override Future<bool?> setSlots(String slots) async => false;

  @override
  Future<void> setLayout(
    BoxFit fit, {
    Alignment alignment = Alignment.center,
  }) async =>
      _ffi.setLayout(
        _boxFitToFitString(fit) ?? 'contain',
        (alignment.x + 1) / 2,
        (alignment.y + 1) / 2,
      );

  // State machine — not in the C API yet
  @override Future<bool?> stateMachineLoad(String stateMachineId) async => false;
  @override Future<bool?> stateMachineStart() async => false;
  @override Future<bool?> stateMachineStop() async => false;
  @override Future<void> stateMachineFire(String event) async {}
  @override Future<bool?> stateMachineSetNumericInput(String key, double value) async => false;
  @override Future<bool?> stateMachineSetStringInput(String key, String value) async => false;
  @override Future<bool?> stateMachineSetBooleanInput(String key, bool value) async => false;
  @override Future<double?> stateMachineGetNumericInput(String key) async => null;
  @override Future<String?> stateMachineGetStringInput(String key) async => null;
  @override Future<bool?> stateMachineGetBooleanInput(String key) async => null;
  @override Future<Map<String, String>?> stateMachineGetInputs() async => null;
  @override Future<String?> stateMachineCurrentState() async => null;
  @override Future<String?> getStateMachine(String id) async => null;

  @override
  Future<void> dispose() async => _ffi.dispose();
}

// ---------------------------------------------------------------------------
// Desktop widget
// ---------------------------------------------------------------------------

class _DotLottieDesktopWidget extends StatefulWidget {
  final String sourceType;
  final String source;
  final bool autoplay;
  final bool loop;
  final int loopCount;
  final double speed;
  final String mode;
  final bool useFrameInterpolation;
  final double logicalWidth;
  final double logicalHeight;
  final double devicePixelRatio;
  final Function(DotLottieViewController)? onViewCreated;
  final VoidCallback? onLoad;
  final VoidCallback? onLoadError;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final VoidCallback? onComplete;
  final Function(double frameNo)? onFrame;
  final Function(double frameNo)? onRender;
  final Function(int loopCount)? onLoop;

  const _DotLottieDesktopWidget({
    required this.sourceType,
    required this.source,
    required this.autoplay,
    required this.loop,
    required this.loopCount,
    required this.speed,
    required this.mode,
    required this.useFrameInterpolation,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.devicePixelRatio,
    this.onViewCreated,
    this.onLoad,
    this.onLoadError,
    this.onPlay,
    this.onPause,
    this.onStop,
    this.onComplete,
    this.onFrame,
    this.onRender,
    this.onLoop,
  });

  @override
  State<_DotLottieDesktopWidget> createState() =>
      _DotLottieDesktopWidgetState();
}

class _DotLottieDesktopWidgetState extends State<_DotLottieDesktopWidget>
    with SingleTickerProviderStateMixin {
  late final DotLottieFfiPlayer _ffi;
  late final Ticker _ticker;
  ui.Image? _currentImage;
  bool _decodePending = false;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _ffi = DotLottieFfiPlayer();
    _ffi.configure(
      loop: widget.loop,
      speed: widget.speed,
      autoplay: widget.autoplay,
      loopCount: widget.loopCount,
      mode: widget.mode,
      useFrameInterpolation: widget.useFrameInterpolation,
    );
    _applySize();
    _ticker = createTicker(_onTick);
    _loadAndStart();
  }

  @override
  void didUpdateWidget(_DotLottieDesktopWidget old) {
    super.didUpdateWidget(old);
    final sizeChanged = widget.logicalWidth != old.logicalWidth ||
        widget.logicalHeight != old.logicalHeight ||
        widget.devicePixelRatio != old.devicePixelRatio;
    if (sizeChanged) {
      _applySize();
      _ffi.render();
    }
    if (widget.source != old.source || widget.sourceType != old.sourceType) {
      _loadAnimation();
    }
  }

  void _applySize() {
    final w = (widget.logicalWidth * widget.devicePixelRatio).round().clamp(1, 16384);
    final h = (widget.logicalHeight * widget.devicePixelRatio).round().clamp(1, 16384);
    _ffi.setSize(w, h);
  }

  Future<void> _loadAndStart() async {
    await _loadAnimation();
    if (widget.onViewCreated != null) {
      widget.onViewCreated!(DotLottieDesktopViewController._(_ffi));
    }
    if (mounted) _ticker.start();
  }

  Future<void> _loadAnimation() async {
    switch (widget.sourceType) {
      case 'json':
        _ffi.loadJson(widget.source);
      case 'url':
        try {
          await _ffi.loadUrl(widget.source);
        } catch (e) {
          debugPrint('dotlottie: failed to download ${widget.source}: $e');
        }
      case 'asset':
        try {
          final data = await rootBundle.load('assets/${widget.source}');
          final bytes = data.buffer.asUint8List();
          if (widget.source.toLowerCase().endsWith('.json')) {
            _ffi.loadJson(utf8.decode(bytes));
          } else {
            _ffi.loadBytes(bytes);
          }
        } catch (e) {
          debugPrint('dotlottie: failed to load asset ${widget.source}: $e');
        }
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == null
        ? 0.0
        : (elapsed - _lastElapsed!).inMicroseconds / 1000.0;
    _lastElapsed = elapsed;

    final rendered = _ffi.tick(dt);
    if (rendered && !_decodePending) {
      _decodeAndUpdate();
    }

    _ffi.pollEvents(
      onLoad: widget.onLoad,
      onLoadError: widget.onLoadError,
      onPlay: widget.onPlay,
      onPause: widget.onPause,
      onStop: widget.onStop,
      onComplete: widget.onComplete,
      onFrame: widget.onFrame,
      onRender: widget.onRender,
      onLoop: widget.onLoop,
    );
  }

  Future<void> _decodeAndUpdate() async {
    _decodePending = true;
    try {
      final pixelView = _ffi.getRawPixels();
      if (pixelView == null) return;
      // Copy before any await — the FFI buffer can be overwritten by the next tick.
      final pixelCopy = Uint8List.fromList(pixelView);
      final w = _ffi.width;
      final h = _ffi.height;

      final buffer = await ui.ImmutableBuffer.fromUint8List(pixelCopy);
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: w,
        height: h,
        // ARGB8888 on LE = [B,G,R,A] in memory = Flutter's bgra8888.
        pixelFormat: ui.PixelFormat.bgra8888,
      );
      final codec = await descriptor.instantiateCodec(
        targetWidth: w,
        targetHeight: h,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();

      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _currentImage?.dispose();
        _currentImage = frame.image;
      });
    } catch (e) {
      debugPrint('dotlottie: frame decode error: $e');
    } finally {
      _decodePending = false;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ffi.dispose();
    _currentImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnimationPainter(_currentImage),
      size: Size(widget.logicalWidth, widget.logicalHeight),
    );
  }
}

class _AnimationPainter extends CustomPainter {
  final ui.Image? image;

  _AnimationPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    final src = Rect.fromLTWH(
        0, 0, image!.width.toDouble(), image!.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image!, src, dst, Paint());
  }

  @override
  bool shouldRepaint(_AnimationPainter old) => old.image != image;
}
