class_name Grade
## Item quality scale (GAME_PLAN §5.1). Order of the enum is the quality order.
## Quality of an item, not a player level. Native grade never changes (§5.2).

enum Value { E, D, C, B, A, S, SS, SSS }


static func to_label(value: Value) -> String:
	return Value.keys()[value]
