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
  List<Map<String, dynamic>>? _stateMachines;
  String? _activeStateMachine;

  // Animation control states
  bool _isPlaying = true;
  double _currentFrame = 0;
  double _totalFrames = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadManifest() async {
    if (_controller != null) {
      final manifest = await _controller!.manifest();
      print(manifest);
      if (manifest != null) {
        // Safely convert the state machines list
        final stateMachinesRaw = manifest['stateMachines'] as List?;
        if (stateMachinesRaw != null) {
          setState(() {
            _stateMachines = stateMachinesRaw.map((sm) {
              // Convert each item to Map<String, dynamic>
              return Map<String, dynamic>.from(sm as Map);
            }).toList();
          });
        }
      }

      // Get initial frame counts
      final total = await _controller!.totalFrames();
      final current = await _controller!.currentFrame();
      if (total != null && current != null) {
        setState(() {
          _totalFrames = total > 0 ? total : 100;
          _currentFrame = current;
        });
      }
    }
  }

  Future<void> _loadAndStartStateMachine(String stateMachineId) async {
    if (_controller != null) {
      final result = await _controller!.stateMachineLoad(stateMachineId);
      if (result == true) {
        await _controller!.stateMachineStart();
        setState(() {
          _activeStateMachine = stateMachineId;
        });
        print('State machine "$stateMachineId" loaded and started');
      }
    }
  }

  Future<void> _stopStateMachine() async {
    if (_controller != null && _activeStateMachine != null) {
      await _controller!.stateMachineStop();
      setState(() {
        _activeStateMachine = null;
      });
      print('State machine stopped');
    }
  }

  Future<void> _handleTotalFrames() async {
    if (_controller != null) {
      var totalFrames = await _controller!.totalFrames();
      if (totalFrames != null) {
        setState(() {
          _totalFrames = totalFrames;
        });
      }
    }
  }

  Future<void> _handlePlay() async {
    if (_controller != null) {
      await _controller!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _handlePause() async {
    if (_controller != null) {
      await _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _handleStop() async {
    if (_controller != null) {
      await _controller!.stop();
      setState(() {
        _isPlaying = false;
        _currentFrame = 0;
      });
    }
  }

  Future<void> _handleSeek(double frame) async {
    if (_controller != null) {
      await _controller!.setFrame(frame);
      setState(() {
        _currentFrame = frame;
      });
    }
  }

  String _formatFrame(double frame) {
    return frame.toInt().toString();
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
                  onViewCreated: (controller) {
                    setState(() {
                      _controller = controller;
                    });
                  },
                  onLoad: () {
                    _loadManifest();
                    _handleTotalFrames();
                  },
                  onFrame: (frameNo) {
                    print(">> Received frame: $frameNo");
                    setState(() {
                      _currentFrame = frameNo;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Display active state machine with stop button
              if (_activeStateMachine != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Active: $_activeStateMachine',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _stopStateMachine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // State Machines List
              if (_stateMachines != null && _stateMachines!.isNotEmpty) ...[
                const Text(
                  'State Machines:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _stateMachines!.map((sm) {
                    final id = sm['id'] as String;
                    final name = sm['name'] as String?;
                    final displayName = name ?? id;
                    final isActive = _activeStateMachine == id;

                    return ElevatedButton(
                      onPressed: () => _loadAndStartStateMachine(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.green : null,
                        foregroundColor: isActive ? Colors.white : null,
                      ),
                      child: Text(displayName),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ] else if (_controller != null) ...[
                const Text('No state machines found'),
                const SizedBox(height: 20),
              ],

              // Animation controls - hidden when state machine is active
              if (_activeStateMachine == null && _controller != null) ...[
                // Scrub bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatFrame(_currentFrame),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _formatFrame(_totalFrames),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8.0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16.0,
                          ),
                        ),
                        child: Slider(
                          value: _currentFrame.clamp(0, _totalFrames),
                          min: 0,
                          max: _totalFrames,
                          onChanged: (value) {
                            setState(() {
                              _currentFrame = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _handleSeek(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stop button
                    IconButton(
                      onPressed: _handleStop,
                      icon: const Icon(Icons.stop),
                      iconSize: 32,
                      tooltip: 'Stop',
                    ),
                    const SizedBox(width: 20),
                    // Play/Pause button
                    IconButton(
                      onPressed: _isPlaying ? _handlePause : _handlePlay,
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 40,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
