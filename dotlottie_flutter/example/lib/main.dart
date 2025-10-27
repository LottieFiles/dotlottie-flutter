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
  final String _platformVersion = 'Unknown';
  DotLottieViewController? _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('DotLottie Flutter Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              const SizedBox(height: 20),

              Container(
                width: 300,
                height: 300,
                color: Colors.grey[200],
                child: DotLottieView(
                  sourceType: 'url',
                  source:
                      'https://lottie.host/ffdc2f29-c7c1-462a-9016-94147dea7f41/DRuFOP07CT.lottie',
                  autoplay: true,
                  loop: true,
                  speed: 1.0,
                  onViewCreated: (controller) {
                    setState(() {
                      _controller = controller;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),
              const Text('Animation should appear above'),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _controller != null
                    ? () async {
                        final result = await _controller!.stateMachineLoad(
                          'StateMachine1',
                        );
                        if (result == true) {
                          await _controller!.stateMachineStart();
                          print('State machine loaded and started');
                        }
                      }
                    : null,
                child: const Text('Load & Start state machine'),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _controller != null
                    ? () async {
                        await _controller!.play();
                      }
                    : null,
                child: const Text('Play'),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _controller != null
                    ? () async {
                        await _controller!.pause();
                      }
                    : null,
                child: const Text('Pause'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
