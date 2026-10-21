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
## Highest level with content; never above the hull's. M1 = 1, MVP = 3.
@export_range(1, 3) var authored_up_to_level: int = 1


func get_level(n: int) -> ShipPartLevel:
	if levels.is_empty():
		return null
	return levels[clampi(n, 1, mini(authored_up_to_level, levels.size())) - 1]


## Highest level the ship can reach with this part (authored and present).
func get_max_level() -> int:
	return clampi(mini(authored_up_to_level, levels.size()), 1, ShipHullDefinition.MAX_PART_LEVEL)


static func slot_key(value: Slot) -> StringName:
	return SLOT_KEYS[value]


static func make_id(value: Slot, owner_hull_id: StringName) -> StringName:
	return StringName("%s_%s" % [SLOT_KEYS[value], owner_hull_id])
