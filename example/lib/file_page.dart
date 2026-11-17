import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Demonstrates loading a dotLottie/Lottie animation from a local file path
/// picked via the device's file system, using `sourceType: 'file'`.
///
/// The dotLottie manifest only exposes state machine `id`/`name`, not their
/// inputs/transitions, so those are surfaced live as they fire at runtime
/// (via the `stateMachineOn*` callbacks) instead of as a fixed set of buttons.
class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  DotLottieViewController? _controller;
  String? _filePath;
  bool _loaded = false;
  bool _loadError = false;
  String? _activeStateMachine;
  final List<String> _events = [];

  final _fireEventController = TextEditingController();
  final _boolInputController = TextEditingController();
  final _numericInputController = TextEditingController();
  final _stringInputController = TextEditingController();

  @override
  void dispose() {
    _fireEventController.dispose();
    _boolInputController.dispose();
    _numericInputController.dispose();
    _stringInputController.dispose();
    super.dispose();
  }

  void _logEvent(String message) {
    setState(() {
      _events.insert(0, message);
      if (_events.length > 50) _events.removeLast();
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _filePath = path;
      _loaded = false;
      _loadError = false;
      _controller = null;
      _activeStateMachine = null;
      _events.clear();
    });
  }

  // Auto-activate the first state machine declared in the file's manifest, if any.
  Future<void> _loadStateMachineFromManifest() async {
    final controller = _controller;
    if (controller == null) return;

    final manifest = await controller.manifest();
    final stateMachines = manifest?['stateMachines'] as List?;
    if (stateMachines == null || stateMachines.isEmpty) return;

    final id = (stateMachines.first as Map)['id'] as String?;
    if (id == null) return;

    final result = await controller.stateMachineLoad(id);
    if (result == true) {
      await controller.stateMachineStart();
      setState(() => _activeStateMachine = id);
      _logEvent('State machine "$id" loaded and started');
    }
  }

  Widget _inputRow({
    required String label,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onSubmit, child: const Text('Set')),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Pick file'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _filePath ?? 'No file selected',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationView({EdgeInsetsGeometry? margin}) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.blueAccent, width: 1),
      ),
      child: _filePath == null
          ? const Center(child: Text('No file selected'))
          : DotLottieView(
              // Rebuild the platform view whenever a new file is picked.
              key: ValueKey(_filePath),
              sourceType: 'file',
              source: _filePath!,
              autoplay: true,
              loop: true,
              fit: BoxFit.contain,
              onViewCreated: (controller) {
                setState(() {
                  _controller = controller;
                });
              },
              onLoad: () {
                setState(() => _loaded = true);
                _loadStateMachineFromManifest();
              },
              onLoadError: () => setState(() => _loadError = true),
              stateMachineOnStart: () => _logEvent('State machine started'),
              stateMachineOnStop: () => _logEvent('State machine stopped'),
              stateMachineOnError: (message) => _logEvent('Error: $message'),
              stateMachineOnStateEntered: (state) =>
                  _logEvent('Entered state: $state'),
              stateMachineOnStateExit: (state) =>
                  _logEvent('Exited state: $state'),
              stateMachineOnTransition: (from, to) =>
                  _logEvent('Transition: $from -> $to'),
              stateMachineOnInputFired: (name) =>
                  _logEvent('Input fired: $name'),
              stateMachineOnCustomEvent: (message) =>
                  _logEvent('Custom event: $message'),
              stateMachineOnBooleanInputValueChange:
                  (name, oldValue, newValue) =>
                      _logEvent('Bool "$name": $oldValue -> $newValue'),
              stateMachineOnNumericInputValueChange:
                  (name, oldValue, newValue) =>
                      _logEvent('Numeric "$name": $oldValue -> $newValue'),
              stateMachineOnStringInputValueChange:
                  (name, oldValue, newValue) =>
                      _logEvent('String "$name": $oldValue -> $newValue'),
            ),
    );
  }

  Widget _buildLoadError() {
    if (!_loadError) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Failed to load animation',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _loaded ? () => _controller?.play() : null,
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            onPressed: _loaded ? () => _controller?.pause() : null,
            icon: const Icon(Icons.pause),
          ),
          IconButton(
            onPressed: _loaded ? () => _controller?.stop() : null,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }

  Widget _buildStateMachineControls({
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
  }) {
    final activeStateMachine = _activeStateMachine;
    if (activeStateMachine == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'State machine "$activeStateMachine" — send inputs:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _inputRow(
            label: 'Fire event',
            controller: _fireEventController,
            hint: 'event name',
            onSubmit: () {
              final name = _fireEventController.text.trim();
              if (name.isEmpty) return;
              _controller?.stateMachineFire(name);
            },
          ),
          _inputRow(
            label: 'Bool input',
            controller: _boolInputController,
            hint: 'name=true',
            onSubmit: () {
              final parts = _boolInputController.text.split('=');
              if (parts.length != 2) return;
              _controller?.stateMachineSetBooleanInput(
                parts[0].trim(),
                parts[1].trim().toLowerCase() == 'true',
              );
            },
          ),
          _inputRow(
            label: 'Numeric input',
            controller: _numericInputController,
            hint: 'name=1.0',
            onSubmit: () {
              final parts = _numericInputController.text.split('=');
              if (parts.length != 2) return;
              final value = double.tryParse(parts[1].trim());
              if (value == null) return;
              _controller?.stateMachineSetNumericInput(parts[0].trim(), value);
            },
          ),
          _inputRow(
            label: 'String input',
            controller: _stringInputController,
            hint: 'name=value',
            onSubmit: () {
              final parts = _stringInputController.text.split('=');
              if (parts.length != 2) return;
              _controller?.stateMachineSetStringInput(
                parts[0].trim(),
                parts[1].trim(),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Live events:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ..._events.map((e) => Text(e, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildFilePicker(),
        Expanded(flex: 3, child: _buildAnimationView()),
        _buildLoadError(),
        _buildPlaybackControls(),
        if (_activeStateMachine != null)
          Expanded(flex: 2, child: _buildStateMachineControls()),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Column(
      children: [
        _buildFilePicker(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildAnimationView(
                  margin: const EdgeInsets.fromLTRB(12, 0, 6, 12),
                ),
              ),
              SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 12, 12),
                  child: Column(
                    children: [
                      _buildLoadError(),
                      _buildPlaybackControls(),
                      if (_activeStateMachine != null)
                        Expanded(
                          child: _buildStateMachineControls(
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      appBar: AppBar(title: const Text('Load From Local File')),
      body: SafeArea(child: isWide ? _buildWideLayout() : _buildMobileLayout()),
    );
  }
}
