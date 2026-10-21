extends GutTest
## Debug HUD text stays fully on screen: toasts centred, station panel inside
## the right edge even with the longest rows.

var hud: MvpDebugHud


func before_each() -> void:
	GameState.start_session(load("res://data/ships/starter_shuttle_01.tres") as ShipHullDefinition, [], 0)
	hud = MvpDebugHud.new()
	add_child_autofree(hud)
	await wait_process_frames(1)


func _screen() -> Rect2:
	return Rect2(Vector2.ZERO, hud.get_viewport().get_visible_rect().size)


func test_toast_is_centred_and_visible() -> void:
	hud._show_toast("Head upgraded to L2")
	await wait_process_frames(2)
	var r := hud._toast.get_global_rect()
	assert_true(_screen().encloses(r), "toast rect %s inside %s" % [r, _screen()])
	assert_almost_eq(r.get_center().x, _screen().get_center().x, 2.0, "toast strip centred")
	assert_eq(hud._toast.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_gt(r.position.y, 8.0, "not at the very top edge")


func test_station_panel_inside_screen() -> void:
	hud.docked = true
	hud.set_panel_open(true)
	await wait_process_frames(3)
	var r := hud._panel.get_global_rect()
	assert_true(_screen().encloses(r), "panel rect %s inside %s" % [r, _screen()])
