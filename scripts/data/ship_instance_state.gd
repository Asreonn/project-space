class_name ShipInstanceState
extends Resource
## Runtime + save state of one owned ship. Holds no definition data.
## hull_hp, fuel, loadout and cargo live in separate state objects.

@export var hull_id: StringName
@export var part_levels: Dictionary[StringName, int] = {
	&"head": 1, &"body": 1, &"wings": 1, &"engine": 1,
}


func can_upgrade(part: StringName) -> bool:
	return part_levels.get(part, 1) < ShipHullDefinition.MAX_PART_LEVEL


static func create_for(hull: ShipHullDefinition, level: int = 1) -> ShipInstanceState:
	var state := ShipInstanceState.new()
	state.hull_id = hull.id if hull != null else &""
	for key: StringName in ShipPartDefinition.SLOT_KEYS:
		state.part_levels[key] = clampi(level, 1, ShipHullDefinition.MAX_PART_LEVEL)
	return state
