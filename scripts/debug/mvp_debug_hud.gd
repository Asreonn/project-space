class_name MvpDebugHud
extends CanvasLayer
## Stand-in HUD + station panel until the UI Designer's scenes land
## (ui/mvp-hud). Uses only EventBus signals and the GameState API, exactly like
## the real UI will. It is also the publisher of station_panel_toggled (E while
## docked), which belongs to the station panel per mvp.md §6.
## No bottom inventory bar (AGENTS.md §8).

const PARTS: Array[StringName] = [&"head", &"body", &"wings", &"engine"]
const STAT_FOR_PART: Dictionary[StringName, StringName] = {
	&"head": &"mining_power", &"body": &"carry_capacity", &"wings": &"maneuver_speed", &"engine": &"flying_speed",
}

var game: MvpGame
var docked: bool = false
var panel_open: bool = false

var _status: Label
var _prompt: Label
var _toast: Label
var _fps: Label
var _panel: PanelContainer
var _sell_button: Button
var _rows: Dictionary[StringName, Button] = {}
var _credits: int = 0
var _cargo_used: int = 0
var _cargo_cap: int = 0
var _toast_t: float = 0.0


func setup(p_game: MvpGame) -> void:
	game = p_game


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_status = _label(root, Vector2(24, 20), 22)
	_fps = _label(root, Vector2(24, 0), 16)
	_fps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps.position = Vector2(-150, 16)
	_prompt = _label(root, Vector2.ZERO, 26)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -150.0
	_prompt.offset_bottom = -110.0
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.text = "E: Station"
	_prompt.visible = false
	# Toast: full-width strip, text centred, below the top edge (never clipped).
	_toast = _label(root, Vector2.ZERO, 26)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 36.0
	_toast.offset_bottom = 76.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate = Color(1.0, 0.75, 0.5)

	# Panel: right-anchored, grows leftward, so long rows never leave the screen.
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.offset_right = -32.0
	_panel.offset_left = -32.0
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.visible = false
	root.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "STATION   (E / Esc closes)"
	box.add_child(title)
	_sell_button = Button.new()
	_sell_button.name = "SellButton"
	_sell_button.pressed.connect(_on_sell)
	box.add_child(_sell_button)
	for part: StringName in PARTS:
		var b := Button.new()
		b.name = "Upgrade_%s" % part
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_upgrade.bind(part))
		box.add_child(b)
		_rows[part] = b

	EventBus.credits_changed.connect(_on_credits)
	EventBus.cargo_changed.connect(_on_cargo)
	EventBus.dock_entered.connect(_on_dock.bind(true))
	EventBus.dock_exited.connect(_on_dock.bind(false))
	EventBus.part_upgraded.connect(_on_part_upgraded)
	EventBus.upgrade_failed.connect(_on_upgrade_failed)
	EventBus.cargo_rejected.connect(_on_cargo_rejected)
	EventBus.cargo_sold.connect(_on_sold)
	_credits = GameState.credits
	_cargo_used = GameState.get_cargo_used()
	_cargo_cap = GameState.get_cargo_capacity()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and (docked or panel_open):
		set_panel_open(not panel_open)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and panel_open:
		set_panel_open(false)
		get_viewport().set_input_as_handled()


func set_panel_open(open: bool) -> void:
	var value := open and docked
	if value == panel_open:
		return
	panel_open = value
	_panel.visible = value
	_prompt.visible = docked and not value
	EventBus.station_panel_toggled.emit(value)
	_refresh_panel()


func _process(dt: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= dt
		if _toast_t <= 0.0:
			_toast.text = ""
	_fps.text = "%d fps" % Engine.get_frames_per_second()
	var speed := game.ship.get_speed() if game != null else 0.0
	var levels := ""
	for part: StringName in PARTS:
		levels += "%s L%d   " % [String(part).capitalize(), GameState.get_part_level(part)]
	var cargo_line := "Cargo  %d / %d u" % [_cargo_used, _cargo_cap]
	if _cargo_cap > 0 and _cargo_used >= _cargo_cap:
		cargo_line += "   FULL"
	_status.text = "Credits  %d cr\n%s\nSpeed  %.1f m/s\n%s\n\nWASD fly · mouse aim · LMB mine · Shift boost · Space brake · E station" % [
		_credits, cargo_line, speed, levels]


func _refresh_panel() -> void:
	if not _panel.visible:
		return
	var value := GameState.get_cargo_value()
	_sell_button.text = "Sell all cargo  (%d u  ->  +%d cr)" % [GameState.get_cargo_units(), value]
	_sell_button.disabled = GameState.get_cargo_units() == 0
	var now := GameState.get_stats()
	for part: StringName in PARTS:
		var b := _rows[part]
		var level := GameState.get_part_level(part)
		var cost := GameState.get_upgrade_cost(part)
		var stat := STAT_FOR_PART[part]
		if cost < 0:
			b.text = "%s  L%d  (max)   %s %s" % [String(part).capitalize(), level, stat, _num(now.get(stat, 0.0))]
			b.disabled = true
			continue
		var next := GameState.preview_stats(part)
		var short := maxi(0, cost - GameState.credits)
		b.text = "%s  L%d -> L%d   %d cr%s   %s %s -> %s" % [String(part).capitalize(), level, level + 1, cost,
			("  (need %d more)" % short) if short > 0 else "", stat, _num(now.get(stat, 0.0)), _num(next.get(stat, 0.0))]
		b.disabled = short > 0


func _on_sell() -> void:
	GameState.sell_all_cargo()
	_refresh_panel()


func _on_upgrade(part: StringName) -> void:
	GameState.try_upgrade(part)
	_refresh_panel()


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.5


func _on_credits(credits: int) -> void:
	_credits = credits
	_refresh_panel()


func _on_cargo(used: int, capacity: int) -> void:
	_cargo_used = used
	_cargo_cap = capacity
	_refresh_panel()


func _on_dock(is_docked: bool) -> void:
	docked = is_docked
	_prompt.visible = is_docked and not panel_open
	if not is_docked:
		set_panel_open(false)


func _on_part_upgraded(part: StringName, level: int) -> void:
	_show_toast("%s upgraded to L%d" % [String(part).capitalize(), level])
	_refresh_panel()


func _on_upgrade_failed(reason: StringName, part: StringName) -> void:
	_show_toast("%s upgrade failed: %s" % [String(part).capitalize(), reason])


func _on_cargo_rejected(_item_id: StringName, _amount: int, _reason: StringName) -> void:
	_show_toast("Cargo full")


func _on_sold(units: int, credits_earned: int) -> void:
	_show_toast("Sold %d u for %d cr" % [units, credits_earned])


static func _num(v: Variant) -> String:
	var f: float = v
	return str(snappedf(f, 0.1))


static func _label(parent: Control, pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override(&"shadow_offset_x", 2)
	l.add_theme_constant_override(&"shadow_offset_y", 2)
	parent.add_child(l)
	return l
