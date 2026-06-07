extends Area3D

var item_id: int = 0
var amount: int = 1
var can_collect: bool = false
var velocity: Vector3 = Vector3.ZERO
var fall_gravity: float = 15.0
var grounded: bool = false

@onready var sprite: Sprite3D = $Sprite3D
@onready var ground_check: RayCast3D = $GroundCheck

func setup(item_resource: Item, item_amount: int):
	item_id = item_resource.id
	amount = item_amount
	
	if sprite and item_resource.icon:
		sprite.texture = item_resource.icon
	
	body_entered.connect(_on_body_entered)

func apply_velocity(vel: Vector3):
	velocity = vel

func _ready():
	await get_tree().create_timer(1.0).timeout
	can_collect = true

func _physics_process(delta):
	sprite.rotate_y(delta * 3.0)
	
	if not grounded:
		velocity.y -= fall_gravity * delta
		position += velocity * delta
		
		ground_check.force_raycast_update()
		if ground_check.is_colliding():
			var hit_point = ground_check.get_collision_point()
			if position.y <= hit_point.y + 0.2:
				position.y = hit_point.y + 0.2
				velocity.y = 0
				velocity.x *= 0.3
				velocity.z *= 0.3
				grounded = true
				
				if velocity.length() < 0.1:
					velocity = Vector3.ZERO
	else:
		velocity.x *= 0.3
		velocity.z *= 0.3
		position += velocity * delta
		
		if velocity.length() < 0.05:
			velocity = Vector3.ZERO

func _on_body_entered(body):
	if body.name == "Player" and can_collect:
		body.collect_item(item_id, amount)
		queue_free()
