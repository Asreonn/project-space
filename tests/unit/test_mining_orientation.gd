extends GutTest
## Beam leaves the nose (Head's FX_MiningOrigin, ship -Z) and goes to the
## target; a target behind the ship is reached by turning toward the aim point
## (ShipController) while the beam stays inside the laser's firing arc
## (MiningLaserDefinition.firing_arc_deg, half-angle from the nose).

const PLAYER_SHIP := "res://scenes/ship/player_ship.tscn"
const HULL := "res://data/ships/starter_shuttle_01.tres"
const SECTOR := "res://data/sectors/mvp_sector_01.tres"
const ASTEROID_SCENE := "res://scenes/world/asteroid.tscn"

var ship: ShipController
var laser: MiningLaser


func before_each() -> void:
	ship = (load(PLAYER_SHIP) as PackedScene).instantiate() as ShipController
	ship.hull_definition = load(HULL)
	ship.use_player_input = false
	add_child_autofree(ship)
	ship.global_transform = Transform3D.IDENTITY # nose along -Z
	laser = ship.get_node("MiningLaser") as MiningLaser
	laser.use_player_input = false
	await wait_physics_frames(2)


func _asteroid(pos: Vector3) -> Asteroid:
	var sector := load(SECTOR) as SectorDefinition
	var a := (load(ASTEROID_SCENE) as PackedScene).instantiate() as Asteroid
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	a.setup(sector.asteroid_types[0], rng, null)
	add_child_autofree(a)
	a.global_position = pos
	return a


func _aim(at: Vector3) -> void:
	ship.has_aim = true
	ship.aim_point = at


func test_mining_origin_is_the_nose() -> void:
	var origin := laser.get_origin_node()
	assert_ne(origin, laser as Node3D, "origin is the Head's FX_MiningOrigin, not the laser node")
	assert_eq(String(origin.name), "FX_MiningOrigin")
	var nose := -ship.global_basis.z
	var off := origin.global_position - ship.global_position
	assert_gt(off.dot(nose), 0.5, "FX_MiningOrigin sits in front of the ship centre")
	var engine_fx := ship.find_children("FX_EngineTrail_*", "Node3D", true, false)
	assert_gt(engine_fx.size(), 0)
	for n: Node in engine_fx:
		var e := (n as Node3D).global_position - ship.global_position
		assert_lt(e.dot(nose), 0.0, "%s is behind the centre" % n.name)


func test_beam_from_nose_to_target_in_front() -> void:
	var rock := _asteroid(Vector3(0.0, 0.0, -6.0))
	_aim(rock.global_position)
	laser.wants_fire = true
	await wait_physics_frames(3)
	var nose := -ship.global_basis.z
	assert_gt((laser.beam_origin - ship.global_position).dot(nose), 0.5, "beam starts at the nose")
	var dir := (laser.beam_end - laser.beam_origin).normalized()
	var to_target := (rock.global_position - laser.beam_origin)
	to_target.y = 0.0
	assert_gt(dir.dot(to_target.normalized()), 0.99, "beam points at the target")
	assert_eq(laser.hit_asteroid, rock as Node3D)
	laser.wants_fire = false


func test_target_behind_ship_turns_toward_it() -> void:
	var rock := _asteroid(Vector3(0.0, 0.0, 6.0)) # behind (+Z)
	_aim(rock.global_position)
	laser.wants_fire = true
	await wait_physics_frames(2)
	var arc := cos(deg_to_rad(laser.definition.firing_arc_deg)) - 0.01
	var dir := (laser.beam_end - laser.beam_origin).normalized()
	assert_gt(dir.dot(ship.get_forward()), arc, "beam never leaves the nose cone")
	assert_null(laser.hit_asteroid, "no hit through the tail")
	for i in 240:
		_aim(rock.global_position)
		await wait_physics_frames(1)
		if laser.hit_asteroid == rock:
			break
	var to_rock := (rock.global_position - ship.global_position)
	to_rock.y = 0.0
	assert_gt(ship.get_forward().dot(to_rock.normalized()), arc, "ship turned its nose toward the target")
	assert_eq(laser.hit_asteroid, rock as Node3D, "beam reaches the target once it is in the cone")
	assert_gt((laser.beam_origin - ship.global_position).dot(ship.get_forward()), 0.5, "beam still starts at the nose")
	laser.wants_fire = false
