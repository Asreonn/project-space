class_name FlightTuning
extends Resource
## Uçuş hissi + kamera parametreleri (gemi modelinin karakteri; upgrade edilen stat değil).
## Kaynak: docs/design/m1_flight_tuning.md. Bütün değerler balance_prototype.
## Not: flying_speed / maneuver_speed / mass gibi STAT'lar burada yalnızca "default_*" olarak durur;
## ShipStatsResolver gelince ShipController.set_resolved_stats() ile ezilir.

@export var balance_prototype: bool = true

@export_group("Stat defaults (adapter)")
@export_range(4.0, 30.0, 0.1) var default_flying_speed: float = 12.0  ## m/s, ileri seyir tavanı (Engine)
@export_range(60.0, 720.0, 1.0) var default_maneuver_speed: float = 270.0  ## deg/s, azami dönüş hızı (Wings)
@export_range(1.0, 100.0, 0.1) var default_mass: float = 10.0  ## t, parçaların kuru kütlesi
@export_range(1.0, 1000.0, 1.0) var default_fuel_capacity: float = 100.0  ## FU
@export_range(0.0, 5.0, 0.01) var default_fuel_rate: float = 0.2  ## FU/s, tam itkide
@export_range(1.0, 1000.0, 1.0) var default_hull: float = 100.0  ## HP

@export_group("Control")
## 0 = A: WASD + burun fareye (varsayılan), 1 = B: W/S itki + A/D dönüş
@export_enum("A_MouseNose", "B_TankTurn") var control_scheme: int = 0

@export_group("Thrust")
@export_range(0.1, 3.0, 0.01) var accel_time_to_max: float = 0.7  ## s, 0 -> flying_speed (a = v / t)
@export_range(0.0, 1.0, 0.01) var reverse_thrust_ratio: float = 0.5  ## S itkisi / W itkisi
@export_range(0.0, 1.0, 0.01) var strafe_speed_ratio: float = 0.4  ## yanal hedef hız / flying_speed
@export_range(30.0, 720.0, 1.0) var maneuver_reference: float = 270.0  ## deg/s, man_k = maneuver_speed / bu

@export_group("Damping")
@export_range(0.1, 20.0, 0.05) var lateral_grip: float = 4.0  ## 1/s, yanal hızın burna hizalanması
@export_range(0.0, 5.0, 0.05) var coast_damp: float = 0.8  ## 1/s, itki yokken boyuna sönüm
@export_range(0.1, 15.0, 0.05) var brake_damp: float = 3.5  ## 1/s, Space fren (her yönde)
@export_range(0.1, 15.0, 0.05) var overspeed_decay: float = 3.0  ## 1/s, tavan üstü hızın sönümü

@export_group("Drift")
@export_range(0.0, 1.0, 0.01) var drift_grip_mult: float = 0.08  ## grip çarpanı (Space+W)
@export_range(0.0, 3.0, 0.01) var drift_damp: float = 0.15  ## 1/s
@export_range(0.0, 1.0, 0.01) var drift_thrust_mult: float = 0.6
@export_range(0.5, 2.0, 0.01) var drift_turn_mult: float = 1.2

@export_group("Turn")
@export_range(0.5, 40.0, 0.1) var turn_gain: float = 10.0  ## 1/s, açı hatası -> hedef açısal hız
@export_range(1.0, 60.0, 0.5) var turn_response: float = 26.0  ## 1/s, açısal hızın hedefe yaklaşması

@export_group("Boost")
@export_range(1.0, 3.0, 0.01) var boost_speed_mult: float = 1.6
@export_range(1.0, 5.0, 0.01) var boost_accel_mult: float = 2.0
@export_range(0.1, 5.0, 0.05) var boost_max_duration: float = 1.2  ## s
@export_range(0.0, 10.0, 0.05) var boost_cooldown: float = 2.0  ## s, bitişten itibaren
@export_range(0.0, 20.0, 0.1) var boost_start_fuel: float = 1.0  ## FU
@export_range(0.0, 20.0, 0.1) var boost_fuel_per_s: float = 2.0  ## FU/s
@export_range(0.0, 50.0, 0.5) var boost_min_fuel: float = 5.0  ## FU

@export_group("Fuel")
@export_range(0.0, 1.0, 0.01) var fuel_idle_ratio: float = 0.1  ## boştayken fuel_rate oranı
@export_range(0.05, 1.0, 0.01) var limp_speed_mult: float = 0.35  ## yakıt 0'da tavan çarpanı

@export_group("Mass")
## M1 Laser-only: L1 parçalar 10 t + laser 0.3 + blaster 0.3 = 10.6 t (tasarım dokümanındaki 11.5 dört modül içindi)
@export_range(1.0, 100.0, 0.1) var reference_mass: float = 10.6  ## t, his = 1.0 olan kütle
@export_range(0.0, 20.0, 0.1) var loadout_mass: float = 0.6  ## t, geçici: modül kütlesi (ModuleDefinition gelince)
@export_range(0.0, 2.0, 0.05) var mass_exp_accel: float = 0.7
@export_range(0.0, 2.0, 0.05) var mass_exp_turn: float = 0.5
@export_range(0.0, 2.0, 0.05) var mass_exp_brake: float = 0.5

@export_group("Collision")
@export_range(0.0, 1.0, 0.01) var collision_restitution: float = 0.3
@export_range(0.0, 30.0, 0.5) var collision_damage_threshold: float = 6.0  ## m/s
@export_range(0.0, 20.0, 0.1) var collision_damage_per_mps: float = 2.0  ## HP / (m/s)

@export_group("Camera")
@export var camera_perspective: bool = false  ## false = orthographic (M1 varsayılanı)
@export_range(15.0, 70.0, 0.5) var camera_fov: float = 35.0  ## deg, yalnız perspektif
@export_range(0.0, 45.0, 0.5) var camera_tilt_deg: float = 10.0  ## dikeyden eğim
@export var ortho_sizes: PackedFloat32Array = PackedFloat32Array([30.0, 40.0, 52.0])  ## m, dikey görüş (zoom kademeleri)
@export_range(0, 2) var default_zoom_index: int = 1
@export_range(10.0, 300.0, 1.0) var ortho_camera_distance: float = 60.0  ## m, ortho'da yalnız kırpma için
@export_range(0.5, 30.0, 0.1) var follow_rate: float = 8.0  ## 1/s
@export_range(0.0, 1.5, 0.01) var look_ahead_time: float = 0.35  ## s
@export_range(0.0, 20.0, 0.1) var look_ahead_max: float = 6.0  ## m
@export_range(0.1, 20.0, 0.1) var look_ahead_rate: float = 3.0  ## 1/s
@export_range(0.0, 1.0, 0.01) var aim_offset_ratio: float = 0.15
@export_range(0.0, 20.0, 0.1) var aim_offset_max: float = 4.0  ## m
@export_range(0.5, 30.0, 0.1) var zoom_rate: float = 6.0  ## 1/s
@export_range(0.0, 1.0, 0.01) var boost_zoom_out: float = 0.12  ## oran
