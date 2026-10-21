class_name ResourceDefinition
extends Resource
## A cargo item (ore, crystal, liquid, gas). Proposal in m1_mining.json "resources";
## sell_price is an MVP addition (station sells for credits).

enum Phase { SOLID, LIQUID, GAS }

@export var id: StringName ## e.g. ore_common_solid
@export var display_name: String
@export var phase: Phase = Phase.SOLID
@export var grade: Grade.Value = Grade.Value.E
@export var volume_per_unit: float = 1.0 ## u per unit
@export var mass_per_unit: float = 0.1 ## t per unit
@export var sell_price: int = 0 ## credits per unit at the station (MVP)
@export var pickup_color: Color = Color(0.85, 0.7, 0.45) ## placeholder pickup tint
## Modeler pickup model (assets/models/pickups/*.glb); empty / missing = tinted cube.
@export_file("*.glb", "*.tscn") var pickup_scene_path: String = ""
@export var balance_prototype: bool = true


static func phase_key(value: Phase) -> StringName:
	match value:
		Phase.LIQUID:
			return ShipStat.STORAGE_LIQUID
		Phase.GAS:
			return ShipStat.STORAGE_GAS
	return ShipStat.STORAGE_SOLID
