import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../ffi/dotlottie_bindings.dart';

class DotLottieFfiPlayer {
  late final Pointer<DotLottiePlayer> _ptr;
  Pointer<Uint32>? _pixelBuffer;
  // Pre-allocated event struct — reused every tick to avoid per-frame malloc.
  late final Pointer<DotLottiePlayerEvent> _eventPtr;
  // Pre-allocated scratch for scalar results.
  late final Pointer<Float> _floatOut;
  late final Pointer<Uint32> _uint32Out;
  late final Pointer<Bool> _boolOut;
  late final Pointer<UintPtr> _sizeOut;

  int _width = 0;
  int _height = 0;
  bool _disposed = false;
  bool _seekPending = false;

  DotLottieFfiPlayer() {
    _ptr = dotlottieNewPlayer(1);
    if (_ptr == nullptr) throw StateError('dotlottie_new_player returned null');
    _eventPtr = malloc<DotLottiePlayerEvent>();
    _floatOut = malloc<Float>();
    _uint32Out = malloc<Uint32>();
    _boolOut = malloc<Bool>();
    _sizeOut = malloc<UintPtr>();
  }

  bool get isDisposed => _disposed;

  void configure({
    bool loop = false,
    double speed = 1.0,
    bool autoplay = false,
    int loopCount = 0,
    String mode = 'forward',
    bool useFrameInterpolation = false,
  }) {
    dotlottieSetLoop(_ptr, loop);
    dotlottieSetSpeed(_ptr, speed);
    dotlottieSetAutoplay(_ptr, autoplay);
    dotlottieSetLoopCount(_ptr, loopCount);
    dotlottieSetMode(_ptr, _modeFromString(mode));
    dotlottieSetUseFrameInterpolation(_ptr, useFrameInterpolation);
  }

  void setSize(int width, int height) {
    if (width == _width && height == _height) return;
    if (_pixelBuffer != null) malloc.free(_pixelBuffer!);
    _pixelBuffer = malloc<Uint32>(width * height);
    _width = width;
    _height = height;
    // ARGB8888 on little-endian x86/x64 is [B,G,R,A] in memory = bgra8888 in Flutter.
    dotlottieSetSwTarget(_ptr, _pixelBuffer!, width, height, kColorSpaceARGB8888);
    dotlottieSetViewport(_ptr, 0, 0, width, height);
  }

  void loadJson(String json) {
    final ptr = json.toNativeUtf8();
    try {
      dotlottieLoadAnimationData(_ptr, ptr);
    } finally {
      malloc.free(ptr);
    }
  }

  void loadBytes(Uint8List bytes) {
    final ptr = malloc<Uint8>(bytes.length);
    try {
      ptr.asTypedList(bytes.length).setAll(0, bytes);
      dotlottieLoadDotlottieData(_ptr, ptr, bytes.length);
    } finally {
      malloc.free(ptr);
    }
  }

