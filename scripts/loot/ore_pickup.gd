class_name OrePickup
extends Node3D
## Ore pickup (scenes/pickups/ore_pickup.tscn root). Holds item + amount and a
## visual (ResourceDefinition.pickup_scene_path GLB, else a tinted cube);
## PickupPool moves it (drift, magnet pull) and delivers it to
## GameState cargo. Modeler pickup scenes can replace the Visual child.

var item_id: StringName
var amount: int = 1
var velocity: Vector3 = Vector3.ZERO
var age: float = 0.0
var attracted: bool = false
var color: Color = Color(0.85, 0.7, 0.45)
var model_path: String = ""

var _spin_axis: Vector3 = Vector3.UP


func setup(p_item_id: StringName, p_amount: int, p_velocity: Vector3, p_color: Color, p_model_path: String = "") -> void:
	item_id = p_item_id
	amount = p_amount
	velocity = p_velocity
	color = p_color
	model_path = p_model_path


func _ready() -> void:
	add_to_group(&"ore_pickups")
	_spin_axis = Vector3(randf() - 0.5, 1.0, randf() - 0.5).normalized()
	if get_node_or_null(^"Visual") != null:
		return
	var model := ModelUtil.instance_model(model_path)
	if model != null:
		model.name = "Visual"
		model.scale = Vector3.ONE * (1.0 + 0.12 * (amount - 1))
		add_child(model)
		return
	var mesh := BoxMesh.new()
	var s := 0.3 + 0.05 * amount
	mesh.size = Vector3(s, s, s)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Visual"
	mi.mesh = mesh
	add_child(mi)


## One movement step. target = magnet position; can_attract = cargo has room.
## Returns true when the pickup is inside collect_radius (pool collects it).
func step(dt: float, tuning: PickupTuning, target: Vector3, has_target: bool, can_attract: bool) -> bool:
	age += dt
	attracted = false
	if has_target and can_attract:
		var to := target - position
		to.y = 0.0
		var dist := to.length()
		if dist <= tuning.collect_radius:
			return true
		if dist <= tuning.magnet_radius:
			attracted = true
			velocity += to / maxf(dist, 0.001) * tuning.pull_accel * dt
			velocity = velocity.limit_length(tuning.pull_max_speed)
	if not attracted:
		velocity *= exp(-tuning.drift_damp * dt)
	position += velocity * dt
	position.y = 0.0
	rotate(_spin_axis, dt * 1.5)
	return false
