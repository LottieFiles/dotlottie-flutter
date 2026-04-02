// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'dotlottie_flutter_platform_interface.dart';

// Store view instances globally so they can be accessed by method channels
final Map<int, DotLottieWebView> _viewInstances = {};

// Store creation params to initialize after view factory returns
final Map<int, Map<String, dynamic>> _creationParams = {};

/// A web implementation of the DotLottieFlutterPlatform of the DotlottieFlutter plugin.
class DotLottieFlutterWeb extends DotLottieFlutterPlatform {
  DotLottieFlutterWeb();

  static void registerWith(Registrar registrar) {
    DotLottieFlutterPlatform.instance = DotLottieFlutterWeb();

    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.type = 'module';
    script.text = '''
    import { DotLottie } from 'https://cdn.jsdelivr.net/npm/@lottiefiles/dotlottie-web@0.69.0/+esm';
    window.DotLottie = DotLottie;
    window.dispatchEvent(new Event('dotlottie-ready'));
  ''';
    web.document.head?.appendChild(script);

    ui_web.platformViewRegistry.registerViewFactory('dotlottie_view', (
      int viewId,
    ) {
      final view = DotLottieWebView(viewId, registrar);
      _viewInstances[viewId] = view;

      if (_creationParams.containsKey(viewId)) {
        Future.delayed(Duration(milliseconds: 100), () {
          final params = _creationParams.remove(viewId);
          if (params != null) {
            view.initializeFromParams(params);
          }
        });
      }

      return view.element;
    });
  }
}

class DotLottieWebView {
  final int viewId;
  final BinaryMessenger messenger;
  late final web.HTMLDivElement element;
  late final web.HTMLCanvasElement canvasElement;
  late final MethodChannel methodChannel;
  JSAny? dotLottiePlayer;
  bool isDisposed = false;
  bool isInitialized = false;

