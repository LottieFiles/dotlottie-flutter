import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';

const _animations = [
  (
    url:
        'https://lottie.host/f667bc2d-f0e2-47d5-8021-dc3473f31f7d/hcK2nKmaPp.lottie',
    label: 'Smiley Slider',
  ),
  (
    url:
        'https://lottie.host/37cfaf9d-6805-4d77-a4d1-a44c2c66e340/e41cghHS0p.lottie',
    label: 'Star rating',
  ),
  (
    url:
        'https://lottie.host/749236ba-351e-49f6-9ed0-b88d8c5ce023/6nY3dSYtwx.lottie',
    label: 'Snow globe',
  ),
  (
    url:
        'https://lottie.host/6b7b97ab-b440-4bc6-844a-1c863c0fe118/Ofg3beI37F.lottie',
    label: 'Car',
  ),
  (
    url:
        'https://lottie.host/76229bd4-4e2c-4718-9737-fa8b8bedae29/qqaRzSPO8n.lottie',
    label: 'Lolo',
  ),
];

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  late final PageController _pageController;
  late final List<GlobalKey<_AnimationPageState>> _pageKeys;
  late final FocusNode _focusNode;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _focusNode = FocusNode();
    _pageKeys = List.generate(
      _animations.length,
      (_) => GlobalKey<_AnimationPageState>(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _pageKeys[_currentPage].currentState?.pause();
    _pageKeys[index].currentState?.play();
    setState(() => _currentPage = index);
  }

  void _goTo(int index) {
    if (index < 0 || index >= _animations.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _goTo(_currentPage - 1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _goTo(_currentPage + 1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation Carousel')),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) => _handleKey(_focusNode, event),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _animations.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final anim = _animations[index];
                      return _AnimationPage(
                        key: _pageKeys[index],
                        url: anim.url,
                        label: anim.label,
                      );
                    },
                  ),
                  Positioned(
                    left: 8,
                    child: _NavButton(
                      icon: Icons.chevron_left,
                      onPressed:
                          _currentPage > 0 ? () => _goTo(_currentPage - 1) : null,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: _NavButton(
                      icon: Icons.chevron_right,
                      onPressed: _currentPage < _animations.length - 1
                          ? () => _goTo(_currentPage + 1)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            _PageIndicator(count: _animations.length, current: _currentPage),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 32,
    );
  }
}

class _AnimationPage extends StatefulWidget {
  const _AnimationPage({
    super.key,
    required this.url,
    required this.label,
  });

  final String url;
  final String label;

  @override
  State<_AnimationPage> createState() => _AnimationPageState();
}

// AutomaticKeepAliveClientMixin keeps the platform view (UiKitView / AndroidView)
// alive when pages scroll off-screen, preventing the native view from being torn
// down and recreated — which crashes dotlottie-ios when views aren't held by
// reference between renders.
class _AnimationPageState extends State<_AnimationPage>
    with AutomaticKeepAliveClientMixin {
  DotLottieViewController? _controller;

  @override
  bool get wantKeepAlive => true;

  void play() => _controller?.play();
  void pause() => _controller?.pause();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DotLottieView(
              sourceType: 'url',
              source: widget.url,
              autoplay: true,
              loop: true,
              fit: BoxFit.contain,
              onViewCreated: (controller) {
                _controller = controller;
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == current ? primary : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
