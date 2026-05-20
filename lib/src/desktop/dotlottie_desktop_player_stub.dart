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

  void dispose() {}
}
