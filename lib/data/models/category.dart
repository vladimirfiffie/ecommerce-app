import 'package:material_ui/material_ui.dart';

/// Icon names as the repository emits them, resolved here so the data layer
/// stays free of Flutter types. Kept as a const map for tree-shaking of icons.
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
    required this.iconName,
    required this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    label: json['label'] as String,
    iconName: json['icon'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
  );

  final String id;
  final String label;

  /// Kept as the name rather than the resolved [IconData] so a category can be
  /// written back out again — which is what the offline snapshot needs.
  final String iconName;

  final String imageUrl;

  IconData get icon => _icons[iconName] ?? Icons.category_rounded;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'icon': iconName,
    'imageUrl': imageUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
