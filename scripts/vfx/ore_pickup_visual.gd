class_name OrePickupVisual
extends Node3D
## Ore pickup look: Modeler's pickup model + soft glow + sparkles + bob, so a
## pickup reads at the ortho 18-24 m gameplay camera. Intended as the `Visual`
## child of scenes/pickups/ore_pickup.tscn (OrePickup skips its placeholder box
## when a `Visual` child exists). VfxDirector also swaps it in at runtime for
## pickups that still carry the placeholder.
##   item_id: picks the model (crystal ids -> crystal_pickup_01) and the colour.
## Budget: model (<= 90 tris) + 1 halo quad + 6 particles.

const MODEL_ORE := "res://assets/models/pickups/ore_pickup_01.glb"
const MODEL_CRYSTAL := "res://assets/models/pickups/crystal_pickup_01.glb"

## Empty = read `item_id` from the parent (OrePickup) on ready.
@export var item_id: StringName = &""
@export var glow_color: Color = Color(0, 0, 0, 0)
@export var model_scale: float = 1.25
@export var bob_height: float = 0.12
@export var bob_speed: float = 2.4
## Halo diameter (m). Glow is what makes the pickup readable when zoomed out.
@export var halo_size: float = 1.5

var _model: Node3D
var _adopted: Node3D
var _phase: float = 0.0
var _t: float = 0.0

@onready var _glow: OreGlow = $OreGlow


## Use an already instanced model (e.g. the pickup's existing `Visual`) instead
## of loading one. Call before adding this node to the tree.
func adopt(model: Node3D) -> void:
	_adopted = model


func _ready() -> void:
	if item_id == &"" and get_parent() != null and get_parent().get(&"item_id") is StringName:
		item_id = get_parent().get(&"item_id")
	var crystal := String(item_id).contains("crystal")
	if glow_color.a <= 0.0:
		glow_color = Color(0.4, 0.85, 1.0) if crystal else Color(1.0, 0.62, 0.25)
	var path := MODEL_CRYSTAL if crystal else MODEL_ORE
	if _adopted != null and is_instance_valid(_adopted):
		var keep_scale := _adopted.scale
		if _adopted.get_parent() != null:
			_adopted.get_parent().remove_child(_adopted)
		_model = _adopted
		add_child(_model)
		_model.scale = keep_scale * model_scale
		_model.position = Vector3.ZERO
		_glow.halo_size = halo_size
		_glow.color = glow_color
		_phase = randf() * TAU
		return
	if ResourceLoader.exists(path):
		_model = (load(path) as PackedScene).instantiate() as Node3D
	else:
		var mi := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 0.2
		m.height = 0.32
		m.radial_segments = 6
		m.rings = 2
		mi.mesh = m
		_model = mi
	_model.name = "Model"
	_model.scale = Vector3.ONE * model_scale
	add_child(_model)
	_glow.halo_size = halo_size
	_glow.color = glow_color
	_phase = randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	var bob := sin(_t * bob_speed + _phase) * bob_height
	# Bob in world up even if the pickup tumbles.
	_model.global_position = global_position + Vector3.UP * (bob + 0.05)
	_glow.global_position = global_position + Vector3.UP * (bob * 0.5)
