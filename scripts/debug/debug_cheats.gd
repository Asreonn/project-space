class_name DebugCheats
extends Node
## Debug-only cheats for demos and playtests (PS Game Designer, mvp.md §2).
## F9 (input action debug_add_credits): +500 credits through GameState.add_credits().
## Only active in debug builds (editor runs and debug exports). In a release
## export OS.is_debug_build() is false and the node frees itself on _ready.

const ACTION_ADD_CREDITS := &"debug_add_credits"
const ADD_CREDITS_AMOUNT := 500

## Tests set this to false to check the release path.
var enabled: bool = OS.is_debug_build()


func _ready() -> void:
	if not enabled:
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if handle(event):
		get_viewport().set_input_as_handled()


## Returns true when the event triggered a cheat.
func handle(event: InputEvent) -> bool:
	if not enabled or event.is_echo():
		return false
	if event.is_action_pressed(ACTION_ADD_CREDITS):
		GameState.add_credits(ADD_CREDITS_AMOUNT)
		print("[DebugCheats] +%d credits (F9)" % ADD_CREDITS_AMOUNT)
		return true
	return false
