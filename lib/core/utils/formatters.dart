import 'package:intl/intl.dart';

final NumberFormat _currency = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
);

final DateFormat _mediumDate = DateFormat.yMMMd('en_US');
final DateFormat _dayMonth = DateFormat('EEE, MMM d', 'en_US');

/// `$149.00`
String formatPrice(double value) => _currency.format(value);

/// `Aug 10, 2026`
String formatDate(DateTime value) => _mediumDate.format(value);

/// `Thu, Aug 14`
String formatDeliveryDate(DateTime value) => _dayMonth.format(value);

/// Compacts large review counts: `1.2k`.
String formatCount(int value) {
  if (value < 1000) return '$value';
  return '${(value / 1000).toStringAsFixed(1)}k';
}
