import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/pill.dart';

/// Auto-advancing promo banner at the top of Home.
///
/// Pauses while the shopper is dragging so it never yanks the page out from
/// under a deliberate swipe.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({required this.products, super.key});

  final List<Product> products;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  static const Duration _interval = Duration(seconds: 5);

  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.products.length < 2) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final int next = (_index + 1) % widget.products.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 210,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _timer?.cancel();
              } else if (notification is ScrollEndNotification) {
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int i) => setState(() => _index = i),
              itemCount: widget.products.length,
              itemBuilder: (BuildContext context, int index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _Banner(product: widget.products[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < widget.products.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: i == _index ? 22 : 6,
                decoration: BoxDecoration(
                  color: i == _index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Material(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: () => context.push(Routes.product(product.id)),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -18,
              top: -10,
              bottom: -10,
              width: 190,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      scheme.primaryContainer,
                      scheme.primaryContainer.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: AppImage(url: product.thumbnail, fit: BoxFit.contain),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const <double>[0.0, 0.55, 1.0],
                    colors: <Color>[
                      scheme.primaryContainer,
                      scheme.primaryContainer.withValues(alpha: 0.92),
                      scheme.primaryContainer.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 128, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Pill(
                    label: product.isOnSale
                        ? 'SAVE ${product.discountPercent}%'
                        : 'EDITOR’S PICK',
                    background: product.isOnSale
                        ? AppTheme.accent
                        : scheme.onPrimaryContainer,
                    foreground: product.isOnSale
                        ? Colors.white
                        : scheme.primaryContainer,
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'From ${formatPrice(product.price)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Shop now',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: scheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
