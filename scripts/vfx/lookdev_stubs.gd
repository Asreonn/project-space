class_name VfxLookdevStubs
extends RefCounted
## Tiny stand-ins used only by vfx_lookdev.tscn so the VFX can be checked
## against the real contract without the gameplay scenes.

## Shape of MiningLaser that VfxDirector reads: beam_origin / beam_end (world).
class LaserStub:
	extends Node3D
	var beam_origin: Vector3 = Vector3.ZERO
	var beam_end: Vector3 = Vector3.ZERO
	var firing: bool = false


## Shape of OrePickup: item_id, velocity, group ore_pickups and a `Visual`
## (the model at model_path like OrePickup does, else a placeholder BoxMesh).
class PickupStub:
	extends Node3D
	var item_id: StringName = &""
	var velocity: Vector3 = Vector3.ZERO
	var model_path: String = ""

	func _ready() -> void:
		add_to_group(&"ore_pickups")
		if model_path != "" and ResourceLoader.exists(model_path):
			var model := (load(model_path) as PackedScene).instantiate() as Node3D
			model.name = "Visual"
			add_child(model)
		elif get_node_or_null(^"Visual") == null:
			var mi := MeshInstance3D.new()
			mi.name = "Visual"
			var box := BoxMesh.new()
			box.size = Vector3(0.35, 0.35, 0.35)
			mi.mesh = box
			add_child(mi)
