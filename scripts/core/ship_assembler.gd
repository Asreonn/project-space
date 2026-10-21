class_name ShipAssembler
extends Node3D
## Data-driven ship assembly (ship_data_model.md §7). Add as a child of the
## ship body (CharacterBody3D, XZ-locked) and call build(hull, state).
##
## Body is the root part: origin = ship center, carries the empties
## Socket_Head, Socket_Wings, Socket_Engine and Hardpoint_<position>
## (Hardpoint_L, Hardpoint_R, optional Hardpoint_Nose). Head / Wings / Engine
## are instanced at the body's Socket_* transforms. FX_EngineTrail_<n> live on
## the engine, optional FX_MiningOrigin on the head.
##
## set_part_level() swaps only that part's model; a body swap re-seats the
## other parts on the new body's sockets. When a level's scene_path is empty
## or the model is not delivered yet, a generated primitive placeholder with
## the same empties is used, so code and VFX can rely on the names today.

signal assembled
signal part_level_changed(slot: ShipPartDefinition.Slot, level: int)
signal stats_changed(stats: Dictionary)

const SOCKET_PREFIX := "Socket_"
const HARDPOINT_PREFIX := "Hardpoint_"
const ENGINE_TRAIL_PREFIX := "FX_EngineTrail_"
const MINING_ORIGIN := "FX_MiningOrigin"
const PLACEHOLDER_META := &"ps_placeholder"

## Placeholder layout = Docs/contracts/model_anchors.md (starter_shuttle_01,
## frozen for L1-L3), so a placeholder ship is the same 1.84 m as the real one:
## nose tip z = -0.945 (FX_MiningOrigin), engine tail z = +0.90.
const PLACEHOLDER_SOCKETS: Dictionary[String, Vector3] = {
	"Socket_Head": Vector3(0.0, 0.0, -0.05),
	"Socket_Wings": Vector3(0.0, 0.0, 0.20),
	"Socket_Engine": Vector3(0.0, 0.0, 0.55),
}
const PLACEHOLDER_HARDPOINTS: Dictionary[String, Vector3] = {
	"Hardpoint_L": Vector3(-0.31, -0.03, -0.30),
	"Hardpoint_R": Vector3(0.31, -0.03, -0.30),
	"Hardpoint_Nose": Vector3(0.0, 0.02, -1.0),
}
## Ship length (nose tip to engine tail), metres.
const SHIP_LENGTH := 1.84
const COLOR_CREAM := Color(0.96, 0.93, 0.86)
const COLOR_ACCENT := Color(1.0, 0.62, 0.32)

## When true, EventBus.part_upgraded (from GameState.try_upgrade) swaps the
## matching part model. The player ship sets this; debug scenes leave it off.
@export var follow_part_upgrades: bool = false

var hull: ShipHullDefinition
var state: ShipInstanceState
var stats: Dictionary[StringName, float] = {}
## Part root nodes by slot key (&"head", &"body", ...), named Head/Body/Wings/Engine.
var parts: Dictionary[StringName, Node3D] = {}
## Scene path used per slot; "" means a generated placeholder.
var used_scene_paths: Dictionary[StringName, String] = {}


func _ready() -> void:
	if follow_part_upgrades:
		EventBus.part_upgraded.connect(_on_part_upgraded)


func _on_part_upgraded(part: StringName, level: int) -> void:
	var index := ShipPartDefinition.SLOT_KEYS.find(part)
	if index < 0 or hull == null:
		return
	set_part_level(index as ShipPartDefinition.Slot, level)


func build(new_hull: ShipHullDefinition, new_state: ShipInstanceState = null) -> void:
	hull = new_hull
	state = new_state if new_state != null else ShipInstanceState.create_for(new_hull)
	for key: StringName in parts.keys():
		_free_part(key)
	parts.clear()
	used_scene_paths.clear()
	if hull == null:
		push_error("ShipAssembler: hull is null")
		return
	_mount(ShipPartDefinition.Slot.BODY)
	for slot: ShipPartDefinition.Slot in [ShipPartDefinition.Slot.HEAD, ShipPartDefinition.Slot.WINGS, ShipPartDefinition.Slot.ENGINE]:
		_mount(slot)
	_resolve_stats()
	assembled.emit()


## Sets a part level (1..3), swaps that part's model and re-resolves stats.
## Upgrade rules and costs live in UpgradeService.
func set_part_level(slot: ShipPartDefinition.Slot, level: int) -> void:
	if hull == null:
		return
	var key := ShipPartDefinition.slot_key(slot)
	var clamped := clampi(level, 1, ShipHullDefinition.MAX_PART_LEVEL)
	state.part_levels[key] = clamped
	if slot == ShipPartDefinition.Slot.BODY:
		build(hull, state) # sockets may move with the body model
	else:
		_free_part(key)
		_mount(slot)
		_resolve_stats()
	part_level_changed.emit(slot, clamped)


func get_part_node(slot: ShipPartDefinition.Slot) -> Node3D:
	return parts.get(ShipPartDefinition.slot_key(slot), null)


func get_socket(slot: ShipPartDefinition.Slot) -> Node3D:
	var body := get_part_node(ShipPartDefinition.Slot.BODY)
	if body == null or slot == ShipPartDefinition.Slot.BODY:
		return null
	return body.find_child(SOCKET_PREFIX + _node_name(slot), true, false) as Node3D


## mount_position is the <position> of Hardpoint_<position>: &"L", &"R", &"Nose".
func find_hardpoint(mount_position: StringName) -> Node3D:
	var body := get_part_node(ShipPartDefinition.Slot.BODY)
	return body.find_child(HARDPOINT_PREFIX + String(mount_position), true, false) as Node3D if body != null else null


func get_engine_trail_points() -> Array[Node3D]:
	var out: Array[Node3D] = []
	var engine := get_part_node(ShipPartDefinition.Slot.ENGINE)
	if engine == null:
		return out
	for n in engine.find_children(ENGINE_TRAIL_PREFIX + "*", "Node3D", true, false):
		out.append(n as Node3D)
	out.sort_custom(func(a: Node3D, b: Node3D) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	return out


func get_mining_origin() -> Node3D:
	var head := get_part_node(ShipPartDefinition.Slot.HEAD)
	return head.find_child(MINING_ORIGIN, true, false) as Node3D if head != null else null


func is_placeholder(slot: ShipPartDefinition.Slot) -> bool:
	var node := get_part_node(slot)
	return node != null and node.has_meta(PLACEHOLDER_META)


func _resolve_stats() -> void:
	stats = ShipStatsResolver.resolve(hull, state)
	stats_changed.emit(stats)


func _mount(slot: ShipPartDefinition.Slot) -> void:
	var key := ShipPartDefinition.slot_key(slot)
	var part := hull.get_part(slot)
	var path := ""
	if part != null:
		var level_number: int = state.part_levels.get(key, 1)
		var lvl := part.get_level(level_number)
		if lvl != null:
			path = lvl.scene_path
	var node: Node3D = null
	if path != "" and ResourceLoader.exists(path):
		var packed := load(path) as PackedScene
		node = packed.instantiate() as Node3D if packed != null else null
		if node == null:
			push_warning("ShipAssembler: '%s' is not a Node3D scene; using placeholder" % path)
	if node == null:
		path = ""
		node = _make_placeholder(slot)
	node.name = _node_name(slot)
	if slot != ShipPartDefinition.Slot.BODY:
		node.transform = _socket_transform(slot)
	add_child(node)
	parts[key] = node
	used_scene_paths[key] = path


## Socket transform relative to this node (works before entering the tree).
func _socket_transform(slot: ShipPartDefinition.Slot) -> Transform3D:
	var body := get_part_node(ShipPartDefinition.Slot.BODY)
	var socket := get_socket(slot)
	if body == null or socket == null:
		push_warning("ShipAssembler: body has no %s%s; part placed at ship center" % [SOCKET_PREFIX, _node_name(slot)])
		return Transform3D.IDENTITY
	var xf := Transform3D.IDENTITY
	var n: Node = socket
	while n != null and n != body:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return body.transform * xf


func _free_part(key: StringName) -> void:
	var node: Node3D = parts.get(key, null)
	if node != null:
		remove_child(node)
		node.free() # out of the tree already; free now so no orphan lingers
	parts.erase(key)


static func _node_name(slot: ShipPartDefinition.Slot) -> String:
	return String(ShipPartDefinition.slot_key(slot)).capitalize()


# --- generated placeholders ------------------------------------------------

static func _make_placeholder(slot: ShipPartDefinition.Slot) -> Node3D:
	var root := Node3D.new()
	root.set_meta(PLACEHOLDER_META, true)
	match slot:
		ShipPartDefinition.Slot.BODY:
			var capsule := CapsuleMesh.new()
			capsule.radius = 0.26
			capsule.height = 1.1
			_add_mesh(root, capsule, COLOR_CREAM, Vector3.ZERO, true)
			for socket_name: String in PLACEHOLDER_SOCKETS:
				_add_marker(root, socket_name, PLACEHOLDER_SOCKETS[socket_name])
			for hp_name: String in PLACEHOLDER_HARDPOINTS:
				_add_marker(root, hp_name, PLACEHOLDER_HARDPOINTS[hp_name])
		ShipPartDefinition.Slot.HEAD:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.22
			cone.height = 0.895
			_add_mesh(root, cone, COLOR_ACCENT, Vector3(0.0, 0.0, -0.4475), true)
			_add_marker(root, MINING_ORIGIN, Vector3(0.0, 0.02, -0.895))
		ShipPartDefinition.Slot.WINGS:
			var box := BoxMesh.new()
			box.size = Vector3(1.3, 0.06, 0.45)
			_add_mesh(root, box, COLOR_CREAM, Vector3.ZERO, false)
		ShipPartDefinition.Slot.ENGINE:
			var nozzle := CylinderMesh.new()
			nozzle.top_radius = 0.16
			nozzle.bottom_radius = 0.2
			nozzle.height = 0.35
			_add_mesh(root, nozzle, COLOR_ACCENT, Vector3(0.0, 0.0, 0.175), true)
			_add_marker(root, ENGINE_TRAIL_PREFIX + "0", Vector3(-0.112, 0.028, 0.35))
			_add_marker(root, ENGINE_TRAIL_PREFIX + "1", Vector3(0.112, 0.028, 0.35))
	return root


## along_z: rotate a Y-axis primitive so its +Y points to -Z (nose direction).
static func _add_mesh(parent: Node3D, mesh: PrimitiveMesh, color: Color, offset: Vector3, along_z: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "PlaceholderMesh"
	mi.mesh = mesh
	mi.position = offset
	if along_z:
		mi.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	parent.add_child(mi)


static func _add_marker(parent: Node3D, marker_name: String, pos: Vector3) -> void:
	var m := Marker3D.new()
	m.name = marker_name
	m.position = pos
	parent.add_child(m)
