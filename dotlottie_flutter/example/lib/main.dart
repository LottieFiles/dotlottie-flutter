import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
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
  String _platformVersion = 'Unknown';
  final _dotLottieFlutterPlugin = DotLottieFlutter();

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

              // Just show the platform view directly - it handles everything
              Container(
                width: 300,
                height: 300,
                color: Colors.grey[200],
                child: const DotLottieView(
                  sourceType: 'url',
                  source:
                      'https://lottie.host/294b684d-d6b4-4116-ab35-85ef566d4379/VkGHcqcMUI.lottie',
                  autoplay: true,
                  loop: true,
                  speed: 1.0,
                ),
              ),

              const SizedBox(height: 20),
              const Text('Animation should appear above'),
            ],
          ),
        ),
      ),
    );
  }
}
