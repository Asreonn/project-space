extends GutTest
## Nose / tail layout of the assembled player ship (nose = -Z, Godot forward):
## Head and FX_MiningOrigin in front, Engine and FX_EngineTrail_* behind, and
## forward thrust moves the ship nose first with the trail behind it.
## Checked at runtime on scenes/ship/player_ship.tscn at every authored level.

const PLAYER_SHIP := "res://scenes/ship/player_ship.tscn"
const HULL := "res://data/ships/starter_shuttle_01.tres"

var ship: ShipController
var asm: ShipAssembler


func before_each() -> void:
	ship = (load(PLAYER_SHIP) as PackedScene).instantiate() as ShipController
	ship.hull_definition = load(HULL)
	ship.use_player_input = false
	add_child_autofree(ship)
	# Arbitrary yaw: the checks are in ship-local space.
	ship.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(37.0)), Vector3(4.0, 0.0, -2.0))
	asm = ship.assembler
	await wait_physics_frames(2)


func _local_z(n: Node3D) -> float:
	return ship.to_local(n.global_position).z


func _mesh_center_local(part: Node3D) -> Vector3:
	var box := AABB()
	var first := true
	for n: Node in part.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b := (ship.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.get_center()


func _check_layout(label: String) -> void:
	var body := asm.get_part_node(ShipPartDefinition.Slot.BODY)
	var head := asm.get_part_node(ShipPartDefinition.Slot.HEAD)
	var engine := asm.get_part_node(ShipPartDefinition.Slot.ENGINE)
	var sock_head := body.find_child("Socket_Head", true, false) as Node3D
	var sock_engine := body.find_child("Socket_Engine", true, false) as Node3D
	assert_lt(_local_z(sock_head), 0.0, "%s: Socket_Head in front of the centre" % label)
	assert_gt(_local_z(sock_engine), 0.0, "%s: Socket_Engine behind the centre" % label)
	assert_almost_eq(head.global_position, sock_head.global_position, Vector3.ONE * 0.001, "%s: Head sits on Socket_Head" % label)
	assert_almost_eq(engine.global_position, sock_engine.global_position, Vector3.ONE * 0.001, "%s: Engine sits on Socket_Engine" % label)
	assert_lt(_mesh_center_local(head).z, -0.3, "%s: Head mesh centre in front" % label)
	assert_gt(_mesh_center_local(engine).z, 0.3, "%s: Engine mesh centre behind" % label)
	assert_lt(_local_z(asm.get_mining_origin()), -0.5, "%s: FX_MiningOrigin at the nose" % label)
	var trails := asm.get_engine_trail_points()
	assert_gt(trails.size(), 0)
	for t: Node3D in trails:
		assert_gt(_local_z(t), 0.5, "%s: %s at the tail" % [label, t.name])
	# No extra yaw between the ship body and its visuals.
	for n: Node3D in [asm.get_parent() as Node3D, asm, head, engine]:
		assert_almost_eq(n.global_basis.z.dot(ship.global_basis.z), 1.0, 0.001, "%s: %s not rotated against the ship" % [label, n.name])


func test_layout_l1_to_l3() -> void:
	_check_layout("L1")
	for slot: ShipPartDefinition.Slot in [ShipPartDefinition.Slot.HEAD, ShipPartDefinition.Slot.ENGINE]:
		assert_false(asm.is_placeholder(slot), "real GLB in use")
	# Same path as an upgrade (EventBus.part_upgraded -> set_part_level).
	for level: int in [2, 3]:
		for slot: ShipPartDefinition.Slot in [ShipPartDefinition.Slot.BODY, ShipPartDefinition.Slot.HEAD,
				ShipPartDefinition.Slot.WINGS, ShipPartDefinition.Slot.ENGINE]:
			asm.set_part_level(slot, level)
		await wait_physics_frames(1)
		_check_layout("L%d" % level)
		assert_string_contains(asm.used_scene_paths[&"head"], "head_L%d" % level)


func test_forward_thrust_moves_nose_first_trail_behind() -> void:
	var nose := -ship.global_basis.z
	ship.has_aim = true
	ship.aim_point = ship.global_position + nose * 30.0
	ship.in_thrust = 1.0
	await wait_physics_frames(40)
	ship.in_thrust = 0.0
	var v := ship.velocity
	v.y = 0.0
	assert_gt(v.length(), 1.0, "ship accelerated")
	assert_gt(v.normalized().dot(-ship.global_basis.z), 0.95, "velocity along the nose")
	for t: Node3D in asm.get_engine_trail_points():
		var off := t.global_position - ship.global_position
		assert_lt(off.dot(v.normalized()), 0.0, "%s trails behind the motion" % t.name)
	var trail := ship.find_child("EngineTrail", true, false) as EngineTrail
	if trail != null:
		assert_gt(trail.thrust, 0.3, "engine trail is driven while thrusting")
