import 'package:flutter/material.dart';

/// Icon names used by `catalog.json`, resolved here so the asset stays
/// free of Flutter types. Kept as a const map for tree-shaking of icons.
const Map<String, IconData> _icons = <String, IconData>{
  'checkroom': Icons.checkroom_rounded,
  'devices': Icons.devices_rounded,
  'spa': Icons.spa_rounded,
  'watch': Icons.watch_rounded,
  'chair': Icons.chair_rounded,
  'sports_tennis': Icons.sports_tennis_rounded,
};

/// A top-level catalog grouping, shown as chips on Home and as a filter.
@immutable
class Category {
  const Category({
    required this.id,
    required this.label,
    required this.icon,
    required this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    label: json['label'] as String,
    icon: _icons[json['icon'] as String] ?? Icons.category_rounded,
    imageUrl: json['imageUrl'] as String? ?? '',
  );

  final String id;
  final String label;
  final IconData icon;
  final String imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
