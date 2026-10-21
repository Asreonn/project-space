class_name StationDock
extends Node3D
## Station root (scenes/world/station.tscn, MVP exception path). Builds the
## station placeholder (ring + boxes) unless a modeler scene is set, a solid
## core the ship bumps into, and the dock Area3D. Ship inside the dock area =
## docked: EventBus.dock_entered / dock_exited. The station panel itself is UI
## (EventBus.station_panel_toggled); upgrades check GameState.docked.
## Dock centre: the model's Dock_Center empty when present, else dock_offset.

signal docked_changed(docked: bool)

const PHYSICS_LAYER_PLAYER := 1
const PHYSICS_LAYER_WORLD := 64 ## layer 7 "world"

@export var dock_radius: float = 5.0
@export var dock_offset: Vector3 = Vector3(0.0, 0.0, 11.0)
@export var core_radius: float = 7.0 ## station is 12-16 m across (mvp.md §3)
## Optional modeler scene; empty / missing = primitive placeholder.
@export_file("*.glb", "*.tscn") var model_scene_path: String = "res://assets/models/station/station_01.glb"

var docked: bool = false
var dock_area: Area3D


func _ready() -> void:
	add_to_group(&"stations")
	var model := _build_visual()
	var dock_center := model.find_child("Dock_Center", true, false) as Node3D if model != null else null
	var dock_pos := dock_offset
	if dock_center != null:
		dock_pos = dock_center.global_position - global_position
		dock_pos.y = 0.0

	var body := StaticBody3D.new()
	body.name = "Core"
	body.collision_layer = PHYSICS_LAYER_WORLD
	body.collision_mask = 0
	var body_shape := CylinderShape3D.new()
	body_shape.radius = core_radius * 0.75
	body_shape.height = 4.0
	var body_col := CollisionShape3D.new()
	body_col.shape = body_shape
	body.add_child(body_col)
	add_child(body)

	dock_area = Area3D.new()
	dock_area.name = "DockArea"
	dock_area.position = dock_pos
	dock_area.collision_layer = 0
	dock_area.collision_mask = PHYSICS_LAYER_PLAYER
	dock_area.monitorable = false
	var shape := SphereShape3D.new()
	shape.radius = dock_radius
	var col := CollisionShape3D.new()
	col.shape = shape
	dock_area.add_child(col)
	add_child(dock_area)
	dock_area.body_entered.connect(_on_body_entered)
	dock_area.body_exited.connect(_on_body_exited)
	if model == null or model.has_meta(&"ps_placeholder"):
		_add_dock_pad(dock_pos)


func get_dock_position() -> Vector3:
	return dock_area.global_position if dock_area != null and dock_area.is_inside_tree() else global_position + dock_offset


func set_docked(value: bool) -> void:
	if value == docked:
		return
	docked = value
	if docked:
		EventBus.dock_entered.emit()
	else:
		EventBus.dock_exited.emit()
	docked_changed.emit(docked)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player_ship"):
		set_docked(true)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(&"player_ship"):
		set_docked(false)


func _build_visual() -> Node3D:
	if model_scene_path != "" and ResourceLoader.exists(model_scene_path):
		var packed := load(model_scene_path) as PackedScene
		var model := packed.instantiate() as Node3D if packed != null else null
		if model != null:
			model.name = "Visual"
			add_child(model)
			return model
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.set_meta(&"ps_placeholder", true)
	add_child(visual)
	var core := CylinderMesh.new()
	core.top_radius = core_radius * 0.55
	core.bottom_radius = core_radius * 0.7
	core.height = 2.4
	_add_mesh(visual, core, Color(0.93, 0.9, 0.84), Vector3.ZERO, Vector3.ZERO)
	var ring := TorusMesh.new()
	ring.inner_radius = core_radius - 0.9
	ring.outer_radius = core_radius
	_add_mesh(visual, ring, Color(0.36, 0.55, 0.78), Vector3(0.0, 0.2, 0.0), Vector3.ZERO)
	for i in 2:
		var arm := BoxMesh.new()
		arm.size = Vector3(0.7, 0.5, core_radius * 2.0)
		_add_mesh(visual, arm, Color(0.75, 0.72, 0.68), Vector3(0.0, 0.5, 0.0), Vector3(0.0, PI / 4.0 + i * PI / 2.0, 0.0))
	var top := BoxMesh.new()
	top.size = Vector3(2.0, 1.2, 2.0)
	_add_mesh(visual, top, Color(1.0, 0.62, 0.32), Vector3(0.0, 1.6, 0.0), Vector3.ZERO)
	return visual


func _add_dock_pad(pos: Vector3) -> void:
	var pad := TorusMesh.new()
	pad.inner_radius = dock_radius - 0.2
	pad.outer_radius = dock_radius
	var mi := _add_mesh(self, pad, Color(1.0, 0.62, 0.32), pos + Vector3(0.0, -0.6, 0.0), Vector3.ZERO, true)
	mi.name = "DockPadPlaceholder"


static func _add_mesh(parent: Node3D, mesh: PrimitiveMesh, color: Color, pos: Vector3, rot: Vector3, emissive: bool = false) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi
