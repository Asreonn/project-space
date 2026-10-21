extends Node3D
## Debug scene: assembles a hull with ShipAssembler on an XZ-locked
## CharacterBody3D and prints the resolved stats. Keys 1-4 (slot_1..slot_4)
## cycle the Head / Body / Wings / Engine level L1 -> L2 -> L3 -> L1.
## Flight and camera are Gameplay Designer work; this only shows assembly.

@export var hull: ShipHullDefinition

@onready var assembler: ShipAssembler = $Ship/Assembler


func _ready() -> void:
	assembler.stats_changed.connect(_on_stats_changed)
	assembler.part_level_changed.connect(_on_part_level_changed)
	assembler.build(hull)
	print("[ShipAssemblyTest] %s parts: %s" % [hull.id, assembler.used_scene_paths])


func _unhandled_input(event: InputEvent) -> void:
	var actions: Array[StringName] = [&"slot_1", &"slot_2", &"slot_3", &"slot_4"]
	var slots: Array[ShipPartDefinition.Slot] = [
		ShipPartDefinition.Slot.HEAD, ShipPartDefinition.Slot.BODY,
		ShipPartDefinition.Slot.WINGS, ShipPartDefinition.Slot.ENGINE,
	]
	for i in actions.size():
		if event.is_action_pressed(actions[i]):
			var key := ShipPartDefinition.slot_key(slots[i])
			var current: int = assembler.state.part_levels.get(key, 1)
			assembler.set_part_level(slots[i], current % ShipHullDefinition.MAX_PART_LEVEL + 1)


func _on_stats_changed(stats: Dictionary) -> void:
	print("[ShipAssemblyTest] stats: %s" % stats)


func _on_part_level_changed(slot: ShipPartDefinition.Slot, level: int) -> void:
	print("[ShipAssemblyTest] %s -> L%d" % [ShipPartDefinition.slot_key(slot), level])
