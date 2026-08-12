import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';

import 'stats.dart';

class CpuGpuPage extends StatefulWidget {
  const CpuGpuPage({super.key});

  @override
  State<CpuGpuPage> createState() => _CpuGpuPageState();
}

enum _Renderer { cpu, gpu }

class _CpuGpuPageState extends State<CpuGpuPage> {
  _Renderer _renderer = _Renderer.cpu;
  DotLottieViewController? _controller;
  String? _activeRenderer;

  bool get _wantsGpu => _renderer == _Renderer.gpu;

  String? get _gpuBackend => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'OpenGL',
    TargetPlatform.iOS || TargetPlatform.macOS => 'WebGPU (Metal)',
    _ => null,
  };

  Future<void> _readActiveRenderer() async {
    final renderer = await _controller?.renderer();
    if (!mounted) return;
    setState(() => _activeRenderer = renderer);
  }

  void _select(_Renderer renderer) {
    if (renderer == _renderer) return;
    setState(() {
      _renderer = renderer;
      _controller = null;
      _activeRenderer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('CPU vs GPU')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DotLottieView(
                    key: ValueKey(_renderer),
                    sourceType: 'asset',
                    source: 'adding-guests.lottie',
                    autoplay: true,
                    loop: true,
                    fit: BoxFit.contain,
                    useOpenGL: _wantsGpu,
                    useWebGPU: _wantsGpu,
                    onViewCreated: (controller) => _controller = controller,
                    onLoad: _readActiveRenderer,
                  ),
                ),
                const Positioned(top: 12, right: 12, child: StatsOverlay()),
              ],
            ),
          ),
          _Controls(
            renderer: _renderer,
            gpuBackend: _gpuBackend,
            activeRenderer: _activeRenderer,
            onSelect: _select,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.renderer,
    required this.gpuBackend,
    required this.activeRenderer,
    required this.onSelect,
  });

  final _Renderer renderer;
  final String? gpuBackend;
  final String? activeRenderer;
  final ValueChanged<_Renderer> onSelect;

  @override
  Widget build(BuildContext context) {
    final status = switch (activeRenderer) {
      final String active => 'active: $active',
      _ when gpuBackend == null => 'GPU rendering is unavailable on this platform',
      _ => 'GPU: $gpuBackend',
    };

    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Builder(
        builder: (context) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<_Renderer>(
                  segments: [
                    const ButtonSegment(
                      value: _Renderer.cpu,
                      label: Text('CPU'),
                      icon: Icon(Icons.memory),
                    ),
                    ButtonSegment(
                      value: _Renderer.gpu,
                      label: const Text('GPU'),
                      icon: const Icon(Icons.speed),
                      enabled: gpuBackend != null,
                    ),
                  ],
                  selected: {renderer},
                  onSelectionChanged: (selection) => onSelect(selection.first),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
