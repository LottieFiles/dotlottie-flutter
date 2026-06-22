import 'dart:typed_data';

/// No-op stub for web and unsupported platforms.
/// Never instantiated — guarded by platform checks before the widget is built.
class DotLottieFfiPlayer {
  DotLottieFfiPlayer() {
    throw UnsupportedError('DotLottieFfiPlayer is not available on this platform');
  }

  bool get isDisposed => true;
  int get width => 0;
  int get height => 0;

  void configure({
    bool loop = false,
    double speed = 1.0,
    bool autoplay = false,
    int loopCount = 0,
    String mode = 'forward',
    bool useFrameInterpolation = false,
  }) {}

  void setSize(int width, int height) {}
  void loadJson(String json) {}
  void loadBytes(Uint8List bytes) {}
  Future<void> loadUrl(String url) async {}

  bool play() => false;
  bool pause() => false;
  bool stop() => false;

  void setSpeed(double speed) {}
  void setLoop(bool loop) {}
  void setMode(String mode) {}
  void setFrameInterpolation(bool use) {}
  void setLayout(String fit, double alignX, double alignY) {}
  bool seekFrame(double frame) => false;
  bool isPlaying() => false;
  bool isPaused() => false;
  bool isStopped() => true;
  bool isLoaded() => false;
  double currentFrame() => 0;
  double totalFrames() => 0;
  double duration() => 0;
  int loopCount() => 0;
  bool tick(double dtMs) => false;
  void render() {}
  Uint8List? getRawPixels() => null;

  void pollEvents({
    void Function()? onLoad,
    void Function()? onLoadError,
    void Function()? onPlay,
    void Function()? onPause,
    void Function()? onStop,
    void Function()? onComplete,
    void Function(double frameNo)? onFrame,
    void Function(double frameNo)? onRender,
    void Function(int loopCount)? onLoop,
  }) {}

  bool setTheme(String themeId) => false;
  bool setThemeData(String themeData) => false;
  bool resetTheme() => false;
  String? activeThemeId() => null;

  bool setMarker(String marker) => false;
  String? activeMarker() => null;
  List<Map<String, dynamic>> getMarkers() => [];

  bool setSegment(double start, double end) => false;
  void clearSegment() {}
  List<double>? getSegment() => null;

  bool loadAnimation(String animationId) => false;
  String? getAnimationId() => null;
  String? getManifest() => null;

  // State machine
  bool get stateMachineActive => false;
  bool loadStateMachine(String stateMachineId) => false;
  bool loadStateMachineData(String data) => false;
  bool startStateMachine() => false;
  bool stopStateMachine() => false;
  void releaseStateMachine() {}
  bool stateMachineTick(double dtMs) => false;
  void postPointerDown(double x, double y) {}
  void postPointerUp(double x, double y) {}
  void postPointerMove(double x, double y) {}
  void postPointerEnter(double x, double y) {}
  void postPointerExit(double x, double y) {}
  void postClick(double x, double y) {}
  bool fireEvent(String event) => false;
  bool setNumericInput(String key, double value) => false;
  bool setStringInput(String key, String value) => false;
  bool setBooleanInput(String key, bool value) => false;
  double? getNumericInput(String key) => null;
  String? getStringInput(String key) => null;
  bool? getBooleanInput(String key) => null;
  String? currentState() => null;
  String? getStateMachine(String id) => null;
  int frameworkSetup() => 0;
  void pollStateMachineEvents({
    void Function()? onStart,
    void Function()? onStop,
    void Function(String previousState, String newState)? onTransition,
    void Function(String enteringState)? onStateEntered,
    void Function(String leavingState)? onStateExit,
    void Function(String message)? onCustomEvent,
    void Function(String message)? onError,
    void Function(String name, String oldValue, String newValue)?
        onStringInputValueChange,
    void Function(String name, double oldValue, double newValue)?
        onNumericInputValueChange,
    void Function(String name, bool oldValue, bool newValue)?
        onBooleanInputValueChange,
    void Function(String name)? onInputFired,
  }) {}

  void dispose() {}
}
