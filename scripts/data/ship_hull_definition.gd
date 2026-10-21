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
@export var hardpoints: Array[StringName] = [] ## Hardpoint_<id> on the body: [&"L", &"R"], &"Nose" optional.
## Highest level with content (models, costs, values). M1 = 1, MVP = 3 (D-011).
## Missing data above it is a warning, not an error.
@export_range(1, 3) var authored_up_to_level: int = 1
## Contract v0.2.1 names this FlightTuningDefinition; the Gameplay Designer's
## class is FlightTuning (scripts/data/flight_tuning.gd), used here.
@export var flight_tuning: FlightTuning
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
