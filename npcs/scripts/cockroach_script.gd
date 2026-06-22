extends CharacterBody3D

@export var item_id: int = 8
@export var collectable_scene: PackedScene
@export var speed: float = 1.5
@export var turn_speed: float = 3.0
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var usi: Marker3D = $usi

var direction: Vector3 = Vector3.FORWARD
var stuck_timer: float = 0.0
var last_position: Vector3

func _ready():
	direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	add_to_group("resource")
	last_position = global_position

func _physics_process(delta):
	if global_position.distance_to(last_position) < 0.05:
		stuck_timer += delta
		if stuck_timer > 1.0:
			direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	last_position = global_position
	
	if not is_on_floor():
		velocity.y = -10.0
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	move_and_slide()
	
	if get_last_slide_collision():
		var normal = get_last_slide_collision().get_normal()
		direction = direction.bounce(normal)
		direction.y = 0
		direction = direction.normalized()
	
	var target_angle = atan2(direction.x, direction.z)
	var current_angle = usi.rotation.y
	var new_angle = lerp_angle(current_angle, target_angle, turn_speed * delta)
	usi.rotation.y = new_angle
	sprite_3d.rotation.y = new_angle

func collect():
	var collectable = collectable_scene.instantiate()
	
	# Сначала добавляем в дерево
	get_parent().add_child(collectable)
	
	# Потом настраиваем
	collectable.setup(ItemRegistry.get_item(item_id), 1)
	
	# Затем задаём позицию
	collectable.global_position = global_position + Vector3(0, 0.2, 0)
	
	queue_free()
