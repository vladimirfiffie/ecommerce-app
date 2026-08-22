import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../state/deals_provider.dart';

/// How often the countdown redraws.
///
/// Set to null by `configureTestEnvironment()`: a repeating timer that calls
/// setState schedules a frame every tick, and `pumpAndSettle` then never
/// settles. Minute precision is all the label shows, so a one-minute tick is
/// as often as it can usefully change.
@visibleForTesting
Duration? dealCountdownTick = const Duration(minutes: 1);

/// Live "ends in …" for the day's deals.
///
/// The deadline is real — the selection rotates at local midnight — which is
/// the only reason this is worth showing. A countdown to nothing is worse
/// than no countdown.
class DealCountdown extends StatefulWidget {
  const DealCountdown({super.key, this.style});

  final TextStyle? style;

  @override
  State<DealCountdown> createState() => _DealCountdownState();
}

class _DealCountdownState extends State<DealCountdown> {
  Timer? _timer;
  late DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final Duration? tick = dealCountdownTick;
    if (tick != null) {
      _timer = Timer.periodic(tick, (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    formatDealsRemaining(_now),
    // A countdown that wraps onto a second line looks broken. Callers put
    // this in tight rows, so it clips rather than reflows.
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: widget.style,
  );
}

/// "Ends in 4h 12m", down to "Ends in under a minute".
///
/// Hours and minutes only: seconds on a deadline this far out are noise, and
/// they'd force a per-second redraw for no information.
String formatDealsRemaining(DateTime now) {
  final Duration left = dealsEndAfter(now).difference(now);
  if (left.isNegative || left == Duration.zero) return 'Ending now';

  final int hours = left.inHours;
  final int minutes = left.inMinutes % 60;

  if (hours > 0) return 'Ends in ${hours}h ${minutes}m';
  if (minutes > 0) return 'Ends in ${minutes}m';
  return 'Ends in under a minute';
}
