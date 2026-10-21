class_name ShipHullDefinition
extends Resource
## One ship model. Native grade is fixed; the 4 parts are fixed to this hull.
## Stored as res://data/ships/<hull_id>.tres. Assembly is data-driven in code
## (ShipAssembler); there is no per-hull assembly scene.

const MAX_PART_LEVEL := 3

@export var id: StringName ## e.g. &"starter_shuttle_01"
@export var display_name: String
@export var native_grade: Grade.Value = Grade.Value.E ## Fixed (§5.2).
@export var affinity: Array[StringName] = [] ## Tendency tags, never a class lock (§4.1).
@export var base_stats: Dictionary[StringName, float] = {}
## Natural ceiling inside the native grade. Stats missing here are uncapped.
@export var upgrade_caps: Dictionary[StringName, float] = {}
@export var hardpoints: Array[StringName] = [] ## e.g. [&"hp_left", &"hp_right"]
@export var head: ShipPartDefinition
@export var body: ShipPartDefinition
@export var wings: ShipPartDefinition
@export var engine: ShipPartDefinition


func get_part(slot: ShipPartDefinition.Slot) -> ShipPartDefinition:
	match slot:
		ShipPartDefinition.Slot.HEAD:
			return head
		ShipPartDefinition.Slot.BODY:
			return body
		ShipPartDefinition.Slot.WINGS:
			return wings
		_:
			return engine
