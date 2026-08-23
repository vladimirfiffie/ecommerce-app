import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// A page that wears the platform's own chrome.
///
/// On Android this is the Scaffold and AppBar it has always been — passed
/// straight through, so the theme's app-bar styling, the two-pane layouts and
/// every widget test that reaches for a [Scaffold] still find one. On iOS the
/// package builds a Cupertino navigation bar instead, with the large-title
/// collapse and the back-swipe that come with it.
///
/// Screens keep handing in Material [AppBar] actions rather than the package's
/// own action type: they are [IconButton]s carrying tooltips and semantics the
/// app has already got right, and the Cupertino side takes them as widgets.
class AdaptiveScreen extends StatelessWidget {
  const AdaptiveScreen({
    required this.title,
    required this.body,
    super.key,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.bottomBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.materialAppBar,
    this.extendBodyBehindAppBar = false,
  });

  /// Plain text, because that is what a Cupertino navigation bar renders as a
  /// large title. A screen whose bar holds something else passes
  /// [titleWidget] as well, and this stays as the name iOS falls back to.
  final String title;

  /// A widget to draw in place of [title] where the platform can take one —
  /// the search field, for instance.
  final Widget? titleWidget;

  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  /// A bar pinned to the bottom of the page for as long as it is open.
  ///
  /// Not [AdaptiveScaffold.bottomNavigationBar], which only takes the
  /// package's own navigation bar — this is for a page's own action bar, like
  /// checkout's pay button. Laid into the body so it sits above the keyboard
  /// and inside the safe area, which is what Scaffold's own slot was doing.
  final Widget? bottomBar;

  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;

  /// A bar built by the caller, for the ones the platform can't express —
  /// transparent over imagery, its own colours. iOS still gets a Cupertino
  /// bar built from [title] and [actions].
  final PreferredSizeWidget? materialAppBar;

  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) => AdaptiveScaffold(
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    floatingActionButton: floatingActionButton,
    extendBodyBehindAppBar: extendBodyBehindAppBar,
    appBar: AdaptiveAppBar(
      title: title,
      titleWidget: titleWidget,
      appBar:
          materialAppBar ??
          AppBar(
            title: titleWidget ?? Text(title),
            titleSpacing: titleWidget == null ? null : 0,
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            bottom: bottom,
          ),
    ),
    body: bottomBar == null
        ? body
        : Column(
            children: <Widget>[
              Expanded(child: body),
              SafeArea(top: false, child: bottomBar!),
            ],
          ),
  );
}
