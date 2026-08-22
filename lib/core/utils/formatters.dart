import 'package:intl/intl.dart';

/// Money and dates, formatted for whatever locale the app is running in.
///
/// The locale comes from [Intl.defaultLocale], which `AsterApp` sets from the
/// active [Locale] on every build. Formatters are rebuilt when it changes and
/// cached per locale — constructing a `NumberFormat` is not free, and prices
/// are formatted several times per frame in a grid.
///
/// Prices are in US dollars because that's what the product feed quotes, and
/// converting them would need exchange rates the app doesn't have. What does
/// change with locale is how the amount is *written*: `$1,299.00` in the US,
/// `1 299,00 $US` in France. The number is the same number.
const String kCurrencyCode = 'USD';

String get _locale => Intl.defaultLocale ?? 'en_US';

final Map<String, NumberFormat> _currencyCache = <String, NumberFormat>{};
final Map<String, DateFormat> _mediumDateCache = <String, DateFormat>{};
final Map<String, DateFormat> _dayMonthCache = <String, DateFormat>{};
final Map<String, DateFormat> _timeCache = <String, DateFormat>{};

NumberFormat get _currency => _currencyCache.putIfAbsent(
  _locale,
  () => NumberFormat.simpleCurrency(locale: _locale, name: kCurrencyCode),
);

DateFormat get _mediumDate =>
    _mediumDateCache.putIfAbsent(_locale, () => DateFormat.yMMMd(_locale));

DateFormat get _dayMonth =>
    _dayMonthCache.putIfAbsent(_locale, () => DateFormat.MMMEd(_locale));

DateFormat get _time =>
    _timeCache.putIfAbsent(_locale, () => DateFormat.jm(_locale));

/// `$149.00`
String formatPrice(double value) => _currency.format(value);

/// `Aug 10, 2026`
String formatDate(DateTime value) => _mediumDate.format(value);

/// `Thu, Aug 14`
String formatDeliveryDate(DateTime value) => _dayMonth.format(value);

/// `3:04 PM`, or `15:04` where that's how the locale writes it.
String formatTime(DateTime value) => _time.format(value);

/// Compacts large review counts: `1.2K`.
///
/// Held to one decimal place: the default gives three significant digits
/// (`1.23K`), which is more precision than a review count badge wants.
String formatCount(int value) => (NumberFormat.compact(
  locale: _locale,
)..maximumFractionDigits = 1).format(value);

/// Drops every cached formatter. Only needed when the locale changes mid-run,
/// which in practice means a test switching locales.
void resetFormatters() {
  _currencyCache.clear();
  _mediumDateCache.clear();
  _dayMonthCache.clear();
  _timeCache.clear();
}