  DotLottieWebView(this.viewId, this.messenger) {
    element = web.document.createElement('div') as web.HTMLDivElement;
    element.id = 'dotlottie-container-$viewId';
    element.style.width = '100%';
    element.style.height = '100%';
    element.style.overflow = 'hidden';
    element.style.display = 'block';

    canvasElement =
        web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvasElement.id = 'dotlottie-canvas-$viewId';
    canvasElement.style.width = '100%';
    canvasElement.style.height = '100%';
    canvasElement.style.display = 'block';

    element.appendChild(canvasElement);

    methodChannel = MethodChannel(
      'dotlottie_view_$viewId',
      const StandardMethodCodec(),
      messenger,
    );
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  // Initialize from creation params (called by view factory)
  void initializeFromParams(Map<String, dynamic> params) {
    _waitForDotLottieAsync().then((_) {
      initialize(params);
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (isDisposed && call.method != 'dispose') {
      throw PlatformException(
        code: 'DISPOSED',
        message: 'View has been disposed',
      );
    }

    switch (call.method) {
      case 'initialize':
        final config = Map<String, dynamic>.from(call.arguments as Map);
        _creationParams[viewId] = config;
        await _waitForDotLottieAsync();
        initialize(config);
        return null;

      case 'play':
        return play();

      case 'pause':
        return pause();

      case 'stop':
        return stop();

      case 'isPlaying':
        return isPlaying();

      case 'isPaused':
        return isPaused();

      case 'isStopped':
        return isStopped();

      case 'isLoaded':
        return isLoaded();

      case 'currentFrame':
        return currentFrame();

      case 'totalFrames':
        return totalFrames();

      case 'duration':
        return duration();

      case 'loopCount':
        return loopCount();

      case 'speed':
        return speed();

      case 'loop':
        return loop();

      case 'autoplay':
        return autoplay();

      case 'useFrameInterpolation':
        return useFrameInterpolation();

      case 'segments':
        return segments();

      case 'mode':
        return mode();

      case 'setSpeed':
        final speed = (call.arguments as Map)['speed'] as double;
        setSpeed(speed);
        return null;

      case 'setLoop':
        final loop = (call.arguments as Map)['loop'] as bool;
        setLoop(loop);
        return null;

      case 'setFrame':
        final frame = (call.arguments as Map)['frame'] as double;
        return setFrame(frame);

      case 'setProgress':
        final progress = (call.arguments as Map)['progress'] as double;
        return setProgress(progress);

      case 'setSegment':
        final args = call.arguments as Map;
        final start = args['start'] as double;
        final end = args['end'] as double;
        setSegment(start, end);
        return null;

      case 'setMode':
        final mode = (call.arguments as Map)['mode'] as String;
        setMode(mode);
        return null;

      case 'setFrameInterpolation':
        final useFrameInterpolation =
            (call.arguments as Map)['useFrameInterpolation'] as bool;
        setUseFrameInterpolation(useFrameInterpolation);
        return null;

      case 'setBackgroundColor':
        final color = (call.arguments as Map)['color'] as String;
        setBackgroundColor(color);
        return null;

      case 'setTheme':
        final themeId = (call.arguments as Map)['themeId'] as String;
        return setTheme(themeId);

      case 'setThemeData':
        final themeData = (call.arguments as Map)['themeData'] as String;
        return setThemeData(themeData);

      case 'resetTheme':
        return resetTheme();

      case 'activeThemeId':
        return activeThemeId();

      case 'loadAnimation':
        final animationId = (call.arguments as Map)['animationId'] as String;
        loadAnimation(animationId);
        return null;

      case 'activeAnimationId':
        return activeAnimationId();

      case 'setMarker':
        final marker = (call.arguments as Map)['marker'] as String;
        setMarker(marker);
        return null;

      case 'markers':
        return markers();

      case 'setSlots':
        final slots = (call.arguments as Map)['slots'] as String;
        return setSlots(slots);

      case 'resize':
        final args = call.arguments as Map;
        final width = args['width'] as int;
        final height = args['height'] as int;
        resize(width, height);
        return null;

      case 'getLayerBounds':
        final layerName = (call.arguments as Map)['layerName'] as String;
        return getLayerBounds(layerName);

      case 'stateMachineLoad':
        final stateMachineId =
            (call.arguments as Map)['stateMachineId'] as String;
        return stateMachineLoad(stateMachineId);

      case 'stateMachineLoadData':
        final data = (call.arguments as Map)['data'] as String;
        return stateMachineLoadData(data);

      case 'stateMachineStart':
        return stateMachineStart();

      case 'stateMachineStop':
        return stateMachineStop();

      case 'stateMachineFire':
        final event = (call.arguments as Map)['event'] as String;
        stateMachineFire(event);
        return null;

      case 'stateMachineSetNumericInput':
        final args = call.arguments as Map;
        final key = args['key'] as String;
        final value = args['value'] as double;
        return stateMachineSetNumericInput(key, value);

      case 'stateMachineSetStringInput':
        final args = call.arguments as Map;
        final key = args['key'] as String;
        final value = args['value'] as String;
        return stateMachineSetStringInput(key, value);

      case 'stateMachineSetBooleanInput':
        final args = call.arguments as Map;
        final key = args['key'] as String;
        final value = args['value'] as bool;
        return stateMachineSetBooleanInput(key, value);

      case 'stateMachineGetNumericInput':
        final key = (call.arguments as Map)['key'] as String;
        return stateMachineGetNumericInput(key);

      case 'stateMachineGetStringInput':
        final key = (call.arguments as Map)['key'] as String;
        return stateMachineGetStringInput(key);

      case 'stateMachineGetBooleanInput':
        final key = (call.arguments as Map)['key'] as String;
        return stateMachineGetBooleanInput(key);

      case 'stateMachineGetInputs':
        return stateMachineGetInputs();

      case 'stateMachineCurrentState':
        return stateMachineCurrentState();

      case 'getStateMachine':
        final id = (call.arguments as Map)['id'] as String;
        return getStateMachine(id);

      case 'manifest':
        return manifest();

      case 'dispose':
        dispose();
        return null;

      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  Future<void> _waitForDotLottieAsync() async {
    var attempts = 0;
    while (attempts < 50) {
      if (isDisposed) return;

      final windowObj = web.window as JSObject;
      final dotLottie = windowObj['DotLottie'.toJS];

      if (dotLottie != null) {
        return;
      }

      attempts++;
      if (attempts % 10 == 0) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Initialize the DotLottie player with config from Dart
  void initialize(Map<String, dynamic> config) {
    if (isDisposed) {
      return;
    }

    if (isInitialized) {
      return;
    }

    try {
      // Get the DotLottie constructor from window
      final windowObj = web.window as JSObject;
      final dotLottieConstructor = windowObj['DotLottie'.toJS];

      if (dotLottieConstructor == null) {
        return;
      }

      // Create config object
      final playerConfig = JSObject();

      // Set canvas
      playerConfig['canvas'.toJS] = canvasElement as JSAny;

      // Set source based on sourceType
      final sourceType = config['sourceType'] as String?;
      final source = config['source'] as String?;

      if (sourceType != null && source != null) {
        switch (sourceType) {
          case 'url':
            playerConfig['src'.toJS] = source.toJS;
            break;
          case 'json':
            playerConfig['data'.toJS] = source.toJS;
            break;
          case 'asset':
            playerConfig['src'.toJS] = 'assets/$source'.toJS;
            break;
        }
      }

      final autoplay = config['autoplay'] as bool? ?? true;
      playerConfig['autoplay'.toJS] = autoplay.toJS;

      final loop = config['loop'] as bool? ?? true;
      playerConfig['loop'.toJS] = loop.toJS;

      final loopCount = config['loopCount'] as num? ?? 0;
      playerConfig['loopCount'.toJS] = loopCount.toJS;

      final mode = config['mode'] as String? ?? 'forward';
      playerConfig['mode'.toJS] = mode.toJS;

      final speed = (config['speed'] as num? ?? 1.0).toDouble();
      playerConfig['speed'.toJS] = speed.toJS;

      final useFrameInterpolation =
          config['useFrameInterpolation'] as bool? ?? false;
      playerConfig['useFrameInterpolation'.toJS] = useFrameInterpolation.toJS;

      playerConfig['segment'.toJS] =
          ((config['segment'] as List?)?.map((e) => (e as num).toJS).toList() ??
                  [])
              .toJS;

      final backgroundColor = config['backgroundColor'] as String?;
      if (backgroundColor != null) {
        element.style.backgroundColor = backgroundColor;
      }

      final themeId = config['themeId'] as String? ?? '';
      playerConfig['themeId'.toJS] = themeId.toJS;

      final stateMachineId = config['stateMachineId'] as String? ?? '';
      playerConfig['stateMachineId'.toJS] = stateMachineId.toJS;

      final animationId = config['animationId'] as String? ?? '';
      playerConfig['animationId'.toJS] = animationId.toJS;

      final width = config['width'] as int?;
      final height = config['height'] as int?;
      if (width != null) {
        canvasElement.width = width;
      }
      if (height != null) {
        canvasElement.height = height;
      }

      // Create the DotLottie player instance
      dotLottiePlayer = _callConstructor(
        dotLottieConstructor as JSFunction,
        playerConfig,
      );

      isInitialized = true;

      _setupEventListeners();
      _setupStateMachineListeners();
    } catch (e) {
      print('Error initilizing dotLottie: $e');
    }
  }

  void _setupEventListeners() {
    if (dotLottiePlayer == null || isDisposed) return;

    try {
      final player = dotLottiePlayer as JSObject;
      final addEventListener = player['addEventListener'.toJS] as JSFunction;

      final onComplete = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('onComplete');
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'complete'.toJS, onComplete);

      final onLoad = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('onLoad');
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'load'.toJS, onLoad);

      final onLoadError = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('onLoadError');
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'loadError'.toJS, onLoadError);

      final onPlay = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('onPlay');
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'play'.toJS, onPlay);

      final onPause = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('onPause');
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'pause'.toJS, onPause);

      final onFrame = ((JSAny event) {
        if (!isDisposed) {
          try {
            // Extract frame number from event
            final jsEvent = event as JSObject;
            final frameNo =
                (jsEvent['currentFrame'.toJS] as JSNumber).toDartDouble;
            methodChannel.invokeMethod('onFrame', frameNo);
          } catch (e) {
            print('Error parsing frame event: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'frame'.toJS, onFrame);

      final onRender = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final frameNo =
                (jsEvent['currentFrame'.toJS] as JSNumber).toDartDouble;
            methodChannel.invokeMethod('onRender', frameNo);
          } catch (e) {
            print('Error parsing render event: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'render'.toJS, onRender);

      final onStop = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('onStop');
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'stop'.toJS, onStop);

      final onLoop = ((JSAny event) {
        if (!isDisposed) {
          try {
            // Extract loop count from event
            final jsEvent = event as JSObject;
            final loopCount = (jsEvent['loopCount'.toJS] as JSNumber).toDartInt;
            methodChannel.invokeMethod('onLoop', loopCount);
          } catch (e) {
            print('Error parsing loop event: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'loop'.toJS, onLoop);
    } catch (e) {
      print('Error setting up event listeners: $e');
    }
  }

  void _setupStateMachineListeners() {
    if (dotLottiePlayer == null || isDisposed) return;

    try {
      final player = dotLottiePlayer as JSObject;
      final addEventListener = player['addEventListener'.toJS] as JSFunction;

      final onStart = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('stateMachineOnStart');
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineStart'.toJS,
        onStart,
      );

      final onStop = (() {
        if (!isDisposed) {
          methodChannel.invokeMethod('stateMachineOnStop');
        }
      }).toJS;
      addEventListener.callAsFunction(player, 'stateMachineStop'.toJS, onStop);

      final onCustomEvent = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final eventName = (jsEvent['eventName'.toJS] as JSString).toDart;
            methodChannel.invokeMethod('stateMachineOnCustomEvent', eventName);
          } catch (e) {
            print('Error parsing stateMachineCustomEvent: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineCustomEvent'.toJS,
        onCustomEvent,
      );

      final onBoolInputChange = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final inputName = (jsEvent['inputName'.toJS] as JSString).toDart;
            final oldValue = (jsEvent['oldValue'.toJS] as JSBoolean).toDart;
            final newValue = (jsEvent['newValue'.toJS] as JSBoolean).toDart;
            methodChannel.invokeMethod(
              'stateMachineOnBooleanInputValueChange',
              {
                'inputName': inputName,
                'oldValue': oldValue,
                'newValue': newValue,
              },
            );
          } catch (e) {
            print('Error parsing stateMachineBooleanInputValueChange: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineBooleanInputValueChange'.toJS,
        onBoolInputChange,
      );

      final onNumericInputChange = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final inputName = (jsEvent['inputName'.toJS] as JSString).toDart;
            final oldValue =
                (jsEvent['oldValue'.toJS] as JSNumber).toDartDouble;
            final newValue =
                (jsEvent['newValue'.toJS] as JSNumber).toDartDouble;
            methodChannel.invokeMethod(
              'stateMachineOnNumericInputValueChange',
              {
                'inputName': inputName,
                'oldValue': oldValue,
                'newValue': newValue,
              },
            );
          } catch (e) {
            print('Error parsing stateMachineNumericInputValueChange: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineNumericInputValueChange'.toJS,
        onNumericInputChange,
      );

      final onStringInputChange = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final inputName = (jsEvent['inputName'.toJS] as JSString).toDart;
            final oldValue = (jsEvent['oldValue'.toJS] as JSString).toDart;
            final newValue = (jsEvent['newValue'.toJS] as JSString).toDart;
            methodChannel.invokeMethod('stateMachineOnStringInputValueChange', {
              'inputName': inputName,
              'oldValue': oldValue,
              'newValue': newValue,
            });
          } catch (e) {
            print('Error parsing stateMachineStringInputValueChange: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineStringInputValueChange'.toJS,
        onStringInputChange,
      );

      final onInputFired = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final inputName = (jsEvent['inputName'.toJS] as JSString).toDart;
            methodChannel.invokeMethod('stateMachineOnInputFired', inputName);
          } catch (e) {
            print('Error parsing stateMachineInputFired: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineInputFired'.toJS,
        onInputFired,
      );

      final onTransition = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final fromState = (jsEvent['fromState'.toJS] as JSString).toDart;
            final toState = (jsEvent['toState'.toJS] as JSString).toDart;
            methodChannel.invokeMethod('stateMachineOnTransition', {
              'previousState': fromState,
              'newState': toState,
            });
          } catch (e) {
            print('Error parsing stateMachineTransition: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineTransition'.toJS,
        onTransition,
      );

      final onStateEntered = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final state = (jsEvent['state'.toJS] as JSString).toDart;
            methodChannel.invokeMethod('stateMachineOnStateEntered', state);
          } catch (e) {
            print('Error parsing stateMachineStateEntered: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineStateEntered'.toJS,
        onStateEntered,
      );

      final onStateExit = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final state = (jsEvent['state'.toJS] as JSString).toDart;
            methodChannel.invokeMethod('stateMachineOnStateExit', state);
          } catch (e) {
            print('Error parsing stateMachineStateExit: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineStateExit'.toJS,
        onStateExit,
      );

      final onError = ((JSAny event) {
        if (!isDisposed) {
          try {
            final jsEvent = event as JSObject;
            final error = (jsEvent['error'.toJS] as JSString).toDart;
            methodChannel.invokeMethod('stateMachineOnError', error);
          } catch (e) {
            print('Error parsing stateMachineError: $e');
          }
        }
      }).toJS;
      addEventListener.callAsFunction(
        player,
        'stateMachineError'.toJS,
        onError,
      );
    } catch (e) {
      print('Error setting up state machine event listeners: $e');
    }
  }

  bool play() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final playMethod = player['play'.toJS] as JSFunction;
        playMethod.callAsFunction(player);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool pause() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final pauseMethod = player['pause'.toJS] as JSFunction;
        pauseMethod.callAsFunction(player);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool stop() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final stopMethod = player['stop'.toJS] as JSFunction;
        stopMethod.callAsFunction(player);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool isPlaying() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['isPlaying'.toJS];
        return (result as JSBoolean).toDart;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool isPaused() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['isPaused'.toJS];
        return (result as JSBoolean).toDart;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool isStopped() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['isStopped'.toJS];
        return (result as JSBoolean).toDart;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool isLoaded() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['isLoaded'.toJS];
        return (result as JSBoolean).toDart;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  double? currentFrame() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['currentFrame'.toJS];
        return (result as JSNumber).toDartDouble;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  double? totalFrames() {
    if (dotLottiePlayer == null) {}

    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['totalFrames'.toJS];

        return (result as JSNumber).toDartDouble;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  double? currentProgress() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final current = currentFrame();
        final total = totalFrames();
        if (current != null && total != null && total > 0) {
          return current / total;
        }
        return null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  double? duration() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['duration'.toJS];
        return (result as JSNumber).toDartDouble;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  int? loopCount() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['loopCount'.toJS];
        return (result as JSNumber).toDartInt;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  double? speed() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['speed'.toJS];
        return (result as JSNumber).toDartDouble;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool loop() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['loop'.toJS];
        return (result as JSBoolean).toDart;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool autoplay() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['autoplay'.toJS];
        return (result as JSBoolean).toDart;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool useFrameInterpolation() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['useFrameInterpolation'.toJS];
        return (result as JSBoolean).toDart;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  List<double>? segments() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['segment'.toJS];
        if (result != null) {
          final array = result as JSArray;
          return [
            (array[0] as JSNumber).toDartDouble,
            (array[1] as JSNumber).toDartDouble,
          ];
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? mode() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['mode'.toJS];
        return (result as JSString).toDart;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void setSpeed(double speed) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setSpeed'.toJS] as JSFunction;
        method.callAsFunction(player, speed.toJS);
      } catch (e) {}
    }
  }

  void setLoop(bool loop) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setLoop'.toJS] as JSFunction;
        method.callAsFunction(player, loop.toJS);
      } catch (e) {}
    }
  }

  bool setFrame(double frame) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setFrame'.toJS] as JSFunction;
        method.callAsFunction(player, frame.toJS);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool setProgress(double progress) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        // Calculate frame from progress
        final total = totalFrames();
        if (total != null && total > 0) {
          final frame = progress * total;
          return setFrame(frame);
        }
        return false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  void setSegment(double start, double end) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setSegment'.toJS] as JSFunction;
        method.callAsFunction(player, start.toJS, end.toJS);
      } catch (e) {}
    }
  }

  void setMode(String mode) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setMode'.toJS] as JSFunction;
        method.callAsFunction(player, mode.toJS);
      } catch (e) {}
    }
  }

  void setUseFrameInterpolation(bool useFrameInterpolation) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setUseFrameInterpolation'.toJS] as JSFunction;
        method.callAsFunction(player, useFrameInterpolation.toJS);
      } catch (e) {}
    }
  }

  void setBackgroundColor(String color) {
    if (!isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setBackgroundColor'.toJS] as JSFunction;
        method.callAsFunction(player, color.toJS);
      } catch (e) {
        // Fallback to setting element background color
        element.style.backgroundColor = color;
      }
    }
  }

  bool setTheme(String themeId) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setTheme'.toJS] as JSFunction;
        final result = method.callAsFunction(player, themeId.toJS);
        return (result as JSBoolean?)?.toDart ?? false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool setThemeData(String themeData) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setThemeData'.toJS] as JSFunction;
        final result = method.callAsFunction(player, themeData.toJS);
        return (result as JSBoolean?)?.toDart ?? false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool resetTheme() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['resetTheme'.toJS] as JSFunction?;
        if (method != null) {
          final result = method.callAsFunction(player);
          return (result as JSBoolean?)?.toDart ?? false;
        }
      } catch (e) {}
    }
    return false;
  }

  String? activeThemeId() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['activeThemeId'.toJS];
        return (result as JSString?)?.toDart;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void loadAnimation(String animationId) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['loadAnimation'.toJS] as JSFunction;
        method.callAsFunction(player, animationId.toJS);
      } catch (e) {}
    }
  }

  String? activeAnimationId() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['activeAnimationId'.toJS];
        return (result as JSString?)?.toDart;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void setMarker(String marker) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setMarker'.toJS] as JSFunction;
        method.callAsFunction(player, marker.toJS);
      } catch (e) {}
    }
  }

  List<Map<String, dynamic>>? markers() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['markers'.toJS] as JSFunction;
        final result = method.callAsFunction(player);
        if (result != null) {
          final array = result as JSArray;
          final markers = <Map<String, dynamic>>[];
          final length = (array.length as JSNumber).toDartInt;
          for (var i = 0; i < length; i++) {
            final marker = array[i] as JSObject;
            markers.add(_jsObjectToMap(marker));
          }
          return markers;
        }
      } catch (e) {}
    }
    return null;
  }

  bool setSlots(String slots) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['setSlots'.toJS] as JSFunction?;
        if (method != null) {
          method.callAsFunction(player, slots.toJS);
          return true;
        }
      } catch (e) {}
    }
    return false;
  }

  void resize(int width, int height) {
    if (!isDisposed) {
      canvasElement.width = width;
      canvasElement.height = height;

      if (dotLottiePlayer != null) {
        try {
          final player = dotLottiePlayer as JSObject;
          final method = player['resize'.toJS] as JSFunction?;
          if (method != null) {
            method.callAsFunction(player);
          }
        } catch (e) {}
      }
    }
  }

  List<double>? getLayerBounds(String layerName) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['getLayerBoundingBox'.toJS] as JSFunction?;
        if (method != null) {
          final result = method.callAsFunction(player, layerName.toJS);
          if (result != null) {
            final array = result as JSArray;
            final bounds = <double>[];
            final length = (array.length as JSNumber).toDartInt;
            for (var i = 0; i < length; i++) {
              bounds.add((array[i] as JSNumber).toDartDouble);
            }
            return bounds;
          }
        }
      } catch (e) {}
    }
    return null;
  }

  bool stateMachineLoad(String stateMachineId) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineLoad'.toJS] as JSFunction;
        final result = method.callAsFunction(player, stateMachineId.toJS);
        return (result as JSBoolean?)?.toDart ?? true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool stateMachineLoadData(String data) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineLoadData'.toJS] as JSFunction;
        final result = method.callAsFunction(player, data.toJS);
        return (result as JSBoolean?)?.toDart ?? true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool stateMachineStart() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineStart'.toJS] as JSFunction;
        final result = method.callAsFunction(player);
        return (result as JSBoolean?)?.toDart ?? true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool stateMachineStop() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineStop'.toJS] as JSFunction;
        final result = method.callAsFunction(player);
        return (result as JSBoolean?)?.toDart ?? true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  void stateMachineFire(String event) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineFireEvent'.toJS] as JSFunction;
        method.callAsFunction(player, event.toJS);
      } catch (e) {}
    }
  }

  bool stateMachineSetNumericInput(String key, double value) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineSetNumericInput'.toJS] as JSFunction;
        final result = method.callAsFunction(player, key.toJS, value.toJS);
        return (result as JSBoolean?)?.toDart ?? true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool stateMachineSetStringInput(String key, String value) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineSetStringInput'.toJS] as JSFunction;
        final result = method.callAsFunction(player, key.toJS, value.toJS);
        return (result as JSBoolean?)?.toDart ?? true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool stateMachineSetBooleanInput(String key, bool value) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineSetBooleanInput'.toJS] as JSFunction;
        final result = method.callAsFunction(player, key.toJS, value.toJS);
        return (result as JSBoolean?)?.toDart ?? true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  double? stateMachineGetNumericInput(String key) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineGetNumericInput'.toJS] as JSFunction;
        final result = method.callAsFunction(player, key.toJS);
        return (result as JSNumber?)?.toDartDouble;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? stateMachineGetStringInput(String key) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineGetStringInput'.toJS] as JSFunction;
        final result = method.callAsFunction(player, key.toJS);
        return (result as JSString?)?.toDart;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool? stateMachineGetBooleanInput(String key) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineGetBooleanInput'.toJS] as JSFunction;
        final result = method.callAsFunction(player, key.toJS);
        return (result as JSBoolean?)?.toDart;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, String>? stateMachineGetInputs() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineGetInputs'.toJS] as JSFunction;
        final result = method.callAsFunction(player);
        if (result != null) {
          final array = result as JSArray;
          final inputs = <String, String>{};
          final length = (array.length as JSNumber).toDartInt;

          for (var i = 0; i < length; i += 2) {
            if (i + 1 < length) {
              final name = (array[i] as JSString).toDart;
              final type = (array[i + 1] as JSString).toDart;
              inputs[name] = type;
            }
          }
          return inputs;
        }
      } catch (e) {}
    }
    return null;
  }

  String? stateMachineCurrentState() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final result = player['stateMachineGetCurrentState'.toJS];
        return (result as JSString?)?.toDart;
      } catch (e) {}
    }
    return null;
  }

  String? getStateMachine(String id) {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;
        final method = player['stateMachineGet'.toJS] as JSFunction;
        final result = method.callAsFunction(player, id.toJS);
        return (result as JSString?)?.toDart;
      } catch (e) {}
    }
    return null;
  }

  Map<String, dynamic>? manifest() {
    if (dotLottiePlayer != null && !isDisposed) {
      try {
        final player = dotLottiePlayer as JSObject;

        final result = player['manifest'.toJS];

        if (result != null && !result.typeofEquals('undefined')) {
          final manifestMap = _jsObjectToMap(result as JSObject);
          return manifestMap;
        }
      } catch (e, _) {
        return null;
      }
    }
    return null;
  }

  void dispose() {
    if (isDisposed) return;

    isDisposed = true;

    if (dotLottiePlayer != null) {
      try {
        final player = dotLottiePlayer as JSObject;
        final destroyMethod = player['destroy'.toJS] as JSFunction;
        destroyMethod.callAsFunction(player);
      } catch (e) {}
      dotLottiePlayer = null;
    }

    _viewInstances.remove(viewId);
    _creationParams.remove(viewId);
  }

  Map<String, dynamic> _jsObjectToMap(JSObject jsObj) {
    final map = <String, dynamic>{};
    try {
      final keys = (web.window as JSObject)['Object'.toJS] as JSObject;
      final keysMethod = keys['keys'.toJS] as JSFunction;
      final keysList = keysMethod.callAsFunction(keys, jsObj) as JSArray;
      final length = (keysList.length as JSNumber).toDartInt;

      for (var i = 0; i < length; i++) {
        final key = (keysList[i] as JSString).toDart;
        final value = jsObj[key.toJS];
        map[key] = _jsValueToDart(value);
      }
    } catch (e) {}

    return map;
  }

  dynamic _jsValueToDart(JSAny? value) {
    if (value == null) return null;

    try {
      if (value.typeofEquals('string')) {
        return (value as JSString).toDart;
      } else if (value.typeofEquals('number')) {
        return (value as JSNumber).toDartDouble;
      } else if (value.typeofEquals('boolean')) {
        return (value as JSBoolean).toDart;
      } else if (value.typeofEquals('object')) {
        final isArray = (web.window as JSObject)['Array'.toJS] as JSObject;
        final isArrayMethod = isArray['isArray'.toJS] as JSFunction;
        final isArrayResult = isArrayMethod.callAsFunction(isArray, value);

        if ((isArrayResult as JSBoolean).toDart) {
          final array = value as JSArray;
          final list = <dynamic>[];
          final length = (array.length as JSNumber).toDartInt;
          for (var i = 0; i < length; i++) {
            list.add(_jsValueToDart(array[i]));
          }
          return list;
        } else {
          return _jsObjectToMap(value as JSObject);
        }
      }
    } catch (e) {}

    return null;
  }
}

@JS('eval')
external JSAny _eval(String code);

JSAny _callConstructor(JSFunction constructor, JSAny config) {
  final windowObj = web.window as JSObject;
  windowObj['_tempConstructor'.toJS] = constructor;
  windowObj['_tempConfig'.toJS] = config;

  final result = _eval('new window._tempConstructor(window._tempConfig)');

  windowObj['_tempConstructor'.toJS] = null;
  windowObj['_tempConfig'.toJS] = null;

  return result;
}

extension JSObjectExtension on JSObject {
  external JSAny? operator [](JSAny property);
  external void operator []=(JSAny property, JSAny? value);
}