  Future<void> loadUrl(String url) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final builder = BytesBuilder();
      await response.forEach(builder.add);
      final bytes = builder.takeBytes();
      if (url.toLowerCase().endsWith('.json')) {
        loadJson(String.fromCharCodes(bytes));
      } else {
        loadBytes(bytes);
      }
    } finally {
      client.close();
    }
  }

  bool play() => dotlottiePlay(_ptr) == kResultSuccess;
  bool pause() => dotlottiePause(_ptr) == kResultSuccess;
  bool stop() => dotlottieStop(_ptr) == kResultSuccess;

  void setSpeed(double speed) => dotlottieSetSpeed(_ptr, speed);
  void setLoop(bool loop) => dotlottieSetLoop(_ptr, loop);
  void setMode(String mode) => dotlottieSetMode(_ptr, _modeFromString(mode));
  void setFrameInterpolation(bool use) =>
      dotlottieSetUseFrameInterpolation(_ptr, use);

  bool isPlaying() => dotlottieGetPlaybackStatus(_ptr) == kStatusPlaying;
  bool isPaused() => dotlottieGetPlaybackStatus(_ptr) == kStatusPaused;
  bool isStopped() => dotlottieGetPlaybackStatus(_ptr) == kStatusStopped;
  bool isLoaded() => dotlottieIsLoaded(_ptr);

  double currentFrame() {
    dotlottieGetCurrentFrame(_ptr, _floatOut);
    return _floatOut.value;
  }

  double totalFrames() {
    dotlottieGetTotalFrames(_ptr, _floatOut);
    return _floatOut.value;
  }

  double duration() {
    dotlottieGetDuration(_ptr, _floatOut);
    return _floatOut.value;
  }

  int loopCount() {
    dotlottieGetCurrentLoopCount(_ptr, _uint32Out);
    return _uint32Out.value;
  }

  /// Seeks to [frame] and renders it into the pixel buffer.
  bool seekFrame(double frame) {
    final result = dotlottieSetFrame(_ptr, frame) == kResultSuccess;
    if (result) {
      dotlottieRender(_ptr);
      _seekPending = true;
    }
    return result;
  }

  /// Advances the animation by [dtMs] milliseconds.
  /// Returns true if a new frame was rendered into the pixel buffer.
  bool tick(double dtMs) {
    if (_pixelBuffer == null || _width == 0 || _height == 0) return false;
    dotlottieTick(_ptr, dtMs, _boolOut);
    if (_boolOut.value || _seekPending) {
      _seekPending = false;
      return true;
    }
    return false;
  }

  void render() => dotlottieRender(_ptr);

  /// Returns a Uint8List VIEW into the native pixel buffer (no copy).
  /// Valid only until the next [tick], [setSize], or [dispose] call.
  Uint8List? getRawPixels() {
    if (_pixelBuffer == null || _width == 0 || _height == 0) return null;
    return _pixelBuffer!
        .asTypedList(_width * _height)
        .buffer
        .asUint8List();
  }

  int get width => _width;
  int get height => _height;

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
  }) {
    while (dotlottiePollEvent(_ptr, _eventPtr) == 1) {
      final e = _eventPtr.ref;
      switch (e.eventType) {
        case kEventLoad:      onLoad?.call();
        case kEventLoadError: onLoadError?.call();
        case kEventPlay:      onPlay?.call();
        case kEventPause:     onPause?.call();
        case kEventStop:      onStop?.call();
        case kEventComplete:  onComplete?.call();
        case kEventFrame:     onFrame?.call(e.data.frameNo);
        case kEventRender:    onRender?.call(e.data.frameNo);
        case kEventLoop:      onLoop?.call(e.data.loopCount);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Themes
  // ---------------------------------------------------------------------------

  bool setTheme(String themeId) {
    final ptr = themeId.toNativeUtf8();
    try {
      return dotlottieSetTheme(_ptr, ptr) == kResultSuccess;
    } finally {
      malloc.free(ptr);
    }
  }

  bool setThemeData(String themeData) {
    final ptr = themeData.toNativeUtf8();
    try {
      return dotlottieSetThemeData(_ptr, ptr) == kResultSuccess;
    } finally {
      malloc.free(ptr);
    }
  }

  bool resetTheme() => dotlottieResetTheme(_ptr) == kResultSuccess;

  String? activeThemeId() => _readNativeString(
        (buf, sizeOut) => dotlottieGetThemeId(_ptr, buf, sizeOut),
      );

  // ---------------------------------------------------------------------------
  // Markers
  // ---------------------------------------------------------------------------

  bool setMarker(String marker) {
    final ptr = marker.toNativeUtf8();
    try {
      return dotlottieSetMarker(_ptr, ptr) == kResultSuccess;
    } finally {
      malloc.free(ptr);
    }
  }

  String? activeMarker() => _readNativeString(
        (buf, sizeOut) => dotlottieGetActiveMarker(_ptr, buf, sizeOut),
      );

  List<Map<String, dynamic>> getMarkers() {
    if (dotlottieGetMarkersCount(_ptr, _uint32Out) != kResultSuccess) {
      return [];
    }
    final count = _uint32Out.value;
    if (count == 0) return [];

    final namePtr = malloc<Pointer<Utf8>>();
    final startPtr = malloc<Float>();
    final endPtr = malloc<Float>();
    try {
      final markers = <Map<String, dynamic>>[];
      for (int i = 0; i < count; i++) {
        if (dotlottieGetMarker(_ptr, i, namePtr, startPtr, endPtr) ==
            kResultSuccess) {
          markers.add({
            'name': namePtr.value.toDartString(),
            'start': startPtr.value,
            'end': endPtr.value,
          });
        }
      }
      return markers;
    } finally {
      malloc.free(namePtr);
      malloc.free(startPtr);
      malloc.free(endPtr);
    }
  }

  // ---------------------------------------------------------------------------
  // Segments
  // ---------------------------------------------------------------------------

  bool setSegment(double start, double end) {
    final seg = malloc<Float>(2);
    try {
      seg[0] = start;
      seg[1] = end;
      return dotlottieSetSegment(_ptr, seg) == kResultSuccess;
    } finally {
      malloc.free(seg);
    }
  }

  void clearSegment() => dotlottieSetSegment(_ptr, nullptr.cast<Float>());

  List<double>? getSegment() {
    final seg = malloc<Float>(2);
    try {
      if (dotlottieGetSegment(_ptr, seg) != kResultSuccess) return null;
      return [seg[0], seg[1]];
    } finally {
      malloc.free(seg);
    }
  }

  // ---------------------------------------------------------------------------
  // Multi-animation
  // ---------------------------------------------------------------------------

  bool loadAnimation(String animationId) {
    final ptr = animationId.toNativeUtf8();
    try {
      return dotlottieLoadAnimation(_ptr, ptr) == kResultSuccess;
    } finally {
      malloc.free(ptr);
    }
  }

  String? getAnimationId() => _readNativeString(
        (buf, sizeOut) => dotlottieGetAnimationId(_ptr, buf, sizeOut),
      );

  String? getManifest() => _readNativeString(
        (buf, sizeOut) => dotlottieGetManifest(_ptr, buf, sizeOut),
      );

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Two-pass pattern for C functions that write a string into a caller-allocated buffer.
  /// First call with null buffer to get required size, then allocate and read.
  String? _readNativeString(
      int Function(Pointer<Uint8>, Pointer<UintPtr>) fn) {
    if (fn(nullptr.cast<Uint8>(), _sizeOut) != kResultSuccess) return null;
    final size = _sizeOut.value;
    if (size == 0) return null;
    final buf = malloc<Uint8>(size);
    try {
      if (fn(buf, _sizeOut) != kResultSuccess) return null;
      return buf.cast<Utf8>().toDartString();
    } finally {
      malloc.free(buf);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_pixelBuffer != null) {
      malloc.free(_pixelBuffer!);
      _pixelBuffer = null;
    }
    malloc.free(_eventPtr);
    malloc.free(_floatOut);
    malloc.free(_uint32Out);
    malloc.free(_boolOut);
    malloc.free(_sizeOut);
    dotlottieDestroy(_ptr);
  }

  static int _modeFromString(String mode) => switch (mode) {
    'reverse'       => kModeReverse,
    'bounce'        => kModeBounce,
    'reverseBounce' => kModeReverseBounce,
    _               => kModeForward,
  };
}
