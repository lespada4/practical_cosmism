extends Area3D

@export var mold_spawner: Node3D
@export var damage_per_mold: float = 2.0
@export var safe_mold_limit: int = 3
@export var damage_delay: float = 5.0  # Задержка перед началом урона

var poison_type: int = 2
var current_damage: float = 0.0
var player_in_zone: bool = false
var delay_timer: float = 0.0
var is_damaging: bool = false

func _ready():
	if mold_spawner and mold_spawner.has_signal("mold_count_changed"):
		mold_spawner.mold_count_changed.connect(_on_mold_count_changed)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_mold_count_changed(mold_count: int):
	if mold_count > safe_mold_limit:
		current_damage = (mold_count - safe_mold_limit) * damage_per_mold
	else:
		current_damage = 0.0
		# Если урон стал нулевым — сбрасываем таймер и останавливаем урон
		if current_damage == 0.0 and player_in_zone:
			delay_timer = 0.0
			is_damaging = false
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.stop_damage(poison_type)

func _process(delta):
	if not player_in_zone or current_damage <= 0:
		delay_timer = 0.0
		is_damaging = false
		return
	
	# Нарастание таймера
	delay_timer += delta
	
	# Если таймер превысил задержку и урон ещё не активен — включаем
	if delay_timer >= damage_delay and not is_damaging:
		is_damaging = true
	
	# Наносим урон только если активен
	if is_damaging:
		var bodies = get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				body.apply_damage(current_damage, poison_type)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_zone = true
		delay_timer = 0.0
		is_damaging = false

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_zone = false
		delay_timer = 0.0
		is_damaging = false
		body.stop_damage(poison_type)
