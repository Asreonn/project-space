extends Node
## Body of tests/tools/capture_mvp.gd, loaded at runtime so autoloads resolve.

signal finished(code: int)

var out_path: String = "user://mvp_capture.png"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (load("res://scenes/main/mvp_sector.tscn") as PackedScene).instantiate() as MvpGame
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	for i in 10:
		await get_tree().physics_frame
	var ship := game.ship
	ship.use_player_input = false
	game.laser.use_player_input = false
	var best: Asteroid = null
	for a: Asteroid in game.field.get_asteroids():
		if best == null or a.global_position.distance_to(ship.global_position) < best.global_position.distance_to(ship.global_position):
			best = a
	if best != null:
		var dir := (best.global_position - ship.global_position).normalized()
		ship.global_position = best.global_position - dir * (best.radius + 4.0)
		ship.look_at(ship.global_position + dir, Vector3.UP)
		game.laser.wants_fire = true
	for i in 90:
		ship.velocity = Vector3.ZERO
		if best != null and is_instance_valid(best):
			ship.has_aim = true
			ship.aim_point = best.global_position
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(out_path)
	print("capture: %s (%dx%d) err=%d" % [out_path, img.get_width(), img.get_height(), err])
	finished.emit(0 if err == OK else 1)
