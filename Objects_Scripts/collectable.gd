extends Area3D

var item_id: int = 0
var amount: int = 1
var can_collect: bool = false
var fall_velocity: float = 0.0
var fall_gravity: float = 15.0
var is_falling: bool = true

@onready var sprite: Sprite3D = $Sprite3D
@onready var ground_check: RayCast3D = $GroundCheck

func setup(item_resource: Item, item_amount: int):
	item_id = item_resource.id
	amount = item_amount
	
	if sprite and item_resource.icon:
		sprite.texture = item_resource.icon
	
	body_entered.connect(_on_body_entered)

func _ready():
	await get_tree().create_timer(1.0).timeout
	can_collect = true

func _physics_process(delta):
	sprite.rotate_y(delta * 1.5)
	
	# Проверка, есть ли земля под предметом
	ground_check.force_raycast_update()
	var has_ground = ground_check.is_colliding()
	
	if has_ground:
		if is_falling:
			# Приземлились
			var hit_point = ground_check.get_collision_point()
			position.y = hit_point.y + 0.2
			is_falling = false
			fall_velocity = 0
	else:
		# Нет земли — падаем
		if not is_falling:
			# Только что потеряли землю
			is_falling = true
			fall_velocity = 0
		else:
			# Продолжаем падать
			fall_velocity -= fall_gravity * delta
			position.y += fall_velocity * delta

func _on_body_entered(body):
	if body.name == "Player" and can_collect:
		body.collect_item(item_id, amount)
		queue_free()
