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

  void Function()? onComplete;
  void Function()? onLoad;
  void Function()? onLoadError;
  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onStop;
  void Function(double frameNo)? onFrame;
  void Function(double frameNo)? onRender;
  void Function(int loopCount)? onLoop;

  // Method to set event handlers
  void setEventHandlers({
    void Function()? onComplete,
    void Function()? onLoad,
    void Function()? onLoadError,
    void Function()? onPlay,
    void Function()? onPause,
    void Function()? onStop,
    void Function(double frameNo)? onFrame,
    void Function(double frameNo)? onRender,
    void Function(int loopCount)? onLoop,
  }) {
    this.onComplete = onComplete;
    this.onLoad = onLoad;
    this.onLoadError = onLoadError;
    this.onPlay = onPlay;
    this.onPause = onPause;
    this.onStop = onStop;
    this.onFrame = onFrame;
    this.onRender = onRender;
    this.onLoop = onLoop;
  }

  Future<void> createPlayer() {
    throw UnimplementedError('createPlayer() has not been implemented.');
  }

  // Playback control methods
  Future<bool?> play() {
    throw UnimplementedError('play() has not been implemented.');
  }

  Future<bool?> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  Future<bool?> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  // Animation properties getters
  Future<bool?> isPlaying() {
    throw UnimplementedError('isPlaying() has not been implemented.');
  }

  Future<bool?> isPaused() {
    throw UnimplementedError('isPaused() has not been implemented.');
  }

  Future<bool?> isStopped() {
    throw UnimplementedError('isStopped() has not been implemented.');
  }

  Future<bool?> isLoaded() {
    throw UnimplementedError('isLoaded() has not been implemented.');
  }

  Future<double?> currentFrame() {
    throw UnimplementedError('currentFrame() has not been implemented.');
  }

  Future<double?> totalFrames() {
    throw UnimplementedError('totalFrames() has not been implemented.');
  }

  Future<double?> duration() {
    throw UnimplementedError('duration() has not been implemented.');
  }

  Future<int?> loopCount() {
    throw UnimplementedError('loopCount() has not been implemented.');
  }

  Future<double?> speed() {
    throw UnimplementedError('speed() has not been implemented.');
  }

  Future<bool?> loop() {
    throw UnimplementedError('loop() has not been implemented.');
  }

  Future<bool?> autoplay() {
    throw UnimplementedError('autoplay() has not been implemented.');
  }

  Future<bool?> useFrameInterpolation() {
    throw UnimplementedError(
      'useFrameInterpolation() has not been implemented.',
    );
  }

  Future<List<double>?> segments() {
    throw UnimplementedError('segments() has not been implemented.');
  }

  Future<String?> mode() {
    throw UnimplementedError('mode() has not been implemented.');
  }

  // Animation control setters
  Future<void> setSpeed(double speed) {
    throw UnimplementedError('setSpeed() has not been implemented.');
  }

  Future<void> setLoop(bool loop) {
    throw UnimplementedError('setLoop() has not been implemented.');
  }

  Future<bool?> setFrame(double frame) {
    throw UnimplementedError('setFrame() has not been implemented.');
  }

  Future<bool?> setProgress(double progress) {
    throw UnimplementedError('setProgress() has not been implemented.');
  }

  Future<void> setSegment(double start, double end) {
    throw UnimplementedError('setSegment() has not been implemented.');
  }

  Future<void> setMarker(String marker) {
    throw UnimplementedError('setMarker() has not been implemented.');
  }

  Future<void> setMode(String mode) {
    throw UnimplementedError('setMode() has not been implemented.');
  }

  Future<void> setFrameInterpolation(bool useFrameInterpolation) {
    throw UnimplementedError(
      'setFrameInterpolation() has not been implemented.',
    );
  }

  Future<void> setBackgroundColor(String color) {
    throw UnimplementedError('setBackgroundColor() has not been implemented.');
  }

  // Theme methods
  Future<bool?> setTheme(String themeId) {
    throw UnimplementedError('setTheme() has not been implemented.');
  }

  Future<bool?> setThemeData(String themeData) {
    throw UnimplementedError('setThemeData() has not been implemented.');
  }

  Future<bool?> resetTheme() {
    throw UnimplementedError('resetTheme() has not been implemented.');
  }

  Future<String?> activeThemeId() {
    throw UnimplementedError('activeThemeId() has not been implemented.');
  }

  // Animation loading methods
  Future<void> loadAnimation(String animationId) {
    throw UnimplementedError('loadAnimation() has not been implemented.');
  }

  Future<String?> activeAnimationId() {
    throw UnimplementedError('activeAnimationId() has not been implemented.');
  }

  Future<List<Map<String, dynamic>>?> markers() {
    throw UnimplementedError('markers() has not been implemented.');
  }

  Future<double?> currentProgress() {
    throw UnimplementedError('currentProgress() has not been implemented.');
  }

  Future<bool?> setSlots(String slots) {
    throw UnimplementedError('setSlots() has not been implemented.');
  }

  Future<void> resize(int width, int height) {
    throw UnimplementedError('resize() has not been implemented.');
  }

  // Layer methods
  Future<List<double>?> getLayerBounds(String layerName) {
    throw UnimplementedError('getLayerBounds() has not been implemented.');
  }

  // State machine methods
  Future<bool?> stateMachineLoad(String stateMachineId) {
    throw UnimplementedError('stateMachineLoad() has not been implemented.');
  }

  Future<bool?> stateMachineLoadData(String data) {
    throw UnimplementedError(
      'stateMachineLoadData() has not been implemented.',
    );
  }

  Future<bool?> stateMachineStart() {
    throw UnimplementedError('stateMachineStart() has not been implemented.');
  }

  Future<bool?> stateMachineStop() {
    throw UnimplementedError('stateMachineStop() has not been implemented.');
  }

  Future<void> stateMachineFire(String event) {
    throw UnimplementedError('stateMachineFire() has not been implemented.');
  }

  Future<bool?> stateMachineSetNumericInput(String key, double value) {
    throw UnimplementedError(
      'stateMachineSetNumericInput() has not been implemented.',
    );
  }

  Future<bool?> stateMachineSetStringInput(String key, String value) {
    throw UnimplementedError(
      'stateMachineSetStringInput() has not been implemented.',
    );
  }

  Future<bool?> stateMachineSetBooleanInput(String key, bool value) {
    throw UnimplementedError(
      'stateMachineSetBooleanInput() has not been implemented.',
    );
  }

  Future<double?> stateMachineGetNumericInput(String key) {
    throw UnimplementedError(
      'stateMachineGetNumericInput() has not been implemented.',
    );
  }

  Future<String?> stateMachineGetStringInput(String key) {
    throw UnimplementedError(
      'stateMachineGetStringInput() has not been implemented.',
    );
  }

  Future<bool?> stateMachineGetBooleanInput(String key) {
    throw UnimplementedError(
      'stateMachineGetBooleanInput() has not been implemented.',
    );
  }

  Future<Map<String, String>?> stateMachineGetInputs() {
    throw UnimplementedError(
      'stateMachineGetInputs() has not been implemented.',
    );
  }

  Future<String?> stateMachineCurrentState() {
    throw UnimplementedError(
      'stateMachineCurrentState() has not been implemented.',
    );
  }

  Future<String?> getStateMachine(String id) {
    throw UnimplementedError('getStateMachine() has not been implemented.');
  }

  // Manifest method
  Future<Map<String, dynamic>?> manifest() {
    throw UnimplementedError('manifest() has not been implemented.');
  }
}
