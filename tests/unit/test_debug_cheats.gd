extends GutTest
## F9 debug cheat (DebugCheats): +500 credits through GameState, debug builds only.

var _saved_credits: int = 0


func before_each() -> void:
	_saved_credits = GameState.credits


func after_each() -> void:
	GameState.credits = _saved_credits


func _press() -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = DebugCheats.ACTION_ADD_CREDITS
	ev.pressed = true
	return ev


func test_input_action_is_bound_to_f9() -> void:
	assert_true(InputMap.has_action(DebugCheats.ACTION_ADD_CREDITS), "debug_add_credits action exists")
	var keys: Array[Key] = []
	for e: InputEvent in InputMap.action_get_events(DebugCheats.ACTION_ADD_CREDITS):
		var k := e as InputEventKey
		if k != null:
			keys.append(k.physical_keycode)
	assert_has(keys, KEY_F9)


func test_f9_adds_500_credits_in_debug_build() -> void:
	var cheats := DebugCheats.new()
	cheats.enabled = true
	add_child_autofree(cheats)
	var before := GameState.credits
	assert_true(cheats.handle(_press()), "cheat handled")
	assert_eq(GameState.credits, before + DebugCheats.ADD_CREDITS_AMOUNT)


func test_disabled_in_release_does_nothing() -> void:
	var cheats := DebugCheats.new()
	cheats.enabled = false # what OS.is_debug_build() gives in a release export
	add_child(cheats)
	var before := GameState.credits
	assert_false(cheats.handle(_press()), "no cheat when disabled")
	assert_eq(GameState.credits, before)
	await wait_process_frames(1)
	assert_false(is_instance_valid(cheats), "node frees itself when disabled")


func test_enabled_follows_build_type() -> void:
	assert_eq(DebugCheats.new().enabled, OS.is_debug_build())
