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

// Opaque state machine handle. Borrows the player; must be released before the
// player is destroyed.
final class DotLottieStateMachine extends Opaque {}

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

// dotlottieFit
const int kFitContain = 0;
const int kFitFill = 1;
const int kFitCover = 2;
const int kFitWidth = 3;
const int kFitHeight = 4;
const int kFitNone = 5;

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

// dotlottieStateMachineEventType
const int kSmEventStart = 0;
const int kSmEventStop = 1;
const int kSmEventTransition = 2;
const int kSmEventStateEntered = 3;
const int kSmEventStateExit = 4;
const int kSmEventCustomEvent = 5;
const int kSmEventError = 6;
const int kSmEventStringInputChange = 7;
const int kSmEventNumericInputChange = 8;
const int kSmEventBooleanInputChange = 9;
const int kSmEventInputFired = 10;

// Interaction bit flags (kInteraction*) returned by
// dotlottie_state_machine_get_framework_setup live in state_machine_interactions.dart
// so they can also be used by the web-safe widget layer.

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

// dotlottieLayout { dotlottieFit fit; float align[2]; }
final class DotLottieLayout extends Struct {
  @Int32()
  external int fit;
  @Array(2)
  external Array<Float> align;
}

// ---------------------------------------------------------------------------
// State machine event struct
//
// All `const char*` string pointers below are only valid until the next
// dotlottie_state_machine_poll_event call — read them immediately.
// ---------------------------------------------------------------------------

final class SmTransitionData extends Struct {
  external Pointer<Utf8> previousState;
  external Pointer<Utf8> newState;
}

final class SmStateData extends Struct {
  external Pointer<Utf8> state;
}

final class SmMessageData extends Struct {
  external Pointer<Utf8> message;
}

final class SmStringInputData extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> oldValue;
  external Pointer<Utf8> newValue;
}

final class SmNumericInputData extends Struct {
  external Pointer<Utf8> name;
  @Float()
  external double oldValue;
  @Float()
  external double newValue;
}

final class SmBooleanInputData extends Struct {
  external Pointer<Utf8> name;
  @Bool()
  external bool oldValue;
  @Bool()
  external bool newValue;
}

final class SmInputFiredData extends Struct {
  external Pointer<Utf8> name;
}

final class DotLottieStateMachineEventData extends Union {
  external SmTransitionData transition;
  external SmStateData state;
  external SmMessageData message;
  external SmStringInputData stringInput;
  external SmNumericInputData numericInput;
  external SmBooleanInputData booleanInput;
  external SmInputFiredData inputFired;
}

final class DotLottieStateMachineEvent extends Struct {
  @Int32()
  external int eventType;
  external DotLottieStateMachineEventData data;
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

// Seek
final dotlottieSetFrame = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Float),
    int Function(Pointer<DotLottiePlayer>, double)>('dotlottie_set_frame');

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

// Layout (fit + alignment) — struct passed by value.
final dotlottieSetLayout = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, DotLottieLayout),
    int Function(
        Pointer<DotLottiePlayer>, DotLottieLayout)>('dotlottie_set_layout');

// Event polling
final dotlottiePollEvent = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<DotLottiePlayerEvent>),
    int Function(Pointer<DotLottiePlayer>,
        Pointer<DotLottiePlayerEvent>)>('dotlottie_poll_event');

// Themes
final dotlottieSetTheme = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Utf8>),
    int Function(Pointer<DotLottiePlayer>, Pointer<Utf8>)>('dotlottie_set_theme');

final dotlottieResetTheme =
    _lib.lookupFunction<Int32 Function(Pointer<DotLottiePlayer>),
        int Function(Pointer<DotLottiePlayer>)>('dotlottie_reset_theme');

final dotlottieSetThemeData = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Utf8>),
    int Function(
        Pointer<DotLottiePlayer>, Pointer<Utf8>)>('dotlottie_set_theme_data');

