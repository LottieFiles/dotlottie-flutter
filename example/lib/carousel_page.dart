import 'package:flutter/material.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';

const _animations = [
  (
    url:
        'https://assets.tickertape.in/lottie/assetLandingPage/diversification_score.lottie',
    label: 'Diversification Score',
  ),
  (
    url:
        'https://assets.tickertape.in/lottie/assetLandingPage/alerts_on_investment.lottie',
    label: 'Alerts on Investment',
  ),
  (
    url:
        'https://assets.tickertape.in/lottie/assetLandingPage/compare_XIRR.lottie',
    label: 'Compare XIRR',
  ),
  (
    url:
        'https://assets.tickertape.in/lottie/assetLandingPage/forecast.lottie',
    label: 'Forecast',
  ),
  (
    url:
        'https://assets.tickertape.in/lottie/assetLandingPage/red_flags.lottie',
    label: 'Red Flags',
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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageKeys = List.generate(
      _animations.length,
      (_) => GlobalKey<_AnimationPageState>(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _pageKeys[_currentPage].currentState?.pause();
    _pageKeys[index].currentState?.play();
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation Carousel')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
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
          ),
          _PageIndicator(count: _animations.length, current: _currentPage),
          const SizedBox(height: 32),
        ],
      ),
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
