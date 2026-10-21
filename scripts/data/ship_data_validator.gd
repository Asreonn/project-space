class_name ShipDataValidator
## Editor/test validation of ship data: ship_data_model.md v0.2.1 §6
## (rules 0-10, warnings W1-W3) plus the §7 naming standard for model empties.
##
## Authored levels come from the data (hull/part authored_up_to_level): rules
## 3-6 and 8 only fail for levels <= part.authored_up_to_level; missing data
## above it is warning W3.
## mode:
##   CONTRACT - rule 5 as written: L2 cost filled without credits, L3 cost has a
##              resource and credits.
##   MVP      - D-011: L2/L3 cost is credits only.
## require_assets: when false, a scene_path whose file is missing is a warning
##   instead of an error (models are delivered by the 3D Modeler).

enum Mode { CONTRACT, MVP }

const MODEL_ROOT := "res://assets/models/ships"
const CREDITS := &"credits"
const FUEL_STATS: Array[StringName] = [ShipStat.FUEL_CAPACITY, ShipStat.FUEL_RATE]
const HARDPOINT_IDS: Array[StringName] = [&"L", &"R", &"Nose", &"Top"]
const BODY_SOCKETS: Array[String] = ["Socket_Head", "Socket_Wings", "Socket_Engine"]
const STORAGE_STATS: Array[StringName] = [ShipStat.STORAGE_SOLID, ShipStat.STORAGE_LIQUID, ShipStat.STORAGE_GAS]
## Rule 8: each part's main stat.
const MAIN_STAT: Dictionary[StringName, StringName] = {
	&"head": ShipStat.MINING_POWER,
	&"body": ShipStat.CARRY_CAPACITY,
	&"wings": ShipStat.MANEUVER_SPEED,
	&"engine": ShipStat.FLYING_SPEED,
}
const EPS := 0.001


class Result:
	extends RefCounted
	var errors: PackedStringArray = []
	var warnings: PackedStringArray = []

	func is_ok() -> bool:
		return errors.is_empty()

	func error(msg: String) -> void:
		errors.append(msg)

	func warn(msg: String) -> void:
		warnings.append(msg)

	func merge(other: Result) -> void:
		errors.append_array(other.errors)
		warnings.append_array(other.warnings)

	func _to_string() -> String:
		var lines: PackedStringArray = []
		for e in errors:
			lines.append("ERROR: " + e)
		for w in warnings:
			lines.append("WARN:  " + w)
		return "\n".join(lines)


## Validates several hulls, including the cross-hull part of rule 2
## (a ShipPartDefinition is never used by more than one hull).
static func validate_catalog(hulls: Array[ShipHullDefinition], mode: Mode = Mode.CONTRACT, require_assets: bool = true) -> Result:
	var result := Result.new()
	var owner_by_part: Dictionary[String, StringName] = {} # part instance id / part id -> hull id
	var seen_hull_ids: Dictionary[StringName, bool] = {}
	for hull: ShipHullDefinition in hulls:
		if hull == null:
			result.error("catalog: null hull entry")
			continue
		if seen_hull_ids.has(hull.id):
			result.error("catalog: duplicate hull id '%s'" % hull.id)
		seen_hull_ids[hull.id] = true
		result.merge(validate_hull(hull, mode, require_assets))
		for slot: int in ShipPartDefinition.Slot.values():
			var part := hull.get_part(slot)
			if part == null:
				continue
			for key: String in ["obj:%d" % part.get_instance_id(), "id:%s" % part.id]:
				if owner_by_part.has(key) and owner_by_part[key] != hull.id:
					result.error("rule 2: part '%s' is used by hulls '%s' and '%s'" % [part.id, owner_by_part[key], hull.id])
				owner_by_part[key] = hull.id
	return result


