extends CharacterBody3D

@export var speed = 3.0
@export var mouse_sensitivity = 0.002
@export var jump_velocity = 5
@export var head_bob_intensity = 0.05
@export var head_bob_speed = 14.0
@export var coyote_time = 0.1

@onready var health_label: Label = $health_label
@onready var interaction_ray: RayCast3D = $Camera3D/interaction_ray
@onready var inventory_label: Label = $inventory_label
@onready var camera: Camera3D = $Camera3D

var inventory_stacks: Array[ItemStack] = []
var head_bob_time = 0.0
var is_moving = false
var camera_default_height = 0.0
var coyote_timer = 0.0
var radiation = 0.0
var current_damage = 0.0

func _ready():
	camera_default_height = camera.transform.origin.y
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_inventory_display()
	update_health_display()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
	
	if event.is_action_pressed("interact"):
		try_interact()
	
	if event.is_action_pressed("drink"):
		drink_moonshine()

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_moving = input_dir.length() > 0
	
	var current_speed = speed if speed != null else 3.0
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	if is_on_floor():
		coyote_timer = coyote_time if coyote_time != null else 0.1
	else:
		coyote_timer -= delta
	
	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		velocity.y = jump_velocity if jump_velocity != null else 5
	
	velocity.y -= 9.8 * delta
	move_and_slide()
	
	if current_damage > 0:
		radiation += current_damage * delta
		if radiation >= 100:
			die()
		update_health_display()
	
	update_head_bob(delta)

func try_interact():
	if not interaction_ray.is_colliding():
		return
	
	var hit = interaction_ray.get_collider()
	
	if hit.is_in_group("resource") and hit.has_method("collect"):
		hit.collect()
	elif hit.has_method("interact"):
		hit.interact(self)

func collect_item(item_id: int, amount: int):
	add_item_stack(item_id, amount)
	update_inventory_display()

func add_item_stack(item_id: int, amount: int) -> bool:
	var item = ItemRegistry.get_item(item_id)
	if not item:
		return false
	
	for stack in inventory_stacks:
		if stack.item.id == item_id and stack.quantity < item.max_stack:
			var space = item.max_stack - stack.quantity
			var to_add = min(space, amount)
			stack.quantity += to_add
			amount -= to_add
			if amount == 0:
				update_inventory_display()
				return true
	
	while amount > 0:
		var to_add = min(item.max_stack, amount)
		var new_stack = ItemStack.new()
		new_stack.item = item
		new_stack.quantity = to_add
		inventory_stacks.append(new_stack)
		amount -= to_add
	
	update_inventory_display()
	return true

func remove_item_stack(item_id: int, amount: int) -> bool:
	var remaining = amount
	for i in range(inventory_stacks.size() - 1, -1, -1):
		var stack = inventory_stacks[i]
		if stack.item.id == item_id:
			if stack.quantity > remaining:
				stack.quantity -= remaining
				remaining = 0
				update_inventory_display()
				return true
			else:
				remaining -= stack.quantity
				inventory_stacks.remove_at(i)
	
	update_inventory_display()
	return remaining == 0

func get_item_count(item_id: int) -> int:
	var total = 0
	for stack in inventory_stacks:
		if stack.item.id == item_id:
			total += stack.quantity
	return total

func update_inventory_display():
	var iron = get_item_count(1)
	var steel = get_item_count(2)
	var moonshine = get_item_count(3)
	inventory_label.text = "Iron: " + str(iron) + "  Steel: " + str(steel) + "  Moonshine: " + str(moonshine)

func update_health_display():
	health_label.text = "Radiation: " + str(round(radiation)) + "%"

func update_head_bob(delta):
	if is_moving:
		head_bob_time += delta * head_bob_speed
		var vertical = sin(head_bob_time) * head_bob_intensity
		var horizontal = cos(head_bob_time * 0.5) * head_bob_intensity
		camera.transform.origin = Vector3(horizontal, camera_default_height + vertical, 0)
	else:
		head_bob_time = 0
		camera.transform.origin = Vector3(0, camera_default_height, 0)

func apply_damage(amount: float, _type):
	current_damage = amount

func stop_damage(_type):
	current_damage = 0.0

func drink_moonshine():
	if get_item_count(3) > 0:
		remove_item_stack(3, 1)
		radiation = max(radiation - 15, 0)
		update_health_display()
		update_inventory_display()

func die():
	get_tree().reload_current_scene()
