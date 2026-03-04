import 'package:flutter/material.dart';
import 'cb_neon_background.dart';

/// CBPrismScaffold: Neon-themed scaffold with glowing effects
class CBPrismScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool showAppBar;
  final bool useSafeArea;
  final List<Widget>? actions;
  final Widget? drawer;
  final String? backgroundAsset;
  final String? brandOverlayAsset;
  final bool showBackgroundRadiance;
  final bool showBrandOverlay;
  final double brandOverlayOpacity;
  final double brandOverlayHeight;
  final PreferredSizeWidget? appBarBottom;

  const CBPrismScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.showAppBar = true,
    this.useSafeArea = true,
    this.actions,
    this.drawer,
    this.backgroundAsset,
    this.brandOverlayAsset = 'assets/images/neon_x_brand.png',
    this.showBackgroundRadiance = true,
    this.showBrandOverlay = false,
    this.brandOverlayOpacity = 0.06,
    this.brandOverlayHeight = 280,
    this.appBarBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge!,
              ),
              centerTitle: true,
              actions: actions,
              bottom: appBarBottom,
            )
          : null,
      drawer: drawer,
      body: CBNeonBackground(
        backgroundAsset: backgroundAsset,
        showRadiance: showBackgroundRadiance,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showBrandOverlay && brandOverlayAsset != null)
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: brandOverlayOpacity,
                    child: Image.asset(
                      brandOverlayAsset!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: brandOverlayHeight,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            useSafeArea ? SafeArea(child: body) : body,
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
