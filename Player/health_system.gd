extends Node
class_name HealthSystem

signal health_changed(new_health: float)
signal radiation_changed(radiation: float, stage: int)
signal died
signal protection_changed(resistance: float, timer: float)
@export var max_health: float = 100.0

var health: float = 100.0
var radiation: float = 0.0
var radiation_stage: int = 0

# Входящая радиация от зон
var environment_radiation: float = 0.0

# Защита от радиации (от водки)
var radiation_resistance: float = 0.0
var resistance_timer: float = 0.0

# Отравление (плесень)
var poison_damage_per_sec: float = 0.0

func _ready():
	health = max_health
	radiation = 0.0

func _process(delta):
	process_resistance_timer(delta)
	process_environment_radiation(delta)
	process_poison_damage(delta)

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
	
	if environment_radiation > 0:
		# Асимптотическое снижение: чем больше защиты, тем меньше радиация
		var reduction_factor = 1.0 / (1.0 + radiation_resistance / 100.0)
		var actual_radiation = environment_radiation * reduction_factor
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
	
	var radiation_damage = get_radiation_damage()
	if radiation_damage > 0:
		health -= radiation_damage * delta
		if health <= 0:
			health = 0
			died.emit()
		health_changed.emit(health)

func process_poison_damage(delta):
	if poison_damage_per_sec > 0:
		health -= poison_damage_per_sec * delta
		if health <= 0:
			health = 0
			died.emit()
		health_changed.emit(health)

func update_radiation_stage():
	if radiation < 30:
		radiation_stage = 0
	elif radiation < 60:
		radiation_stage = 1
	elif radiation < 100:
		radiation_stage = 2
	else:
		radiation_stage = 3

func get_radiation_damage() -> float:
	match radiation_stage:
		0: return 0.0
		1: return 2.0
		2: return 5.0
		3: return 10.0 + (radiation - 100) * 0.5  # растёт с переизбытком
	return 0.0

# ========== ВНЕШНИЕ ВОЗДЕЙСТВИЯ ==========

func apply_environment_radiation(amount: float):
	environment_radiation = amount

func stop_environment_radiation():
	environment_radiation = 0.0

func apply_poison_damage(amount: float):
	poison_damage_per_sec = amount

func stop_poison_damage():
	poison_damage_per_sec = 0.0

func heal_health(amount: float):
	health = min(health + amount, max_health)
	health_changed.emit(health)

# ========== ПРЕДМЕТЫ ==========

func use_moonshine():
	radiation = max(radiation - 10, 0)
	radiation_resistance = radiation_resistance + 0.5  # без лимита
	resistance_timer = 20.0

func use_antirad():
	radiation = max(radiation - 30, 0)
	update_radiation_stage()
	radiation_changed.emit(radiation, radiation_stage)