final dotlottieGetThemeId = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Uint8>, Pointer<UintPtr>),
    int Function(Pointer<DotLottiePlayer>, Pointer<Uint8>,
        Pointer<UintPtr>)>('dotlottie_get_theme_id');

// Markers
final dotlottieSetMarker = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Utf8>),
    int Function(
        Pointer<DotLottiePlayer>, Pointer<Utf8>)>('dotlottie_set_marker');

final dotlottieGetActiveMarker = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Uint8>, Pointer<UintPtr>),
    int Function(Pointer<DotLottiePlayer>, Pointer<Uint8>,
        Pointer<UintPtr>)>('dotlottie_get_active_marker');

final dotlottieGetMarkersCount = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Uint32>),
    int Function(Pointer<DotLottiePlayer>,
        Pointer<Uint32>)>('dotlottie_get_markers_count');

final dotlottieGetMarker = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Uint32, Pointer<Pointer<Utf8>>,
        Pointer<Float>, Pointer<Float>),
    int Function(Pointer<DotLottiePlayer>, int, Pointer<Pointer<Utf8>>,
        Pointer<Float>, Pointer<Float>)>('dotlottie_get_marker');

// Segments
// C type is `const float (*)[2]` — at the machine level this is just float*.
final dotlottieSetSegment = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Float>),
    int Function(
        Pointer<DotLottiePlayer>, Pointer<Float>)>('dotlottie_set_segment');

final dotlottieGetSegment = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Float>),
    int Function(
        Pointer<DotLottiePlayer>, Pointer<Float>)>('dotlottie_get_segment');

// Multi-animation
final dotlottieLoadAnimation = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Utf8>),
    int Function(
        Pointer<DotLottiePlayer>, Pointer<Utf8>)>('dotlottie_load_animation');

final dotlottieGetAnimationId = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Uint8>, Pointer<UintPtr>),
    int Function(Pointer<DotLottiePlayer>, Pointer<Uint8>,
        Pointer<UintPtr>)>('dotlottie_get_animation_id');

final dotlottieGetManifest = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Uint8>, Pointer<UintPtr>),
    int Function(Pointer<DotLottiePlayer>, Pointer<Uint8>,
        Pointer<UintPtr>)>('dotlottie_get_manifest');

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

// Lifecycle
final dotlottieStateMachineLoad = _lib.lookupFunction<
    Pointer<DotLottieStateMachine> Function(
        Pointer<DotLottiePlayer>, Pointer<Utf8>),
    Pointer<DotLottieStateMachine> Function(Pointer<DotLottiePlayer>,
        Pointer<Utf8>)>('dotlottie_state_machine_load');

final dotlottieStateMachineLoadData = _lib.lookupFunction<
    Pointer<DotLottieStateMachine> Function(
        Pointer<DotLottiePlayer>, Pointer<Utf8>),
    Pointer<DotLottieStateMachine> Function(Pointer<DotLottiePlayer>,
        Pointer<Utf8>)>('dotlottie_state_machine_load_data');

final dotlottieStateMachineStart = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>, Bool),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>,
        bool)>('dotlottie_state_machine_start');

final dotlottieStateMachineStop = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>),
    int Function(
        Pointer<DotLottieStateMachine>)>('dotlottie_state_machine_stop');

final dotlottieStateMachineRelease = _lib.lookupFunction<
    Void Function(Pointer<DotLottieStateMachine>),
    void Function(
        Pointer<DotLottieStateMachine>)>('dotlottie_state_machine_release');

// Tick
final dotlottieStateMachineTick = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Float, Pointer<Bool>),
    int Function(Pointer<DotLottieStateMachine>, double,
        Pointer<Bool>)>('dotlottie_state_machine_tick');

// Pointer events (all take float x, y)
final dotlottieStateMachinePostPointerDown = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Float, Float),
    int Function(Pointer<DotLottieStateMachine>, double,
        double)>('dotlottie_state_machine_post_pointer_down');

