class_name ShipDataValidator
## Editor/test validation of ship data (ship_data_model.md §6, rules 1-7,
## plus the §7 naming standard for hardpoints and model empties).
##
## authored_max_level: highest part level whose content must be filled in.
##   Levels above it only need to exist structurally (rule 3); their scene and
##   cost checks (rules 4, 5) are skipped. M1 ships only L1 content, so M1 uses 1.
##   Final content uses 3 (the contract default).
## require_assets: when false, a scene_path that does not exist yet is reported
##   as a warning instead of an error (models are delivered by the 3D Modeler).

const MODEL_ROOT := "res://assets/models/ships"
const FUEL_STATS: Array[StringName] = [ShipStat.FUEL_CAPACITY, ShipStat.FUEL_RATE]
## Hardpoint ids are the <position> part of Hardpoint_<position>: L, R, Nose, ...
const HARDPOINT_ID_PATTERN := "^[A-Z][A-Za-z0-9]*$"
const BODY_SOCKETS: Array[String] = ["Socket_Head", "Socket_Wings", "Socket_Engine"]


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
static func validate_catalog(hulls: Array[ShipHullDefinition], authored_max_level: int = ShipHullDefinition.MAX_PART_LEVEL, require_assets: bool = true) -> Result:
	var result := Result.new()
	var owner_by_part: Dictionary = {} # ShipPartDefinition or part id -> hull id
	var seen_hull_ids: Dictionary[StringName, bool] = {}
	for hull: ShipHullDefinition in hulls:
		if hull == null:
			result.error("catalog: null hull entry")
			continue
		if seen_hull_ids.has(hull.id):
			result.error("catalog: duplicate hull id '%s'" % hull.id)
		seen_hull_ids[hull.id] = true
		result.merge(validate_hull(hull, authored_max_level, require_assets))
		for slot: int in ShipPartDefinition.Slot.values():
			var part := hull.get_part(slot)
			if part == null:
				continue
			for key: Variant in [part, part.id]:
				if owner_by_part.has(key) and owner_by_part[key] != hull.id:
					result.error("rule 2: part '%s' is used by hulls '%s' and '%s'" % [part.id, owner_by_part[key], hull.id])
				owner_by_part[key] = hull.id
	return result


static func validate_hull(hull: ShipHullDefinition, authored_max_level: int = ShipHullDefinition.MAX_PART_LEVEL, require_assets: bool = true) -> Result:
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
	var seen_hp: Dictionary[StringName, bool] = {}
	for hp: StringName in hull.hardpoints:
		if seen_hp.has(hp):
			r.error("%s: duplicate hardpoint '%s'" % [h, hp])
		seen_hp[hp] = true
		if not _matches(HARDPOINT_ID_PATTERN, hp):
			r.error("%s: hardpoint id '%s' must be a position like L, R, Nose (node Hardpoint_<position>)" % [h, hp])

	var parts_ok := true
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
		var expected_id := ShipPartDefinition.make_id(slot, hull.id)
		if part.id != expected_id:
			r.error("%s: id '%s' should be '%s'" % [p, part.id, expected_id])
		# Rule 3: exactly 3 levels in order L1, L2, L3.
		if part.levels.size() != ShipHullDefinition.MAX_PART_LEVEL:
			r.error("rule 3: %s has %d levels, expected %d" % [p, part.levels.size(), ShipHullDefinition.MAX_PART_LEVEL])
			parts_ok = false
		for i in part.levels.size():
			var lvl := part.levels[i]
			var n := i + 1
			var pl := "%s L%d" % [p, n]
			if lvl == null:
				r.error("rule 3: %s is null" % pl)
				parts_ok = false
				continue
			if lvl.level != n:
				r.error("rule 3: %s has level %d" % [pl, lvl.level])
			for m: StatModifier in lvl.modifiers:
				if m == null:
					r.error("%s: null modifier" % pl)
				elif not ShipStat.is_valid(m.stat):
					r.error("%s: unknown stat '%s' in modifier" % [pl, m.stat])
			var authored := n <= authored_max_level
			# Rule 4: scene_path exists and follows the naming pattern.
			if authored or lvl.scene_path != "":
				if _check_scene_path(r, hull.id, key, n, lvl.scene_path, pl, require_assets and authored):
					_check_model_empties(r, hull, slot, lvl.scene_path, pl)
			# Rule 5: L1 cost empty, L2/L3 cost filled.
			if n == 1:
				if not lvl.cost.is_empty():
					r.error("rule 5: %s must have an empty cost" % pl)
			elif lvl.cost.is_empty() and authored:
				r.error("rule 5: %s has no upgrade cost" % pl)
			for c: CostEntry in lvl.cost:
				if c == null or c.item_id == &"" or c.amount <= 0:
					r.error("rule 5: %s has an invalid cost entry" % pl)

	# Rule 6: resolved stats never exceed upgrade_caps (L3 = cap).
	# Checked with every part at L1, L2 and L3, before the resolver clamp.
	if parts_ok:
		for n in range(1, ShipHullDefinition.MAX_PART_LEVEL + 1):
			var raw := ShipStatsResolver.resolve_raw(hull, ShipInstanceState.create_for(hull, n), false)
			for stat: StringName in raw.keys():
				if hull.upgrade_caps.has(stat) and raw[stat] > hull.upgrade_caps[stat] + 0.0001:
					r.error("rule 6: %s %s at L%d = %s exceeds cap %s" % [h, stat, n, raw[stat], hull.upgrade_caps[stat]])

	# Rule 7: fuel stats live in hull base_stats.
	for stat: StringName in FUEL_STATS:
		if not hull.base_stats.has(stat):
			r.error("rule 7: %s base_stats has no '%s'" % [h, stat])
	return r


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
