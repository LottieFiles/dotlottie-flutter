import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'stats_rss_stub.dart' if (dart.library.io) 'stats_rss_io.dart';

class StatsOverlay extends StatefulWidget {
  const StatsOverlay({super.key});

  @override
  State<StatsOverlay> createState() => _StatsOverlayState();
}

class _StatsOverlayState extends State<StatsOverlay>
    with SingleTickerProviderStateMixin {
  static const _sampleInterval = Duration(milliseconds: 500);

  late final AnimationController _spinner;
  final Stopwatch _elapsed = Stopwatch();
  Timer? _timer;

  int _frames = 0;
  double _fps = 0;
  int _rssMb = 0;

  @override
  void initState() {
    super.initState();
    _spinner = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _elapsed.start();
    _timer = Timer.periodic(_sampleInterval, (_) => _sample());
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _timer?.cancel();
    _spinner.dispose();
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) => _frames += timings.length;

  void _sample() {
    final seconds = _elapsed.elapsedMilliseconds / 1000;
    if (!mounted || seconds <= 0) return;

    setState(() {
      _fps = _frames / seconds;
      _rssMb = currentRssBytes() ~/ (1024 * 1024);
    });

    _frames = 0;
    _elapsed
      ..reset()
      ..start();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatRow(label: 'FPS', value: _fps.toStringAsFixed(1)),
            if (_rssMb > 0) _StatRow(label: 'MEM', value: '$_rssMb MB'),
            const SizedBox(height: 6),
            RotationTransition(
              turns: _spinner,
              child: const Icon(Icons.sync, size: 14, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
