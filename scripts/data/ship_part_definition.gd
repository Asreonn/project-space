class_name ShipPartDefinition
extends Resource
## A Head / Body / Wings / Engine part that belongs to exactly one hull.
## Parts are never shared or swapped between hulls (GAME_PLAN v0.2 §4.3).
## Stored as res://data/parts/<part>_<hull_id>.tres with L1-L3 as sub-resources.

enum Slot { HEAD, BODY, WINGS, ENGINE }

## Lowercase key per slot, used by ShipInstanceState.part_levels and file names.
const SLOT_KEYS: Array[StringName] = [&"head", &"body", &"wings", &"engine"]

@export var id: StringName ## <part>_<hull_id>, e.g. head_starter_shuttle_01
@export var hull_id: StringName ## Single owner; must equal the owning hull's id.
@export var slot: Slot
@export var display_name: String
## Exactly 3 entries, ordered L1, L2, L3.
@export var levels: Array[ShipPartLevel] = []


func get_level(n: int) -> ShipPartLevel:
	if levels.is_empty():
		return null
	return levels[clampi(n, 1, levels.size()) - 1]


static func slot_key(value: Slot) -> StringName:
	return SLOT_KEYS[value]


static func make_id(value: Slot, owner_hull_id: StringName) -> StringName:
	return StringName("%s_%s" % [SLOT_KEYS[value], owner_hull_id])
