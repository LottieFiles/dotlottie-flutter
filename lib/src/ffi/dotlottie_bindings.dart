import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Library loading (lazy — only opens the binary when first accessed)
// ---------------------------------------------------------------------------

final DynamicLibrary _lib = _openLibrary();

DynamicLibrary _openLibrary() {
  if (Platform.isWindows) return DynamicLibrary.open('dotlottie_player.dll');
  if (Platform.isLinux) return DynamicLibrary.open('libdotlottie_rs.so');
  throw UnsupportedError(
    'dotlottie FFI player is not supported on ${Platform.operatingSystem}',
  );
}

// ---------------------------------------------------------------------------
// Opaque player type
// ---------------------------------------------------------------------------

final class DotLottiePlayer extends Opaque {}

// ---------------------------------------------------------------------------
// Constants (C enums map to int in Dart FFI)
// ---------------------------------------------------------------------------

// dotlottieColorSpace
const int kColorSpaceABGR8888 = 0;
const int kColorSpaceARGB8888 = 2;

// dotlottieMode
const int kModeForward = 0;
const int kModeReverse = 1;
const int kModeBounce = 2;
const int kModeReverseBounce = 3;

// dotlottiePlaybackStatus
const int kStatusPlaying = 0;
const int kStatusPaused = 1;
const int kStatusStopped = 2;

// dotlottieDotLottieResult
const int kResultSuccess = 0;

// dotlottieDotLottiePlayerEventType
const int kEventLoad = 0;
const int kEventLoadError = 1;
const int kEventPlay = 2;
const int kEventPause = 3;
const int kEventStop = 4;
const int kEventFrame = 5;
const int kEventRender = 6;
const int kEventLoop = 7;
const int kEventComplete = 8;

// ---------------------------------------------------------------------------
// Event struct
// ---------------------------------------------------------------------------

final class DotLottiePlayerEventData extends Union {
  @Float()
  external double frameNo;
  @Uint32()
  external int loopCount;
}

final class DotLottiePlayerEvent extends Struct {
  @Int32()
  external int eventType;
  external DotLottiePlayerEventData data;
}

// ---------------------------------------------------------------------------
// Function bindings (all lazy via late)
// ---------------------------------------------------------------------------

// Lifecycle
final dotlottieNewPlayer =
    _lib.lookupFunction<Pointer<DotLottiePlayer> Function(Uint32),
        Pointer<DotLottiePlayer> Function(int)>('dotlottie_new_player');

final dotlottieDestroy =
    _lib.lookupFunction<Int32 Function(Pointer<DotLottiePlayer>),
        int Function(Pointer<DotLottiePlayer>)>('dotlottie_destroy');

// Loading
final dotlottieLoadAnimationData = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Utf8>),
    int Function(
        Pointer<DotLottiePlayer>, Pointer<Utf8>)>('dotlottie_load_animation_data');

final dotlottieLoadDotlottieData = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Uint8>, UintPtr),
    int Function(Pointer<DotLottiePlayer>, Pointer<Uint8>,
        int)>('dotlottie_load_dotlottie_data');

// Render target + viewport
final dotlottieSetSwTarget = _lib.lookupFunction<
    Int32 Function(
        Pointer<DotLottiePlayer>, Pointer<Uint32>, Uint32, Uint32, Int32),
    int Function(Pointer<DotLottiePlayer>, Pointer<Uint32>, int, int,
        int)>('dotlottie_set_sw_target');

final dotlottieSetViewport = _lib.lookupFunction<
    Int32 Function(
        Pointer<DotLottiePlayer>, Int32, Int32, Int32, Int32),
    int Function(
        Pointer<DotLottiePlayer>, int, int, int, int)>('dotlottie_set_viewport');

// Tick and render
final dotlottieTick = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Float, Pointer<Bool>),
    int Function(Pointer<DotLottiePlayer>, double,
        Pointer<Bool>)>('dotlottie_tick');

final dotlottieRender =
    _lib.lookupFunction<Int32 Function(Pointer<DotLottiePlayer>),
        int Function(Pointer<DotLottiePlayer>)>('dotlottie_render');

// Playback control
final dotlottiePlay =
    _lib.lookupFunction<Int32 Function(Pointer<DotLottiePlayer>),
        int Function(Pointer<DotLottiePlayer>)>('dotlottie_play');

final dotlottiePause =
    _lib.lookupFunction<Int32 Function(Pointer<DotLottiePlayer>),
        int Function(Pointer<DotLottiePlayer>)>('dotlottie_pause');

final dotlottieStop =
    _lib.lookupFunction<Int32 Function(Pointer<DotLottiePlayer>),
        int Function(Pointer<DotLottiePlayer>)>('dotlottie_stop');

// Status queries
final dotlottieGetPlaybackStatus =
    _lib.lookupFunction<Int32 Function(Pointer<DotLottiePlayer>),
        int Function(Pointer<DotLottiePlayer>)>('dotlottie_get_playback_status');

final dotlottieIsLoaded =
    _lib.lookupFunction<Bool Function(Pointer<DotLottiePlayer>),
        bool Function(Pointer<DotLottiePlayer>)>('dotlottie_is_loaded');

final dotlottieGetCurrentFrame = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Float>),
    int Function(Pointer<DotLottiePlayer>,
        Pointer<Float>)>('dotlottie_get_current_frame');

final dotlottieGetTotalFrames = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Float>),
    int Function(Pointer<DotLottiePlayer>,
        Pointer<Float>)>('dotlottie_get_total_frames');

final dotlottieGetDuration = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Float>),
    int Function(Pointer<DotLottiePlayer>,
        Pointer<Float>)>('dotlottie_get_duration');

final dotlottieGetCurrentLoopCount = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Uint32>),
    int Function(Pointer<DotLottiePlayer>,
        Pointer<Uint32>)>('dotlottie_get_current_loop_count');

// Config setters
final dotlottieSetLoop = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Bool),
    int Function(Pointer<DotLottiePlayer>, bool)>('dotlottie_set_loop');

final dotlottieSetSpeed = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Float),
    int Function(Pointer<DotLottiePlayer>, double)>('dotlottie_set_speed');

final dotlottieSetAutoplay = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Bool),
    int Function(Pointer<DotLottiePlayer>, bool)>('dotlottie_set_autoplay');

final dotlottieSetLoopCount = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Uint32),
    int Function(Pointer<DotLottiePlayer>, int)>('dotlottie_set_loop_count');

final dotlottieSetMode = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Int32),
    int Function(Pointer<DotLottiePlayer>, int)>('dotlottie_set_mode');

final dotlottieSetUseFrameInterpolation = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Bool),
    int Function(Pointer<DotLottiePlayer>,
        bool)>('dotlottie_set_use_frame_interpolation');

// Event polling
final dotlottiePollEvent = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<DotLottiePlayerEvent>),
    int Function(Pointer<DotLottiePlayer>,
        Pointer<DotLottiePlayerEvent>)>('dotlottie_poll_event');
