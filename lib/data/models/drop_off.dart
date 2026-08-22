import 'package:material_ui/material_ui.dart';

/// What the courier should do when they get there.
///
/// Carries only what is true in any language — an id, an icon, and whether it
/// is the one that needs no explaining. The words live in `enum_labels.dart`,
/// the same as every other enum the shopper reads.
enum DropOff {
  handToMe(id: 'hand', icon: Icons.front_hand_outlined),
  atDoor(id: 'door', icon: Icons.door_front_door_outlined),
  withNeighbour(id: 'neighbour', icon: Icons.people_outline_rounded),
  safePlace(id: 'safe', icon: Icons.inventory_2_outlined);

  const DropOff({required this.id, required this.icon});

  final String id;
  final IconData icon;

  /// The default, and the only one that doesn't change what happens.
  bool get isDefault => this == DropOff.handToMe;

  /// Whether the choice is meaningless for a given delivery method — nobody
  /// leaves a click-and-collect parcel on a doorstep.
  static bool appliesTo(String deliveryId) => deliveryId != 'pickup';

  static DropOff byId(String? id) => values.firstWhere(
    (DropOff d) => d.id == id,
    orElse: () => DropOff.handToMe,
  );

  /// How long a note can be. Long enough for a gate code and a landmark,
  /// short enough that it still fits on a label.
  static const int maxNoteLength = 140;
}
