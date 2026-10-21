class_name OreGlow
extends Node3D
## Idle glow for an ore pickup: pulsing soft halo + a few sparkles.
## Add as a child of the pickup (scale 1 = ~0.35 m ore chunk).
##   glow.set_color(ore_color)   # e.g. orange ore, cyan crystal
##   glow.set_active(false)      # hide when collected / returned to a pool
## Budget: 1 quad + max 6 particles.

@export var color: Color = Color(1.0, 0.62, 0.25):
	set(value):
		color = value
		if is_node_ready():
			_apply()
@export var halo_size: float = 1.1

@onready var _halo: MeshInstance3D = $Halo
@onready var _sparkles: GPUParticles3D = $Sparkles


func _ready() -> void:
	_apply()


func set_color(c: Color) -> void:
	color = c


func set_active(on: bool) -> void:
	visible = on
	_sparkles.emitting = on


func _apply() -> void:
	_halo.scale = Vector3.ONE * halo_size
	var hm := _halo.material_override as ShaderMaterial
	if hm != null:
		hm.set_shader_parameter(&"tint", color)
	var sm := _sparkles.draw_pass_1.surface_get_material(0) as ShaderMaterial
	if sm != null:
		sm.set_shader_parameter(&"tint", color.lightened(0.35))