static func validate_hull(hull: ShipHullDefinition, mode: Mode = Mode.CONTRACT, require_assets: bool = true) -> Result:
	var r := Result.new()
	if hull == null:
		r.error("hull is null")
		return r
	var h := "hull '%s'" % hull.id
	if hull.id == &"":
		r.error("hull has an empty id")
	elif not _matches("^[a-z][a-z0-9]*(_[a-z0-9]+)*_\\d{2,}$", hull.id):
		r.warn("%s: id should be lower snake_case with a version suffix (e.g. starter_shuttle_01)" % h)

	for stat: StringName in hull.base_stats.keys():
		if not ShipStat.is_valid(stat):
			r.error("%s: unknown stat '%s' in base_stats" % [h, stat])
	for stat: StringName in hull.upgrade_caps.keys():
		if not ShipStat.is_valid(stat):
			r.error("%s: unknown stat '%s' in upgrade_caps" % [h, stat])

	# Rule 10: hardpoint ids.
	var seen_hp: Dictionary[StringName, bool] = {}
	for hp: StringName in hull.hardpoints:
		if seen_hp.has(hp):
			r.error("rule 10: %s duplicate hardpoint '%s'" % [h, hp])
		seen_hp[hp] = true
		if not HARDPOINT_IDS.has(hp):
			r.error("rule 10: %s hardpoint id '%s' must be one of L, R, Nose, Top (node Hardpoint_<id>)" % [h, hp])
		elif hp == &"Top":
			r.error("rule 10: %s hardpoint 'Top' is reserved (not in M1/MVP)" % h)

	# Rule 0 (hull side).
	if hull.authored_up_to_level < 1 or hull.authored_up_to_level > ShipHullDefinition.MAX_PART_LEVEL:
		r.error("rule 0: %s authored_up_to_level %d not in 1..3" % [h, hull.authored_up_to_level])

	var parts_ok := true
	var min_authored := ShipHullDefinition.MAX_PART_LEVEL
	for slot: int in ShipPartDefinition.Slot.values():
		var key := ShipPartDefinition.slot_key(slot)
		var part := hull.get_part(slot)
		var p := "%s.%s" % [h, key]
		# Rule 1: all 4 parts set, slot matches the field.
		if part == null:
			r.error("rule 1: %s is missing" % p)
			parts_ok = false
			continue
		if part.slot != slot:
			r.error("rule 1: %s has slot %s" % [p, ShipPartDefinition.Slot.keys()[part.slot]])
		# Rule 2: part belongs to this hull.
		if part.hull_id != hull.id:
			r.error("rule 2: %s has hull_id '%s'" % [p, part.hull_id])
		# Rule 4 (id): <part>_<hull_id>.
		var expected_id := ShipPartDefinition.make_id(slot, hull.id)
		if part.id != expected_id:
			r.error("rule 4: %s id '%s' should be '%s'" % [p, part.id, expected_id])
		# Rule 0 (part side).
		var authored := part.authored_up_to_level
		if authored < 1 or authored > hull.authored_up_to_level:
			r.error("rule 0: %s authored_up_to_level %d not in 1..%d (hull)" % [p, authored, hull.authored_up_to_level])
		min_authored = mini(min_authored, authored)
		# Rule 3: at least authored levels, at most 3, ordered L1, L2, L3.
		if part.levels.size() > ShipHullDefinition.MAX_PART_LEVEL:
			r.error("rule 3: %s has %d levels, max %d" % [p, part.levels.size(), ShipHullDefinition.MAX_PART_LEVEL])
		if part.levels.size() < authored:
			r.error("rule 3: %s has %d levels, authored_up_to_level is %d" % [p, part.levels.size(), authored])
			parts_ok = false
		elif part.levels.size() < ShipHullDefinition.MAX_PART_LEVEL:
			r.warn("W3: %s has only %d of %d levels" % [p, part.levels.size(), ShipHullDefinition.MAX_PART_LEVEL])
		for i in part.levels.size():
			var lvl := part.levels[i]
			var n := i + 1
			var pl := "%s L%d" % [p, n]
			var is_authored := n <= authored
			if lvl == null:
				if is_authored:
					r.error("rule 3: %s is null" % pl)
					parts_ok = false
				else:
					r.warn("W3: %s is missing" % pl)
				continue
			if lvl.level != n:
				r.error("rule 3: %s has level %d" % [pl, lvl.level])
			for m: StatModifier in lvl.modifiers:
				if m == null:
					r.error("%s: null modifier" % pl)
				elif not ShipStat.is_valid(m.stat):
					r.error("%s: unknown stat '%s' in modifier" % [pl, m.stat])
				elif m.op == StatModifier.Op.MUL and not hull.base_stats.has(m.stat):
					r.warn("W1: %s MUL modifier on '%s', which is not in base_stats (dropped)" % [pl, m.stat])
			if not is_authored:
				if lvl.scene_path == "" or lvl.modifiers.is_empty() or (n > 1 and lvl.cost.is_empty()):
					r.warn("W3: %s (above authored_up_to_level) has missing model, cost or values" % pl)
				if lvl.scene_path != "":
					_check_scene_path(r, hull.id, key, n, lvl.scene_path, pl, false)
				continue
			# Rule 4: scene_path required, exists, follows the naming pattern.
			if _check_scene_path(r, hull.id, key, n, lvl.scene_path, pl, require_assets):
				_check_model_empties(r, hull, slot, lvl.scene_path, pl)
			# Rule 5: costs.
			_check_cost(r, lvl, n, pl, mode)

	if not parts_ok:
		return r

	# Rule 6: caps, checked on uncapped values with every part at L1, L2, L3.
	var top := ShipHullDefinition.MAX_PART_LEVEL
	for n in range(1, top + 1):
		var raw := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, n), false)
		for stat: StringName in hull.upgrade_caps.keys():
			var cap: float = hull.upgrade_caps[stat]
			var v: float = raw.get(stat, 0.0)
			var lower := ShipStat.is_lower_better(stat)
			if (not lower and v > cap + EPS) or (lower and v < cap - EPS):
				r.error("rule 6: %s %s at L%d = %s is past cap %s" % [h, stat, n, v, cap])
			elif n == top and min_authored >= top and absf(v - cap) > EPS:
				r.error("rule 6: %s %s at L3 = %s must equal cap %s" % [h, stat, v, cap])

	# Rule 8 (main stat) / W2 (secondary stats): absolute values never get worse.
	for slot: int in ShipPartDefinition.Slot.values():
		var part := hull.get_part(slot)
		var key := ShipPartDefinition.slot_key(slot)
		for n in range(1, part.get_max_level()):
			var prev := _part_stats(part.get_level(n))
			var cur := _part_stats(part.get_level(n + 1))
			for s: StringName in cur.keys():
				var lower := ShipStat.is_lower_better(s)
				var a: float = prev.get(s, 0.0)
				var b: float = cur[s]
				if (not lower and b < a - EPS) or (lower and b > a + EPS):
					var msg := "%s.%s %s L%d = %s, L%d = %s" % [h, key, s, n, a, n + 1, b]
					if s == MAIN_STAT[key]:
						r.error("rule 8: " + msg)
					else:
						r.warn("W2: " + msg)

	# Rule 9: storage_<phase> <= carry_capacity at every authored level.
	for n in range(1, min_authored + 1):
		var stats := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, n))
		var carry: float = stats.get(ShipStat.CARRY_CAPACITY, 0.0)
		for stat: StringName in STORAGE_STATS:
			if stats.get(stat, 0.0) > carry + EPS:
				r.error("rule 9: %s %s at L%d exceeds carry_capacity %s" % [h, stat, n, carry])

	# Rule 7: fuel stats live in hull base_stats.
	for stat: StringName in FUEL_STATS:
		if not hull.base_stats.has(stat):
			r.error("rule 7: %s base_stats has no '%s'" % [h, stat])
	return r


