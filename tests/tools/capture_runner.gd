extends Node
## Body of tests/tools/capture_mvp.gd, loaded at runtime so autoloads resolve.
## Options (after `--`): <out.png> --ortho=<size m> (capture-only camera size
## override) --face=down|up|any (ship nose toward screen-down = world +Z, etc.).
## Prefers an M/L asteroid so it does not break before the shot.

signal finished(code: int)

var out_path: String = "user://mvp_capture.png"
var ortho_size: float = -1.0
var face: String = "any"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (load("res://scenes/main/mvp_sector.tscn") as PackedScene).instantiate() as MvpGame
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	for i in 10:
		await get_tree().physics_frame
	if ortho_size > 0.0:
		game.camera.set_size_override(ortho_size)
	var ship := game.ship
	var laser := game.laser
	ship.use_player_input = false
	laser.use_player_input = false
	var best: Asteroid = null
	for a: Asteroid in game.field.get_asteroids():
		if a.size == &"S":
			continue
		if best == null or a.global_position.distance_to(ship.global_position) < best.global_position.distance_to(ship.global_position):
			best = a
	if best != null:
		var dir := (best.global_position - ship.global_position).normalized()
		if face == "down":
			dir = Vector3.BACK # +Z: screen-down (camera up = -Z)
		elif face == "up":
			dir = Vector3.FORWARD
		ship.global_position = best.global_position - dir * (best.radius + 4.0)
		ship.look_at(ship.global_position + dir, Vector3.UP)
		ship.velocity = Vector3.ZERO
		game.camera.snap()
		laser.wants_fire = true
	for i in 90:
		ship.velocity = Vector3.ZERO
		if best != null and is_instance_valid(best):
			ship.has_aim = true
			ship.aim_point = best.global_position
		await get_tree().process_frame
	var cam := game.camera
	var vp := get_viewport().get_visible_rect().size
	var origin := game.assembler.get_mining_origin()
	print("capture: camera %s size %.1f, nose=%s, firing=%s, hit=%s" % [
		"ortho" if cam.projection == Camera3D.PROJECTION_ORTHOGONAL else "persp", cam.size,
		-ship.global_basis.z, laser.firing, laser.hit_asteroid == best])
	print("capture: screen mining_origin=%s beam_origin=%s beam_end=%s center=%s (viewport %s)" % [
		cam.unproject_position(origin.global_position), cam.unproject_position(laser.beam_origin),
		cam.unproject_position(laser.beam_end), cam.unproject_position(ship.global_position), vp])
	for t: Node3D in game.assembler.get_engine_trail_points():
		print("capture: screen %s=%s" % [t.name, cam.unproject_position(t.global_position)])
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(out_path)
	print("capture: %s (%dx%d) err=%d" % [out_path, img.get_width(), img.get_height(), err])
	finished.emit(0 if err == OK else 1)
