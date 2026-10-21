class_name MvpGame
extends Node3D
## Root of scenes/main/mvp_sector.tscn. Starts the GameState session and wires
## the Gameplay Designer's player ship (scenes/ship/player_ship.tscn) and
## camera with the station, asteroid field, pickup pool, FX and HUD.
## Loop (mvp.md §1): fly -> mine -> break -> collect -> dock -> sell -> upgrade.

@export var hull: ShipHullDefinition
@export var sector: SectorDefinition

@onready var ship: ShipController = $PlayerShip
@onready var camera: GameCamera = $GameCamera
@onready var station: StationDock = $Station
@onready var field: AsteroidField = $AsteroidField
@onready var pickups: PickupPool = $PickupPool
@onready var fx: MvpFxBridge = $FxBridge
@onready var hud: MvpDebugHud = $DebugHud
@onready var world_env: WorldEnvironment = $WorldEnvironment

var assembler: ShipAssembler
var laser: MiningLaser


func _ready() -> void:
	GameState.start_session(hull, sector.resources, sector.starting_credits)
	EventBus.cargo_changed.connect(_on_cargo_changed)

	assembler = find_ship_assembler(ship)
	laser = ship.find_child("MiningLaser", true, false) as MiningLaser
	if assembler == null:
		push_error("MvpGame: player ship has no ShipAssembler")
		return
	station.position = sector.station_position
	var spawn := Transform3D(Basis.IDENTITY, sector.player_spawn)
	ship.global_transform = spawn
	ship.set_spawn(spawn)
	ship.fuel_enabled = false
	if hull.flight_tuning != null:
		ship.tuning = hull.flight_tuning

	assembler.follow_part_upgrades = true
	assembler.build(hull, GameState.ship_state)
	ship.ship_state = GameState.ship_state
	ship.set_resolved_stats(GameState.get_stats())
	ship.hull = ship.get_stat(ShipController.STAT_HULL)
	if laser != null:
		laser.setup(ship, assembler)
	fx.setup(ship, assembler, world_env)
	camera.set_target(ship)
	hud.setup(self)

	pickups.target = ship
	field.pickup_pool = pickups
	field.avoid_target = ship
	field.spawn_all()


## Robust lookup: the controller's assembler, then its assembler_path, then any
## ShipAssembler below the ship (engineering brief: Visual/ShipAssembler).
static func find_ship_assembler(p_ship: ShipController) -> ShipAssembler:
	if p_ship == null:
		return null
	if p_ship.assembler != null:
		return p_ship.assembler
	var node := p_ship.get_node_or_null(p_ship.assembler_path) as ShipAssembler
	if node != null:
		return node
	for n: Node in p_ship.find_children("*", "Node3D", true, false):
		if n is ShipAssembler:
			return n as ShipAssembler
	return null


func _physics_process(dt: float) -> void:
	# Soft boundary (mvp.md §3): past boundary_radius, push the ship back in.
	var offset := ship.global_position - sector.station_position
	offset.y = 0.0
	var past := offset.length() - sector.boundary_radius
	if past > 0.0:
		var push := minf(past * sector.boundary_push, 60.0)
		ship.velocity -= offset.normalized() * push * dt


func is_docked() -> bool:
	return station.docked


func _on_cargo_changed(_used: int, _capacity: int) -> void:
	ship.cargo_mass = GameState.get_cargo_mass()
