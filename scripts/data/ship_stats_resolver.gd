class_name ShipStatsResolver
## final[stat] = clamp((base[stat] + sum(ADD)) * prod(MUL)) by upgrade_caps[stat]
## (min for normal stats, max for ShipStat.LOWER_IS_BETTER). Stats missing from
## upgrade_caps are uncapped. Level modifiers are absolute (only the current
## level's list is read). Hardpoint/passive modules and
## cargo mass are applied in a later layer (outside this contract).


## apply_caps = false skips the cap clamp (ShipDataValidator rule 6).
static func resolve(hull: ShipHullDefinition, state: ShipInstanceState, apply_caps: bool = true) -> Dictionary[StringName, float]:
	var out: Dictionary[StringName, float] = {}
	if hull == null:
		push_error("ShipStatsResolver: hull is null")
		return out
	if state != null and state.hull_id != &"" and state.hull_id != hull.id:
		push_warning("ShipStatsResolver: state.hull_id '%s' != hull.id '%s'" % [state.hull_id, hull.id])

	var add: Dictionary[StringName, float] = {}
	var mul: Dictionary[StringName, float] = {}
	for slot: int in ShipPartDefinition.Slot.values():
		var part := hull.get_part(slot)
		if part == null:
			push_error("ShipStatsResolver: hull '%s' has no %s part" % [hull.id, ShipPartDefinition.slot_key(slot)])
			continue
		var key := ShipPartDefinition.slot_key(slot)
		var level_number: int = state.part_levels.get(key, 1) if state != null else 1
		var lvl := part.get_level(level_number)
		if lvl == null:
			push_error("ShipStatsResolver: part '%s' has no levels" % part.id)
			continue
		for m: StatModifier in lvl.modifiers:
			if m == null:
				continue
			if m.op == StatModifier.Op.ADD:
				add[m.stat] = add.get(m.stat, 0.0) + m.value
			else:
				mul[m.stat] = mul.get(m.stat, 1.0) * m.value

	var keys: Array[StringName] = []
	for s: StringName in hull.base_stats.keys():
		keys.append(s)
	for s: StringName in add.keys():
		if not keys.has(s):
			keys.append(s)
	for s: StringName in keys:
		var v: float = (hull.base_stats.get(s, 0.0) + add.get(s, 0.0)) * mul.get(s, 1.0)
		if apply_caps and hull.upgrade_caps.has(s):
			var cap: float = hull.upgrade_caps[s]
			v = maxf(v, cap) if ShipStat.is_lower_better(s) else minf(v, cap)
		out[s] = v
	return out
