class_name TestShips
## Builders for synthetic ship data used by unit tests.


static func mod(stat: StringName, value: float, op: StatModifier.Op = StatModifier.Op.ADD) -> StatModifier:
	var m := StatModifier.new()
	m.stat = stat
	m.op = op
	m.value = value
	return m


## Hull with 4 parts x 3 empty levels and no scene paths.
static func make_hull(base: Dictionary[StringName, float], caps: Dictionary[StringName, float], hull_id: StringName = &"test_hull_01") -> ShipHullDefinition:
	var h := ShipHullDefinition.new()
	h.id = hull_id
	h.base_stats = base
	h.upgrade_caps = caps
	for slot: int in ShipPartDefinition.Slot.values():
		var p := ShipPartDefinition.new()
		p.slot = slot as ShipPartDefinition.Slot
		p.hull_id = h.id
		p.id = ShipPartDefinition.make_id(p.slot, h.id)
		for n: int in [1, 2, 3]:
			var l := ShipPartLevel.new()
			l.level = n
			p.levels.append(l)
		match slot:
			ShipPartDefinition.Slot.HEAD: h.head = p
			ShipPartDefinition.Slot.BODY: h.body = p
			ShipPartDefinition.Slot.WINGS: h.wings = p
			_: h.engine = p
	return h
