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
  // Pre-allocated state machine event struct — reused every tick.
  late final Pointer<DotLottieStateMachineEvent> _smEventPtr;
  // Pre-allocated scratch for scalar results.
  late final Pointer<Float> _floatOut;
  late final Pointer<Uint32> _uint32Out;
  late final Pointer<Uint16> _uint16Out;
  late final Pointer<Bool> _boolOut;
  late final Pointer<UintPtr> _sizeOut;

  // Non-null only while a state machine is loaded. The state machine borrows the
  // player, so it must be stopped + released before the player is destroyed.
  Pointer<DotLottieStateMachine>? _sm;

  int _width = 0;
  int _height = 0;
  bool _disposed = false;
  bool _seekPending = false;

  DotLottieFfiPlayer() {
    _ptr = dotlottieNewPlayer(1);
    if (_ptr == nullptr) throw StateError('dotlottie_new_player returned null');
    _eventPtr = malloc<DotLottiePlayerEvent>();
    _smEventPtr = malloc<DotLottieStateMachineEvent>();
    _floatOut = malloc<Float>();
    _uint32Out = malloc<Uint32>();
    _uint16Out = malloc<Uint16>();
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
  // State machine
  // ---------------------------------------------------------------------------

  /// True while a state machine is loaded. Pointer events and the state machine
  /// tick are only valid in this state.
  bool get stateMachineActive => _sm != null && _sm != nullptr;

  bool loadStateMachine(String stateMachineId) {
    releaseStateMachine();
    final ptr = stateMachineId.toNativeUtf8();
    try {
      final sm = dotlottieStateMachineLoad(_ptr, ptr);
      if (sm == nullptr) return false;
      _sm = sm;
      return true;
    } finally {
      malloc.free(ptr);
    }
  }

  bool loadStateMachineData(String data) {
    releaseStateMachine();
    final ptr = data.toNativeUtf8();
    try {
      final sm = dotlottieStateMachineLoadData(_ptr, ptr);
      if (sm == nullptr) return false;
      _sm = sm;
      return true;
    } finally {
      malloc.free(ptr);
    }
  }

  bool startStateMachine() {
    if (!stateMachineActive) return false;
    return dotlottieStateMachineStart(_sm!, nullptr.cast<Utf8>(), false) ==
        kResultSuccess;
  }

  bool stopStateMachine() {
    if (!stateMachineActive) return false;
    return dotlottieStateMachineStop(_sm!) == kResultSuccess;
  }

  /// Stops and destroys the state machine, releasing the player borrow.
  void releaseStateMachine() {
    if (!stateMachineActive) return;
    dotlottieStateMachineStop(_sm!);
    dotlottieStateMachineRelease(_sm!);
    _sm = null;
  }

  /// Advances the state machine by [dtMs] milliseconds (also renders).
  /// Returns true if a new frame was rendered into the pixel buffer.
  bool stateMachineTick(double dtMs) {
    if (!stateMachineActive) return false;
    if (_pixelBuffer == null || _width == 0 || _height == 0) return false;
    dotlottieStateMachineTick(_sm!, dtMs, _boolOut);
    return _boolOut.value;
  }

  void postPointerDown(double x, double y) {
    if (stateMachineActive) dotlottieStateMachinePostPointerDown(_sm!, x, y);
  }

  void postPointerUp(double x, double y) {
    if (stateMachineActive) dotlottieStateMachinePostPointerUp(_sm!, x, y);
  }

  void postPointerMove(double x, double y) {
    if (stateMachineActive) dotlottieStateMachinePostPointerMove(_sm!, x, y);
  }

  void postPointerEnter(double x, double y) {
    if (stateMachineActive) dotlottieStateMachinePostPointerEnter(_sm!, x, y);
  }

  void postPointerExit(double x, double y) {
    if (stateMachineActive) dotlottieStateMachinePostPointerExit(_sm!, x, y);
  }

  void postClick(double x, double y) {
    if (stateMachineActive) dotlottieStateMachinePostClick(_sm!, x, y);
  }

  bool fireEvent(String event) {
    if (!stateMachineActive) return false;
    final ptr = event.toNativeUtf8();
    try {
      return dotlottieStateMachineFireEvent(_sm!, ptr) == kResultSuccess;
    } finally {
      malloc.free(ptr);
    }
  }

  bool setNumericInput(String key, double value) {
    if (!stateMachineActive) return false;
    final ptr = key.toNativeUtf8();
    try {
      return dotlottieStateMachineSetNumericInput(_sm!, ptr, value) ==
          kResultSuccess;
    } finally {
      malloc.free(ptr);
    }
  }

  bool setStringInput(String key, String value) {
    if (!stateMachineActive) return false;
    final keyPtr = key.toNativeUtf8();
    final valPtr = value.toNativeUtf8();
    try {
      return dotlottieStateMachineSetStringInput(_sm!, keyPtr, valPtr) ==
          kResultSuccess;
    } finally {
      malloc.free(keyPtr);
      malloc.free(valPtr);
    }
  }

  bool setBooleanInput(String key, bool value) {
    if (!stateMachineActive) return false;
    final ptr = key.toNativeUtf8();
    try {
      return dotlottieStateMachineSetBooleanInput(_sm!, ptr, value) ==
          kResultSuccess;
    } finally {
      malloc.free(ptr);
    }
  }

  double? getNumericInput(String key) {
    if (!stateMachineActive) return null;
    final ptr = key.toNativeUtf8();
    try {
      if (dotlottieStateMachineGetNumericInput(_sm!, ptr, _floatOut) !=
          kResultSuccess) {
        return null;
      }
      return _floatOut.value;
    } finally {
      malloc.free(ptr);
    }
  }

  String? getStringInput(String key) {
    if (!stateMachineActive) return null;
    final keyPtr = key.toNativeUtf8();
    try {
      return _readNativeString(
        (buf, sizeOut) =>
            dotlottieStateMachineGetStringInput(_sm!, keyPtr, buf, sizeOut),
      );
    } finally {
      malloc.free(keyPtr);
    }
  }

  bool? getBooleanInput(String key) {
    if (!stateMachineActive) return null;
    final ptr = key.toNativeUtf8();
    try {
      if (dotlottieStateMachineGetBooleanInput(_sm!, ptr, _boolOut) !=
          kResultSuccess) {
        return null;
      }
      return _boolOut.value;
    } finally {
      malloc.free(ptr);
    }
  }

  String? currentState() {
    if (!stateMachineActive) return null;
    return _readNativeString(
      (buf, sizeOut) =>
          dotlottieStateMachineGetCurrentState(_sm!, buf, sizeOut),
    );
  }

  String? getStateMachine(String id) {
    final idPtr = id.toNativeUtf8();
    try {
      return _readNativeString(
        (buf, sizeOut) => dotlottieGetStateMachine(_ptr, idPtr, buf, sizeOut),
      );
    } finally {
      malloc.free(idPtr);
    }
  }

  /// Returns the InteractionType bit flags (kInteraction*) declaring which
  /// pointer listeners the loaded state machine needs, or 0 if unavailable.
  int frameworkSetup() {
    if (!stateMachineActive) return 0;
    if (dotlottieStateMachineGetFrameworkSetup(_sm!, _uint16Out) !=
        kResultSuccess) {
      return 0;
    }
    return _uint16Out.value;
  }

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
  }) {
    if (!stateMachineActive) return;
    // String pointers in the event are only valid until the next poll call, so
    // each branch reads them immediately.
    while (dotlottieStateMachinePollEvent(_sm!, _smEventPtr) == 1) {
      final e = _smEventPtr.ref;
      switch (e.eventType) {
        case kSmEventStart:
          onStart?.call();
        case kSmEventStop:
          onStop?.call();
        case kSmEventTransition:
          onTransition?.call(
            e.data.transition.previousState.toDartString(),
            e.data.transition.newState.toDartString(),
          );
        case kSmEventStateEntered:
          onStateEntered?.call(e.data.state.state.toDartString());
        case kSmEventStateExit:
          onStateExit?.call(e.data.state.state.toDartString());
        case kSmEventCustomEvent:
          onCustomEvent?.call(e.data.message.message.toDartString());
        case kSmEventError:
          onError?.call(e.data.message.message.toDartString());
        case kSmEventStringInputChange:
          onStringInputValueChange?.call(
            e.data.stringInput.name.toDartString(),
            e.data.stringInput.oldValue.toDartString(),
            e.data.stringInput.newValue.toDartString(),
          );
        case kSmEventNumericInputChange:
          onNumericInputValueChange?.call(
            e.data.numericInput.name.toDartString(),
            e.data.numericInput.oldValue,
            e.data.numericInput.newValue,
          );
        case kSmEventBooleanInputChange:
          onBooleanInputValueChange?.call(
            e.data.booleanInput.name.toDartString(),
            e.data.booleanInput.oldValue,
            e.data.booleanInput.newValue,
          );
        case kSmEventInputFired:
          onInputFired?.call(e.data.inputFired.name.toDartString());
      }
    }
  }

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
    // The state machine borrows the player — release it before destroying.
    releaseStateMachine();
    if (_pixelBuffer != null) {
      malloc.free(_pixelBuffer!);
      _pixelBuffer = null;
    }
    malloc.free(_eventPtr);
    malloc.free(_smEventPtr);
    malloc.free(_floatOut);
    malloc.free(_uint32Out);
    malloc.free(_uint16Out);
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
