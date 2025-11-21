# dotLottie Flutter

A Flutter plugin for rendering Lottie and dotLottie animations with full playback control, state machine support, and cross-platform compatibility.

**Platforms supported:** iOS, Android, macOS, and Web

Built on top of native implementations:
- [iOS/macOS](https://github.com/LottieFiles/dotlottie-ios/)
- [Android](https://github.com/LottieFiles/dotlottie-android/)
- [Web](https://github.com/LottieFiles/dotlottie-web)

## Features

- ✨ Play Lottie and dotLottie animations
- 🎮 Full playback control (play, pause, stop, seek)
- 🔄 State machine support with interactive inputs
- 🎨 Theme support
- 📱 Cross-platform: iOS, Android, macOS, and Web

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Properties](#properties)
- [Methods](#methods)
- [Events](#events)
- [State Machines](#state-machine-example)
- [Developer Setup](#developer-setup-guide)

## Installation

With Flutter:

```bash
flutter pub add dotlottie-flutter
```

This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get)

Import it in your Dart code:

```dart
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
```

### Android

To allow dotlottie-android to download, ensure you have jitpack inside your build.gradle.kts file:

```kotlin
maven { url = uri("https://jitpack.io") }
```

## Quick Start

```
import 'package:flutter/material.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DotLottieViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('dotLottie Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // DotLottie animation view
              SizedBox(
                width: 300,
                height: 300,
                child: DotLottieView(
                  sourceType: 'url',
                  source: 'https://lottie.host/your-animation.lottie',
                  autoplay: true,
                  loop: true,
                  onViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoad: () {
                     // Do something
                  }
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Basic playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _controller?.play(),
                    child: const Text('Play'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _controller?.pause(),
                    child: const Text('Pause'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _controller?.stop(),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Properties

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `source` | `String` | The source of the animation (URL, asset path, or JSON string) |
| `sourceType` | `String` | Type of source: `'url'`, `'asset'`, or `'json'` |

### Playback Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `autoplay` | `bool` | `false` | Whether the animation should start playing automatically |
| `loop` | `bool` | `false` | Whether the animation should loop |
| `loopCount` | `int?` | `null` | Number of times to loop (overrides `loop` if set) |
| `speed` | `double` | `1.0` | Playback speed multiplier (e.g., `2.0` for double speed) |
| `mode` | `String?` | `null` | Playback mode: `'forward'`, `'reverse'`, `'bounce'`, or `'reverse-bounce'` |
| `useFrameInterpolation` | `bool` | `false` | Enable frame interpolation for smoother playback |

### Animation Control

| Property | Type | Description |
|----------|------|-------------|
| `segment` | `List<double>?` | Play a specific segment `[startFrame, endFrame]` |
| `marker` | `String?` | Play from a named marker defined in the animation |
| `animationId` | `String?` | ID of a specific animation to play (for multi-animation files) |

### Visual Properties

| Property | Type | Description |
|----------|------|-------------|
| `backgroundColor` | `String?` | Background color in hex format (e.g., `'#FF0000'`) |
| `width` | `double?` | Canvas width for rendering |
| `height` | `double?` | Canvas height for rendering |

### Advanced Properties

| Property | Type | Description |
|----------|------|-------------|
| `themeId` | `String?` | ID of a theme to apply to the animation |
| `stateMachineId` | `String?` | ID of a state machine to load and start automatically |

## Example Usage
```dart
DotLottieView(
  source: 'https://lottie.host/your-animation.lottie',
  sourceType: 'url',
  autoplay: true,
  loop: true,
  speed: 1.5,
  mode: 'bounce',
  backgroundColor: '#FFFFFF',
  useFrameInterpolation: true,
  onViewCreated: (controller) {
    // Access controller for programmatic control
  },
)
```

## State Machine Example
```dart
DotLottieView(
  source: 'https://lottie.host/your-animation.lottie',
  sourceType: 'url',
  stateMachineId: 'myStateMachine',
  onViewCreated: (controller) {
    _controller = controller;
  },
  stateMachineOnStateEntered: (state) {
    print('Entered state: $state');
  },
)

// Interact with the state machine
ElevatedButton(
  onPressed: () {
    _controller?.stateMachineSetBooleanInput('isActive', true);
    _controller?.stateMachineFire('myEvent');
  },
  child: Text('Trigger Event'),
)
```

### Methods

Access these methods via the controller:
```dart
DotLottieViewController? _controller;
await _controller?.play();
```

#### Playback Control

| Method | Returns | Description |
|--------|---------|-------------|
| `play()` | `Future<bool?>` | Starts playing the animation. |
| `pause()` | `Future<bool?>` | Pauses the animation. |
| `stop()` | `Future<bool?>` | Stops the animation and resets to the beginning. |

#### Animation State Getters

| Method | Returns | Description |
|--------|---------|-------------|
| `isPlaying()` | `Future<bool?>` | Returns whether the animation is currently playing. |
| `isPaused()` | `Future<bool?>` | Returns whether the animation is paused. |
| `isStopped()` | `Future<bool?>` | Returns whether the animation is stopped. |
| `isLoaded()` | `Future<bool?>` | Returns whether the animation has loaded. |
| `currentFrame()` | `Future<double?>` | Gets the current frame number. |
| `totalFrames()` | `Future<double?>` | Gets the total number of frames. |
| `currentProgress()` | `Future<double?>` | Gets the current progress (0.0 to 1.0). |
| `duration()` | `Future<double?>` | Gets the animation duration in milliseconds. |
| `loopCount()` | `Future<int?>` | Gets the current loop count. |
| `speed()` | `Future<double?>` | Gets the current playback speed. |
| `loop()` | `Future<bool?>` | Gets the loop setting. |
| `autoplay()` | `Future<bool?>` | Gets the autoplay setting. |
| `useFrameInterpolation()` | `Future<bool?>` | Gets the frame interpolation setting. |
| `segments()` | `Future<List<double>?>` | Gets the active segment `[start, end]`. |
| `mode()` | `Future<String?>` | Gets the current playback mode. |

#### Animation Control Setters

| Method | Returns | Description |
|--------|---------|-------------|
| `setSpeed(double speed)` | `Future<void>` | Sets the playback speed. |
| `setLoop(bool loop)` | `Future<void>` | Sets whether the animation should loop. |
| `setFrame(double frame)` | `Future<bool?>` | Sets the current frame. |
| `setProgress(double progress)` | `Future<bool?>` | Sets the progress (0.0 to 1.0). |
| `setSegments(double start, double end)` | `Future<void>` | Sets a segment of the animation to play. |
| `setMarker(String marker)` | `Future<void>` | Sets a marker for playback. |
| `setMode(String mode)` | `Future<void>` | Sets the playback mode. |
| `setFrameInterpolation(bool useFrameInterpolation)` | `Future<void>` | Enables or disables frame interpolation. |

#### Theme Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `setTheme(String themeId)` | `Future<bool?>` | Applies a theme by ID. |
| `setThemeData(String themeData)` | `Future<bool?>` | Applies a theme using JSON data. |
| `resetTheme()` | `Future<bool?>` | Resets to the default theme. |
| `activeThemeId()` | `Future<String?>` | Gets the currently active theme ID. |

#### Animation Loading

| Method | Returns | Description |
|--------|---------|-------------|
| `loadAnimation(String animationId)` | `Future<void>` | Loads a specific animation by ID. |
| `activeAnimationId()` | `Future<String?>` | Gets the currently active animation ID. |
| `markers()` | `Future<List<Map<String, dynamic>>?>` | Gets all available markers. |

#### Advanced Features

| Method | Returns | Description |
|--------|---------|-------------|
| `setSlots(String slots)` | `Future<bool?>` | Sets slot data for dynamic content. |
| `resize(int width, int height)` | `Future<void>` | Resizes the animation viewport. |
| `getLayerBounds(String layerName)` | `Future<List<double>?>` | Gets the bounds of a specific layer. |
| `manifest()` | `Future<Map<String, dynamic>?>` | Gets the animation manifest data. |

#### State Machine Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `stateMachineLoad(String stateMachineId)` | `Future<bool?>` | Loads a state machine by ID. |
| `stateMachineLoadData(String data)` | `Future<bool?>` | Loads a state machine from JSON data. |
| `stateMachineStart()` | `Future<bool?>` | Starts the loaded state machine. |
| `stateMachineStop()` | `Future<bool?>` | Stops the state machine. |
| `stateMachineFire(String event)` | `Future<void>` | Fires a named event in the state machine. |
| `stateMachineSetNumericInput(String key, double value)` | `Future<bool?>` | Sets a numeric input value. |
| `stateMachineSetStringInput(String key, String value)` | `Future<bool?>` | Sets a string input value. |
| `stateMachineSetBooleanInput(String key, bool value)` | `Future<bool?>` | Sets a boolean input value. |
| `stateMachineGetNumericInput(String key)` | `Future<double?>` | Gets a numeric input value. |
| `stateMachineGetStringInput(String key)` | `Future<String?>` | Gets a string input value. |
| `stateMachineGetBooleanInput(String key)` | `Future<bool?>` | Gets a boolean input value. |
| `stateMachineGetInputs()` | `Future<Map<String, String>?>` | Gets all input names and their types. |
| `stateMachineCurrentState()` | `Future<String?>` | Gets the current state name. |
| `getStateMachine(String id)` | `Future<String?>` | Gets state machine data by ID. |

#### Cleanup

| Method | Returns | Description |
|--------|---------|-------------|
| `dispose()` | `Future<void>` | Disposes of the controller and releases resources. |

### Events

Add listeners to events on the widget:
```dart
DotLottieView(
   onFrame: (frameNo) {
      // Do something
   }
)
```

| Event                                  | Description                                                   |
| -------------------------------------- | ------------------------------------------------------------- |
| `onLoad` → `void Function()?`                  | Called when the animation is loaded.                          |
| `onComplete` → `void Function()?`              | Called when the animation completes.                          |
| `onLoadError` → `void Function()?`             | Called when there's an error loading the animation.           |
| `onPlay` → `void Function()?`                  | Called when the animation starts playing.                     |
| `onPause` → `void Function()?`                 | Called when the animation is paused.                          |
| `onStop` → `void Function()?`                  | Called when the animation is stopped.                         |
| `onLoop` → `void Function(double loopCount)?` | Called when the animation loops, with the current loop count. |
| `onFrame` → `void Function(double frameNo)?`  | Called on each frame update.                                  |
| `onRender` → `void Function(double frameNo)?` | Called when a frame is rendered.                              |
| `onFreeze` → `void Function()?`                | Called when the animation is frozen.                          |
| `onUnFreeze` → `void Function()?`              | Called when the animation is unfrozen.                        |
| `onDestroy` → `void Function()?`               | Called when the animation is destroyed.                       |

### State Machine Events

| Event                                                                                                  | Description                                      |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------ |
| `stateMachineOnStart` → `void Function()?`                                                                     | Called when the state machine starts.            |
| `stateMachineOnStop` → `void Function()?`                                                                      | Called when the state machine stops.             |
| `stateMachineOnStateEntered` → `void Function(String enteringState)?`                                         | Called when entering a new state.                |
| `stateMachineOnStateExit` → `void Function(String leavingState)?`                                             | Called when exiting a state.                     |
| `stateMachineOnTransition` → `void Function(String previousState, String newState)?`                         | Called during a state transition.                |
| `stateMachineOnBooleanInputValueChange` → `void Function(String inputName, bool oldValue, bool newValue)?` | Called when a boolean input changes.             |
| `stateMachineOnNumericInputValueChange` → `void Function(String inputName, double oldValue, double newValue)?`   | Called when a numeric input changes.             |
| `stateMachineOnStringInputValueChange` → `void Function(String inputName, String oldValue, String newValue)?`    | Called when a string input changes.              |
| `stateMachineOnInputFired` → `void Function(String inputName)?`                                               | Called when an input event is fired.             |
| `stateMachineOnCustomEvent` → `void Function(String message)?`                                                | Called when a custom state machine event occurs. |
| `stateMachineOnError` → `void Function(String message)?`                                                      | Called when a state machine error occurs.        |

## Contributing

See the [development guide](DEVELOPMENT.md) to learn how to get up and running with this project. Once you're ready, please submit a pull request and we will review it! Thanks!

## License

MIT
