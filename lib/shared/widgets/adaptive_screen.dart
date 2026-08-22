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
/// Screens keep handing in Material [AppBar] actions rather than the
/// package's own action type: they are [IconButton]s carrying tooltips and
/// semantics that the app has already got right, and the Cupertino side takes
/// them as widgets too.
class AdaptiveScreen extends StatelessWidget {
  const AdaptiveScreen({
    required this.title,
    required this.body,
    super.key,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
  });

  /// Plain text, because that is what a Cupertino navigation bar can render
  /// as a large title. Screens needing a widget for a title keep their own
  /// [Scaffold] — see the ones that put a search field up there.
  final String title;

  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => AdaptiveScaffold(
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    floatingActionButton: floatingActionButton,
    appBar: AdaptiveAppBar(
      title: title,
      actions: null,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
      ),
    ),
    body: body,
  );
}
