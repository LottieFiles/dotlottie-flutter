import 'dotlottie_flutter_platform_interface.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class DotLottieView extends StatelessWidget {
  final String sourceType;
  final String source;
  final bool autoplay;
  final bool loop;
  final double speed;

  const DotLottieView({
    Key? key,
    required this.sourceType,
    required this.source,
    this.autoplay = true,
    this.loop = true,
    this.speed = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'dotlottie_view';

    // Pass parameters to the platform view.
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'sourceType': sourceType,
      'source': source,
      'autoplay': autoplay,
      'loop': loop,
      'speed': speed,
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Text('$defaultTargetPlatform is not yet supported');
  }
}

class DotLottieFlutter {
  void Function()? onLoad;
  void Function()? onLoadError;
  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onStop;
  void Function()? onComplete;
  void Function()? onLoop;
  void Function(double frame)? onFrame;

  DotLottieFlutter() {
    // Set up the event handlers from the platform interface
    DotLottieFlutterPlatform.instance.setEventHandlers(
      onLoad: () => onLoad?.call(),
      onLoadError: () => onLoadError?.call(),
      onPlay: () => onPlay?.call(),
      onPause: () => onPause?.call(),
      onStop: () => onStop?.call(),
      onComplete: () => onComplete?.call(),
      onLoop: () => onLoop?.call(),
      onFrame: (frame) => onFrame?.call(frame),
    );
  }

  Future<String?> getPlatformVersion() {
    return DotLottieFlutterPlatform.instance.getPlatformVersion();
  }

  Future<void> createPlayer() async {
    return DotLottieFlutterPlatform.instance.createPlayer();
  }

  Future<void> loadAnimation({
    required String sourceType,
    required String source,
    bool autoplay = true,
    bool loop = true,
    double speed = 1.0,
  }) {
    return DotLottieFlutterPlatform.instance.loadAnimation(
      sourceType: sourceType,
      source: source,
      autoplay: autoplay,
      loop: loop,
      speed: speed,
    );
  }

  Future<void> play() async {
    return DotLottieFlutterPlatform.instance.play();
  }

  Future<void> pause() async {
    return DotLottieFlutterPlatform.instance.pause();
  }

  Future<void> stop() async {
    return DotLottieFlutterPlatform.instance.stop();
  }

  Future<void> setSpeed(double speed) async {
    return DotLottieFlutterPlatform.instance.setSpeed(speed);
  }

  Future<void> setLoop(bool loop) async {
    return DotLottieFlutterPlatform.instance.setLoop(loop);
  }

  Future<double?> getCurrentFrame() async {
    return DotLottieFlutterPlatform.instance.getCurrentFrame();
  }

  Future<double?> getTotalFrames() async {
    return DotLottieFlutterPlatform.instance.getTotalFrames();
  }

  Future<bool?> isPlaying() async {
    return DotLottieFlutterPlatform.instance.isPlaying();
  }

  Future<bool?> isPaused() async {
    return DotLottieFlutterPlatform.instance.isPaused();
  }
}