static func _check_cost(r: Result, lvl: ShipPartLevel, n: int, label: String, mode: Mode) -> void:
	var has_credits := false
	var has_items := false
	for c: CostEntry in lvl.cost:
		if c == null or c.item_id == &"" or c.amount <= 0:
			r.error("rule 5: %s has an invalid cost entry" % label)
			continue
		if c.item_id == CREDITS:
			has_credits = true
		else:
			has_items = true
	if n == 1:
		if not lvl.cost.is_empty():
			r.error("rule 5: %s must have an empty cost" % label)
		return
	if lvl.cost.is_empty():
		r.error("rule 5: %s has no upgrade cost" % label)
		return
	if mode == Mode.MVP:
		if has_items or not has_credits:
			r.error("rule 5 (MVP, D-011): %s cost must be credits only" % label)
	elif n == 2 and has_credits:
		r.error("rule 5: %s cost must not contain credits" % label)
	elif n == 3 and not (has_credits and has_items):
		r.error("rule 5: %s cost needs a resource and credits" % label)


## Absolute ADD contribution of one level per stat (rule 8 / W2).
static func _part_stats(lvl: ShipPartLevel) -> Dictionary[StringName, float]:
	var out: Dictionary[StringName, float] = {}
	if lvl == null:
		return out
	for m: StatModifier in lvl.modifiers:
		if m != null and m.op == StatModifier.Op.ADD:
			out[m.stat] = out.get(m.stat, 0.0) + m.value
	return out


## Returns true when the scene exists and can be inspected further.
static func _check_scene_path(r: Result, hull_id: StringName, key: StringName, n: int, path: String, label: String, require_exists: bool) -> bool:
	var stem := "%s/%s/%s_L%d" % [MODEL_ROOT, hull_id, key, n]
	if path == "":
		r.error("rule 4: %s has no scene_path" % label)
		return false
	if path != stem + ".glb" and path != stem + ".tscn":
		r.error("rule 4: %s scene_path '%s' should be '%s.glb' (or .tscn)" % [label, path, stem])
		return false
	if not ResourceLoader.exists(path):
		if require_exists:
			r.error("rule 4: %s scene '%s' does not exist" % [label, path])
		else:
			r.warn("rule 4: %s scene '%s' does not exist yet" % [label, path])
		return false
	return true


## §7: body carries Socket_Head/Wings/Engine and every Hardpoint_<position>;
## engine carries FX_EngineTrail_0.
static func _check_model_empties(r: Result, hull: ShipHullDefinition, slot: int, path: String, label: String) -> void:
	if slot != ShipPartDefinition.Slot.BODY and slot != ShipPartDefinition.Slot.ENGINE:
		return
	var packed := load(path) as PackedScene
	if packed == null:
		r.error("rule 4: %s '%s' is not a scene" % [label, path])
		return
	var inst := packed.instantiate()
	if slot == ShipPartDefinition.Slot.BODY:
		for socket in BODY_SOCKETS:
			if inst.find_child(socket, true, false) == null:
				r.error("%s: body model has no '%s'" % [label, socket])
		for hp: StringName in hull.hardpoints:
			if inst.find_child("Hardpoint_" + String(hp), true, false) == null:
				r.error("%s: body model has no 'Hardpoint_%s'" % [label, hp])
	elif inst.find_child("FX_EngineTrail_0", true, false) == null:
		r.warn("%s: engine model has no 'FX_EngineTrail_0'" % label)
	inst.free()


static func _matches(pattern: String, value: StringName) -> bool:
	return RegEx.create_from_string(pattern).search(String(value)) != null