final dotlottieStateMachinePostPointerUp = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Float, Float),
    int Function(Pointer<DotLottieStateMachine>, double,
        double)>('dotlottie_state_machine_post_pointer_up');

final dotlottieStateMachinePostPointerMove = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Float, Float),
    int Function(Pointer<DotLottieStateMachine>, double,
        double)>('dotlottie_state_machine_post_pointer_move');

final dotlottieStateMachinePostPointerEnter = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Float, Float),
    int Function(Pointer<DotLottieStateMachine>, double,
        double)>('dotlottie_state_machine_post_pointer_enter');

final dotlottieStateMachinePostPointerExit = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Float, Float),
    int Function(Pointer<DotLottieStateMachine>, double,
        double)>('dotlottie_state_machine_post_pointer_exit');

final dotlottieStateMachinePostClick = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Float, Float),
    int Function(Pointer<DotLottieStateMachine>, double,
        double)>('dotlottie_state_machine_post_click');

// Inputs
final dotlottieStateMachineFireEvent = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>),
    int Function(Pointer<DotLottieStateMachine>,
        Pointer<Utf8>)>('dotlottie_state_machine_fire_event');

final dotlottieStateMachineSetNumericInput = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>, Float),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>,
        double)>('dotlottie_state_machine_set_numeric_input');

final dotlottieStateMachineSetStringInput = _lib.lookupFunction<
    Int32 Function(
        Pointer<DotLottieStateMachine>, Pointer<Utf8>, Pointer<Utf8>),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>,
        Pointer<Utf8>)>('dotlottie_state_machine_set_string_input');

final dotlottieStateMachineSetBooleanInput = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>, Bool),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>,
        bool)>('dotlottie_state_machine_set_boolean_input');

final dotlottieStateMachineGetNumericInput = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>, Pointer<Float>),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>,
        Pointer<Float>)>('dotlottie_state_machine_get_numeric_input');

final dotlottieStateMachineGetStringInput = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>, Pointer<Uint8>,
        Pointer<UintPtr>),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>, Pointer<Uint8>,
        Pointer<UintPtr>)>('dotlottie_state_machine_get_string_input');

final dotlottieStateMachineGetBooleanInput = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>, Pointer<Bool>),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Utf8>,
        Pointer<Bool>)>('dotlottie_state_machine_get_boolean_input');

// Status
final dotlottieStateMachineGetCurrentState = _lib.lookupFunction<
    Int32 Function(
        Pointer<DotLottieStateMachine>, Pointer<Uint8>, Pointer<UintPtr>),
    int Function(Pointer<DotLottieStateMachine>, Pointer<Uint8>,
        Pointer<UintPtr>)>('dotlottie_state_machine_get_current_state');

final dotlottieStateMachineGetFrameworkSetup = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottieStateMachine>, Pointer<Uint16>),
    int Function(Pointer<DotLottieStateMachine>,
        Pointer<Uint16>)>('dotlottie_state_machine_get_framework_setup');

// Event polling
final dotlottieStateMachinePollEvent = _lib.lookupFunction<
    Int32 Function(
        Pointer<DotLottieStateMachine>, Pointer<DotLottieStateMachineEvent>),
    int Function(Pointer<DotLottieStateMachine>,
        Pointer<DotLottieStateMachineEvent>)>(
    'dotlottie_state_machine_poll_event');

// Definition fetch (player-level)
final dotlottieGetStateMachine = _lib.lookupFunction<
    Int32 Function(Pointer<DotLottiePlayer>, Pointer<Utf8>, Pointer<Uint8>,
        Pointer<UintPtr>),
    int Function(Pointer<DotLottiePlayer>, Pointer<Utf8>, Pointer<Uint8>,
        Pointer<UintPtr>)>('dotlottie_get_state_machine');
