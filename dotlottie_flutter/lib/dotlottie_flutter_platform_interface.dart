import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dotlottie_flutter_method_channel.dart';

abstract class DotLottieFlutterPlatform extends PlatformInterface {
  /// Constructs a DotLottieFlutterPlatform.
  DotLottieFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static DotLottieFlutterPlatform _instance = MethodChannelDotLottieFlutter();

  /// The default instance of [DotLottieFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelDotLottieFlutter].
  static DotLottieFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DotLottieFlutterPlatform] when
  /// they register themselves.
  static set instance(DotLottieFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Event handlers - to be set by the main class
  void Function()? onLoad;
  void Function()? onLoadError;
  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onStop;
  void Function()? onComplete;
  void Function()? onLoop;
  void Function(double frame)? onFrame;

  // Method to set event handlers
  void setEventHandlers({
    void Function()? onLoad,
    void Function()? onLoadError,
    void Function()? onPlay,
    void Function()? onPause,
    void Function()? onStop,
    void Function()? onComplete,
    void Function()? onLoop,
    void Function(double frame)? onFrame,
  }) {
    this.onLoad = onLoad;
    this.onLoadError = onLoadError;
    this.onPlay = onPlay;
    this.onPause = onPause;
    this.onStop = onStop;
    this.onComplete = onComplete;
    this.onLoop = onLoop;
    this.onFrame = onFrame;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> createPlayer() {
    throw UnimplementedError('createPlayer() has not been implemented.');
  }

  Future<void> loadAnimation({
    required String sourceType,
    required String source,
    bool autoplay = true,
    bool loop = true,
    double speed = 1.0,
  }) {
    throw UnimplementedError('loadAnimation() has not been implemented.');
  }

  Future<void> play() {
    throw UnimplementedError('play() has not been implemented.');
  }

  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> setSpeed(double speed) {
    throw UnimplementedError('setSpeed() has not been implemented.');
  }

  Future<void> setLoop(bool loop) {
    throw UnimplementedError('setLoop() has not been implemented.');
  }

  Future<double?> getCurrentFrame() {
    throw UnimplementedError('getCurrentFrame() has not been implemented.');
  }

  Future<double?> getTotalFrames() {
    throw UnimplementedError('getTotalFrames() has not been implemented.');
  }

  Future<bool?> isPlaying() {
    throw UnimplementedError('isPlaying() has not been implemented.');
  }

  Future<bool?> isPaused() {
    throw UnimplementedError('isPaused() has not been implemented.');
  }
}
