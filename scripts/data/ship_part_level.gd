class_name ShipPartLevel
extends Resource
## One visual + stat level (L1, L2, L3) of a ShipPartDefinition.

@export_range(1, 3) var level: int = 1
## res://assets/models/ships/<hull_id>/<part>_L<n>.glb (or a .tscn wrapper of it).
@export_file("*.glb", "*.tscn") var scene_path: String
@export var modifiers: Array[StatModifier] = []
## Cost of upgrading TO this level. Empty for L1.
@export var cost: Array[CostEntry] = []
## Values are temporary prototype numbers (GAME_PLAN §15.3).
@export var balance_prototype: bool = true
