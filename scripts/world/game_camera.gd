class_name GameCamera
extends Camera3D
## M1 top-down takip kamerası. Spec: docs/design/m1_flight_tuning.md §2.
## Ortografik (varsayılan) veya düşük FOV perspektif; ikisi de aynı dikey görüşü (view_size, m) korur.
## Takip, look-ahead ve zoom exp(-k*dt) ile (kare oranından bağımsız).

@export var target_path: NodePath
## Boşsa hedefin FlightTuning'i kullanılır.
@export var tuning: FlightTuning

var view_size: float = 40.0  ## m, anlık dikey görüş
var _ship: ShipController
var _zoom_i: int = 1
var _focus: Vector3 = Vector3.ZERO
var _lead: Vector3 = Vector3.ZERO
var _size_override: float = -1.0


func _ready() -> void:
	_ship = get_node_or_null(target_path) as ShipController
	if tuning == null and _ship:
		tuning = _ship.tuning
	if tuning == null:
		tuning = FlightTuning.new()
	_zoom_i = clampi(tuning.default_zoom_index, 0, tuning.ortho_sizes.size() - 1)
	view_size = _base_size()
	snap()
	current = true


func set_target(ship: ShipController) -> void:
	_ship = ship
	if ship and ship.tuning:
		tuning = ship.tuning
	snap()


## Debug slider: zoom kademesi yerine sabit görüş (m). < 0 = kademeye dön.
func set_size_override(size_m: float) -> void:
	_size_override = size_m


func get_size_override() -> float:
	return _size_override


func snap() -> void:
	if _ship == null:
		return
	_focus = _ship.global_position
	_lead = Vector3.ZERO
	_apply_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"zoom_in"):
		_zoom_i = maxi(_zoom_i - 1, 0)
	elif event.is_action_pressed(&"zoom_out"):
		_zoom_i = mini(_zoom_i + 1, tuning.ortho_sizes.size() - 1)


func _base_size() -> float:
	if _size_override > 0.0:
		return _size_override
	if tuning.ortho_sizes.is_empty():
		return 40.0
	return tuning.ortho_sizes[_zoom_i]


func _process(dt: float) -> void:
	if _ship == null or not is_instance_valid(_ship):
		return
	var ship_pos := _ship.get_global_transform_interpolated().origin
	ship_pos.y = 0.0
	var v := _ship.velocity
	v.y = 0.0
	var lead := (v * tuning.look_ahead_time).limit_length(tuning.look_ahead_max)
	if _ship.has_aim:
		var aim_off := (_ship.aim_point - ship_pos) * tuning.aim_offset_ratio
		aim_off.y = 0.0
		lead += aim_off.limit_length(tuning.aim_offset_max)
	_lead = _lead.lerp(lead, 1.0 - exp(-tuning.look_ahead_rate * dt))
	_focus = _focus.lerp(ship_pos + _lead, 1.0 - exp(-tuning.follow_rate * dt))

	var fly := _ship.get_stat(ShipController.STAT_FLYING_SPEED)
	var boost_span := maxf(fly * (tuning.boost_speed_mult - 1.0), 0.01)
	var boost_t := clampf((v.length() - fly) / boost_span, 0.0, 1.0)
	var target_size := _base_size() * (1.0 + tuning.boost_zoom_out * boost_t)
	view_size = lerpf(view_size, target_size, 1.0 - exp(-tuning.zoom_rate * dt))
	_apply_transform()


func get_camera_distance() -> float:
	if tuning.camera_perspective:
		return view_size / (2.0 * tan(deg_to_rad(tuning.camera_fov) * 0.5))
	return tuning.ortho_camera_distance


func _apply_transform() -> void:
	var tilt := deg_to_rad(tuning.camera_tilt_deg)
	var dir := Vector3(0.0, cos(tilt), sin(tilt))  # yukarıda, hafif +Z (ekranın altı) tarafında
	var dist := get_camera_distance()
	if tuning.camera_perspective:
		projection = Camera3D.PROJECTION_PERSPECTIVE
		fov = tuning.camera_fov
	else:
		projection = Camera3D.PROJECTION_ORTHOGONAL
		size = view_size
	near = 0.5
	far = dist + 200.0
	global_position = _focus + dir * dist
	look_at(_focus, Vector3.FORWARD)
