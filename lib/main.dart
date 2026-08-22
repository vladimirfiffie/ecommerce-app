import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/app_providers.dart';
import 'state/notifications_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation is deliberately unrestricted: the layout adapts to landscape
  // and to tablet widths, so locking it would throw that away.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Month and weekday names for every locale `intl` knows. Without this,
  // formatting a date in anything but the default locale throws.
  await initializeDateFormatting();

  // Read preferences once up front so the whole settings/cart/favorites layer
  // can stay synchronous.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Register notification channels up front. Permission is only requested
  // when the shopper opts in from Settings — prompting at first launch, before
  // they've seen anything, is how you get denied permanently.
  unawaited(container.read(notificationsProvider).ensureInitialized());

  runApp(
    UncontrolledProviderScope(container: container, child: const AsterApp()),
  );
}
