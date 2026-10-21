class_name StatModifier
extends Resource
## One stat change granted by a ShipPartLevel.
## ADD values are summed, MUL values are multiplied (see ShipStatsResolver).

enum Op { ADD, MUL }

@export var stat: StringName
@export var op: Op = Op.ADD
@export var value: float = 0.0
