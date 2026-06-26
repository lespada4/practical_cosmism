extends Node
class_name HealthSystem

signal health_changed(new_health: float)
signal radiation_changed(radiation: float, stage: int)
signal died
signal protection_changed(resistance: float, timer: float)
signal damage_taken(amount: float, damage_type: int)

@onready var geiger_tick: AudioStreamPlayer = $GeigerTick

@export var max_health: float = 100.0
@export var max_radiation: float = 100.0

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

# Гейгер
var tick_timer: float = 0.0
var current_tick_interval: float = 2.0
var active_radiation_timer: float = 0.0  # сколько времени игрок активно получает радиацию

func _ready():
	add_to_group("health_system")
	health = max_health
	radiation = 0.0
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

func _cleanup_invalid_zones():
	derad_zones = derad_zones.filter(func(z): return is_instance_valid(z))

func _on_derad_active_changed(_active: bool):
	_cleanup_invalid_zones()
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	for zone in derad_zones:
		if zone.is_player_in_zone(player) and zone.is_active:
			derad_zone_count += 1
			return
	
	derad_zone_count = 0

func _on_player_entered_derad_zone():
	_cleanup_invalid_zones()
	
	var player = get_tree().get_first_node_in_group("player")
	for zone in derad_zones:
		if zone.is_player_in_zone(player) and zone.is_active:
			derad_zone_count += 1
			return

func _on_player_exited_derad_zone():
	_cleanup_invalid_zones()
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
		var damage_this_frame = radiation_damage * delta
		health -= damage_this_frame
		if health <= 0:
			health = 0
			died.emit()
		health_changed.emit(health)
		
		if Engine.get_physics_frames() % 60 == 0:
			damage_taken.emit(damage_this_frame * 2, 1)
	
	# Гейгер
	_update_geiger(delta)

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
		return
	
	# Активная радиация от зон
	var is_active_radiation = false
	
	if environment_radiation > 0:
		var reduction = min(radiation_resistance / 100.0, 0.8)
		var actual_radiation = environment_radiation * (1.0 - reduction)
		radiation += actual_radiation * delta
		changed = true
		is_active_radiation = true
		
	elif environment_radiation == 0 and radiation > 0:
		if radiation_stage <= 2:
			radiation -= 10.0 * delta
			if radiation < 0:
				radiation = 0
			changed = true
	
	# Обновляем таймер активной радиации
	if is_active_radiation:
		active_radiation_timer += delta
	else:
		active_radiation_timer = max(active_radiation_timer - delta * 2, 0.0)
	
	if changed:
		update_radiation_stage()
		radiation_changed.emit(radiation, radiation_stage)

func process_inventory_radiation(delta):
	if is_in_derad_zone():
		if radiation > 0:
			radiation = max(radiation - 15.0 * delta, 0.0)
			update_radiation_stage()
			radiation_changed.emit(radiation, radiation_stage)
		return
	
	var is_active_radiation = false
	
	if inventory_radiation > 0:
		var reduction = min(radiation_resistance / 100.0, 0.8)
		var actual_radiation = inventory_radiation * (1.0 - reduction)
		radiation += actual_radiation * delta
		update_radiation_stage()
		radiation_changed.emit(radiation, radiation_stage)
		is_active_radiation = true
	
	if is_active_radiation:
		active_radiation_timer += delta
	else:
		active_radiation_timer = max(active_radiation_timer - delta * 2, 0.0)

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

@export var tick_pitch_min: float = 0.98
@export var tick_pitch_max: float = 1

@export var min_tick_interval: float = 0.2  # минимальный интервал между тиками
@export var max_tick_interval: float = 0.8   # максимальный интервал между тиками

func _update_geiger(delta):
	# Определяем интервал тика
	var interval = max_tick_interval
	
	if radiation <= 0:
		interval = 999.0  # не тикаем
	elif active_radiation_timer > 1.0:
		# Активный режим: частота зависит от длительности нахождения в радиации
		var intensity = clamp(active_radiation_timer / 5.0, 0.0, 1.0)
		interval = lerp(0.8, min_tick_interval, intensity)
	else:
		# Пассивный режим: частота зависит от уровня радиации
		var t = clamp(radiation / max_radiation, 0.0, 1.0)
		interval = lerp(max_tick_interval, min_tick_interval, t)
	
	# Принудительно ограничиваем интервал
	interval = max(interval, min_tick_interval)
	
	current_tick_interval = interval
	tick_timer += delta
	
	if tick_timer >= current_tick_interval and radiation > 0:
		tick_timer = 0.0
		_play_geiger_tick()

func _play_geiger_tick():
	if not geiger_tick:
		return
	
	# Случайный питч в небольшом диапазоне
	geiger_tick.pitch_scale = randf_range(tick_pitch_min, tick_pitch_max)
	geiger_tick.play()

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

func take_damage(amount: float, damage_type: int = 0):
	if amount <= 0:
		return
	
	health -= amount
	if health <= 0:
		health = 0
		died.emit()
	
	health_changed.emit(health)
	damage_taken.emit(amount, damage_type)

func use_moonshine():
	radiation = max(radiation - 15, 0)
	radiation_resistance = radiation_resistance + 40
	resistance_timer = 20.0
	
	update_radiation_stage()
	radiation_changed.emit(radiation, radiation_stage)
	protection_changed.emit(radiation_resistance, resistance_timer)

func use_antirad():
	radiation = max(radiation - 30, 0)
	update_radiation_stage()
	radiation_changed.emit(radiation, radiation_stage)

func use_cockroach():
	health = min(health + 5, max_health)
	health_changed.emit(health)
