extends Node
class_name HealthSystem

signal health_changed(new_health: float)
signal radiation_changed(radiation: float, stage: int)
signal died
signal protection_changed(resistance: float, timer: float)

@onready var geiger_light: AudioStreamPlayer = $GeigerLight
@onready var geiger_mid: AudioStreamPlayer = $GeigerMid
@onready var geiger_heavy: AudioStreamPlayer = $GeigerHeavy

@export var max_health: float = 100.0

var health: float = 100.0
var radiation: float = 0.0
var radiation_stage: int = 0
var last_stage: int = -1

var environment_radiation: float = 0.0
var radiation_resistance: float = 0.0
var resistance_timer: float = 0.0
var poison_damage_per_sec: float = 0.0
var inventory_radiation: float = 0.0

var derad_zone_count: int = 0
var derad_zones: Array = []

func _ready():
	health = max_health
	radiation = 0.0
	update_geiger_sound()
	call_deferred("connect_to_derad_zones")

func connect_to_derad_zones():
	for zone in get_tree().get_nodes_in_group("derad_zones"):
		_connect_to_zone(zone)

func _connect_to_zone(zone):
	if zone not in derad_zones:
		derad_zones.append(zone)
	
	if zone.has_signal("player_entered_zone"):
		if not zone.player_entered_zone.is_connected(_on_player_entered_derad_zone):
			zone.player_entered_zone.connect(_on_player_entered_derad_zone)
	if zone.has_signal("player_exited_zone"):
		if not zone.player_exited_zone.is_connected(_on_player_exited_derad_zone):
			zone.player_exited_zone.connect(_on_player_exited_derad_zone)
	if zone.has_signal("active_state_changed"):
		if not zone.active_state_changed.is_connected(_on_derad_active_changed):
			zone.active_state_changed.connect(_on_derad_active_changed)

func _on_derad_active_changed(_active: bool):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	for zone in derad_zones:
		if zone.is_player_in_zone(player) and zone.is_active:
			derad_zone_count += 1
			return
	
	derad_zone_count = 0

func _on_player_entered_derad_zone():
	var player = get_tree().get_first_node_in_group("player")
	for zone in derad_zones:
		if zone.is_player_in_zone(player) and zone.is_active:
			derad_zone_count += 1
			return

func _on_player_exited_derad_zone():
	derad_zone_count -= 1
	if derad_zone_count < 0:
		derad_zone_count = 0

func is_in_derad_zone() -> bool:
	return derad_zone_count > 0

func _process(delta):
	process_resistance_timer(delta)
	process_environment_radiation(delta)
	process_inventory_radiation(delta)
	process_poison_damage(delta)
	
	var radiation_damage = get_radiation_damage()
	if radiation_damage > 0:
		health -= radiation_damage * delta
		if health <= 0:
			health = 0
			died.emit()
		health_changed.emit(health)

func process_resistance_timer(delta):
	if resistance_timer > 0:
		resistance_timer -= delta
		if resistance_timer <= 0:
			radiation_resistance = 0.0
			protection_changed.emit(radiation_resistance, resistance_timer)
		else:
			protection_changed.emit(radiation_resistance, resistance_timer)

func process_environment_radiation(delta):
	var changed = false
	
	if is_in_derad_zone():
		if radiation > 0:
			radiation = max(radiation - 15.0 * delta, 0.0)
			changed = true
		update_radiation_stage()
		radiation_changed.emit(radiation, radiation_stage)
		update_geiger_sound()
		return
	
	if environment_radiation > 0:
		var reduction = min(radiation_resistance / 100.0, 0.8)
		var actual_radiation = environment_radiation * (1.0 - reduction)
		radiation += actual_radiation * delta
		changed = true
		
	elif environment_radiation == 0 and radiation > 0:
		if radiation_stage <= 2:
			radiation -= 10.0 * delta
			if radiation < 0:
				radiation = 0
			changed = true
	
	if changed:
		update_radiation_stage()
		radiation_changed.emit(radiation, radiation_stage)
		update_geiger_sound()

func process_inventory_radiation(delta):
	if is_in_derad_zone():
		if radiation > 0:
			radiation = max(radiation - 15.0 * delta, 0.0)
			update_radiation_stage()
			radiation_changed.emit(radiation, radiation_stage)
			update_geiger_sound()
		return
	
	if inventory_radiation > 0:
		var reduction = min(radiation_resistance / 100.0, 0.8)
		var actual_radiation = inventory_radiation * (1.0 - reduction)
		radiation += actual_radiation * delta
		update_radiation_stage()
		radiation_changed.emit(radiation, radiation_stage)
		update_geiger_sound()

func process_poison_damage(delta):
	if poison_damage_per_sec > 0:
		health -= poison_damage_per_sec * delta
		if health <= 0:
			health = 0
			died.emit()
		health_changed.emit(health)

func update_radiation_stage():
	if radiation < 10:
		radiation_stage = 0
	elif radiation < 40:
		radiation_stage = 1
	elif radiation < 80:
		radiation_stage = 2
	elif radiation < 120:
		radiation_stage = 3
	else:
		radiation_stage = 4

func get_radiation_damage() -> float:
	match radiation_stage:
		0, 1: return 0.0
		2: return 2.0
		3: return 5.0
		4: return 10.0 + (radiation - 120) * 0.5
	return 0.0

func update_geiger_sound():
	if radiation_stage == last_stage:
		return
	
	last_stage = radiation_stage
	
	geiger_light.stop()
	geiger_mid.stop()
	geiger_heavy.stop()
	
	match radiation_stage:
		0: return
		1, 2:
			geiger_light.play()
		3:
			geiger_mid.play()
		4:
			geiger_heavy.play()

func apply_environment_radiation(amount: float):
	environment_radiation = amount

func stop_environment_radiation():
	environment_radiation = 0.0

func apply_poison_damage(amount: float):
	poison_damage_per_sec = amount

func stop_poison_damage():
	poison_damage_per_sec = 0.0

func apply_inventory_radiation(amount: float):
	inventory_radiation = amount

func heal_health(amount: float):
	health = min(health + amount, max_health)
	health_changed.emit(health)

func use_moonshine():
	radiation = max(radiation - 15, 0)
	radiation_resistance = radiation_resistance + 40
	resistance_timer = 20.0
	
	update_radiation_stage()
	radiation_changed.emit(radiation, radiation_stage)
	protection_changed.emit(radiation_resistance, resistance_timer)
	update_geiger_sound()

func use_antirad():
	radiation = max(radiation - 30, 0)
	update_radiation_stage()
	radiation_changed.emit(radiation, radiation_stage)
	update_geiger_sound()

func use_cockroach():
	health = min(health + 5, max_health)
	health_changed.emit(health)
