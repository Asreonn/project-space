extends Node3D
## Project Space — main scene bootstrap (placeholder).
## Owner: Godot Engineer. The M1 vertical slice replaces the placeholder ship,
## adds the ship controller, asteroid field, HUD and VFX (see docs/ROADMAP.md).

func _ready() -> void:
	print("[ProjectSpace] main scene ready (Godot %s)" % Engine.get_version_info().string)
