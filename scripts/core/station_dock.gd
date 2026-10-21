class_name StationDock
extends Node3D
## Station root (scenes/world/station.tscn, MVP exception path).
## Model: assets/models/stations/station_01.glb (placeholder primitives when
## missing). Only the hub collides (station_01_collision.glb convex hull); the
## deck, ring and pad sit below the play plane (Y = 0) and the ship flies over
## them. Dock area: cylinder of dock_radius around the Dock_Center empty.
## Ship inside = docked: EventBus.dock_entered / dock_exited. The station panel
## is UI (EventBus.station_panel_toggled); upgrades check GameState.docked.
## Empties read by name: Dock_Center, Dock_Pad_0, Dock_Entrance, Beacon_Light.

signal docked_changed(docked: bool)

const PHYSICS_LAYER_PLAYER := 1
const PHYSICS_LAYER_WORLD := 64 ## layer 7 "world"
const MODEL_PATH := "res://assets/models/stations/station_01.glb"
const HUB_RADIUS := 1.84 ## placeholder hub, matches the modeler hull

@export var dock_radius: float = 5.0
## Optional override of the model; empty = MODEL_PATH.
@export_file("*.glb", "*.tscn") var model_scene_path: String = ""

var docked: bool = false
var dock_area: Area3D
var model: Node3D
var is_placeholder: bool = false


func _ready() -> void:
	add_to_group(&"stations")
	var path := model_scene_path if model_scene_path != "" else MODEL_PATH
	model = ModelUtil.instance_model(path)
	if model == null:
		model = _build_placeholder()
		is_placeholder = true
	model.name = "Visual"
	add_child(model)

	var hub := StaticBody3D.new()
	hub.name = "Hub"
	hub.collision_layer = PHYSICS_LAYER_WORLD
	hub.collision_mask = 0
	var col := ModelUtil.convex_collision(ModelUtil.collision_path_for(path)) if not is_placeholder else null
	if col == null:
		var shape := CylinderShape3D.new()
		shape.radius = HUB_RADIUS
		shape.height = 3.0
		col = CollisionShape3D.new()
		col.shape = shape
	hub.add_child(col)
	add_child(hub)

	dock_area = Area3D.new()
	dock_area.name = "DockArea"
	dock_area.position = get_marker_local(&"Dock_Center", Vector3.ZERO)
	dock_area.position.y = 0.0
	dock_area.collision_layer = 0
	dock_area.collision_mask = PHYSICS_LAYER_PLAYER
	dock_area.monitorable = false
	var area_shape := CylinderShape3D.new()
	area_shape.radius = dock_radius
	area_shape.height = 4.0
	var area_col := CollisionShape3D.new()
	area_col.shape = area_shape
	dock_area.add_child(area_col)
	add_child(dock_area)
	dock_area.body_entered.connect(_on_body_entered)
	dock_area.body_exited.connect(_on_body_exited)

	var beacon := OmniLight3D.new()
	beacon.name = "BeaconLight"
	beacon.position = get_marker_local(&"Beacon_Light", Vector3(0.0, 2.45, 0.0))
	beacon.light_color = Color(1.0, 0.62, 0.32)
	beacon.light_energy = 2.0
	beacon.omni_range = 8.0
	add_child(beacon)


## Position of a named empty relative to the station root (fallback when absent).
func get_marker_local(marker_name: StringName, fallback: Vector3) -> Vector3:
	var m := model.find_child(String(marker_name), true, false) as Node3D if model != null else null
	if m == null:
		return fallback
	return ModelUtil.relative_transform(m, self).origin


## World position of the dock centre (HUD markers, autopilot, tests).
func get_dock_position() -> Vector3:
	return to_global(get_marker_local(&"Dock_Center", Vector3.ZERO))


func get_dock_pad_position() -> Vector3:
	return to_global(get_marker_local(&"Dock_Pad_0", Vector3(0.0, 0.0, -3.0)))


func get_entrance_position() -> Vector3:
	return to_global(get_marker_local(&"Dock_Entrance", Vector3(0.0, 0.0, -6.5)))


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
	if _is_player(body):
		set_docked(true)


func _on_body_exited(body: Node3D) -> void:
	if _is_player(body):
		set_docked(false)


static func _is_player(body: Node3D) -> bool:
	return body is ShipController or body.is_in_group(&"player")


## Primitive stand-in with the same empties: hub above the play plane, deck and
## ring below it, dock entrance on -Z.
func _build_placeholder() -> Node3D:
	var root := Node3D.new()
	var hub := CylinderMesh.new()
	hub.top_radius = HUB_RADIUS * 0.8
	hub.bottom_radius = HUB_RADIUS
	hub.height = 3.0
	_add_mesh(root, hub, Color(0.93, 0.9, 0.84), Vector3(0.0, 0.2, 0.0))
	var deck := CylinderMesh.new()
	deck.top_radius = dock_radius + 0.3
	deck.bottom_radius = dock_radius + 0.3
	deck.height = 0.2
	_add_mesh(root, deck, Color(0.36, 0.42, 0.52), Vector3(0.0, -0.6, 0.0))
	var ring := TorusMesh.new()
	ring.inner_radius = 6.4
	ring.outer_radius = 6.9
	_add_mesh(root, ring, Color(0.75, 0.72, 0.68), Vector3(0.0, -0.35, 0.0))
	var rim := TorusMesh.new()
	rim.inner_radius = dock_radius - 0.12
	rim.outer_radius = dock_radius
	_add_mesh(root, rim, Color(0.35, 0.85, 1.0), Vector3(0.0, -0.45, 0.0), true)
	var markers: Dictionary[String, Vector3] = {
		"Dock_Center": Vector3.ZERO, "Dock_Pad_0": Vector3(0.0, 0.0, -3.0),
		"Dock_Entrance": Vector3(0.0, 0.0, -6.5), "Beacon_Light": Vector3(0.0, 2.45, 0.0),
	}
	for marker_name: String in markers:
		var m := Marker3D.new()
		m.name = marker_name
		m.position = markers[marker_name]
		root.add_child(m)
	return root


static func _add_mesh(parent: Node3D, mesh: PrimitiveMesh, color: Color, pos: Vector3, emissive: bool = false) -> void:
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
	parent.add_child(mi)
