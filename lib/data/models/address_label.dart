import 'package:flutter/material.dart';

/// The labels an address is usually given, and the icon that stands for each.
///
/// The label itself stays free text — someone's third address is "The cabin"
/// and no list will ever have it — so these are offered rather than enforced.
/// What they buy is an icon: a saved address is picked out of a list at a
/// glance by its shape long before its street is read.
enum AddressLabel {
  home('Home', Icons.home_rounded),
  work('Work', Icons.business_rounded),
  school('School', Icons.school_rounded),
  gym('Gym', Icons.fitness_center_rounded),
  family('Family', Icons.people_alt_rounded),
  other('Other', Icons.place_rounded);

  const AddressLabel(this.label, this.icon);

  final String label;
  final IconData icon;

  /// The icon for any label, offered or typed.
  ///
  /// Matched case-insensitively so "home" and "Home" are the same door, and
  /// falling back to a plain pin — an address with a name nobody anticipated
  /// still needs something to draw.
  static IconData iconFor(String label) {
    final String needle = label.trim().toLowerCase();
    for (final AddressLabel option in values) {
      if (option.label.toLowerCase() == needle) return option.icon;
    }
    return Icons.place_rounded;
  }

  /// Whether [label] is one of the offered ones, so the picker can show it
  /// selected rather than leaving every chip grey next to a filled field.
  static bool isPreset(String label) => values.any(
    (AddressLabel o) => o.label.toLowerCase() == label.trim().toLowerCase(),
  );
}
