extends CharacterBody3D

@export var speed = 3.0
@export var mouse_sensitivity = 0.002
@export var jump_velocity = 6
@export var head_bob_intensity = 0.05
@export var head_bob_speed = 14.0
@export var coyote_time = 0.1
@export var build_distance_min: float = 1
@export var build_distance_max: float = 5.0

@onready var health_label: Label = $health_label
@onready var interaction_ray: RayCast3D = $Camera3D/interaction_ray
@onready var inventory_label: Label = $inventory_label
@onready var camera: Camera3D = $Camera3D
@onready var crosshair: TextureRect = $crosshair

var inventory_stacks: Array[ItemStack] = []
var head_bob_time = 0.0
var is_moving = false
var camera_default_height = 0.0
var coyote_timer = 0.0
var radiation = 0.0
var current_damage = 0.0
var build_distance: float = 3.0

# Строительство
var build_mode: bool = false
var current_ghost: Area3D = null
var current_blueprint_id: String = ""

func _ready():
	camera_default_height = camera.transform.origin.y
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_inventory_display()
	update_health_display()
	add_to_group("player")

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
		
		# Обновляем дальность постройки при движении камеры
		if build_mode:
			update_build_distance_by_camera()
	
	if event.is_action_pressed("interact"):
		if build_mode:
			try_build()
		else:
			try_interact()
	
	if event.is_action_pressed("build_mode"):
		if not build_mode:
			enter_build_mode("still")
		else:
			exit_build_mode()
	
	if event.is_action_pressed("drink"):
		drink_moonshine()
	
	if build_mode and event.is_action_pressed("rotate_building") and current_ghost:
		current_ghost.rotate_y(deg_to_rad(45))

func update_build_distance_by_camera():
	var t = (camera.rotation.x + 1.5) / 3.0
	t = clamp(t, 0.0, 1.0)
	build_distance = lerp(build_distance_min, build_distance_max, t)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_moving = input_dir.length() > 0
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		velocity.y = jump_velocity
	
	# Увеличенная гравитация и ускорение падения
	var gravity = 14.0  # вместо 9.8
	var fall_multiplier = 2.0  # ускорение при падении
	
	if velocity.y < 0:
		velocity.y -= gravity * fall_multiplier * delta
	else:
		velocity.y -= gravity * delta
	
	move_and_slide()
	
	if current_damage > 0:
		radiation += current_damage * delta
		if radiation >= 100:
			die()
		update_health_display()
	
	if build_mode and current_ghost:
		update_ghost_position()
	
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

# ========== СИСТЕМА СТРОИТЕЛЬСТВА ==========

func enter_build_mode(blueprint_id: String):
	var blueprint = BlueprintRegistry.get_blueprint(blueprint_id)
	if not blueprint:
		return
	
	current_blueprint_id = blueprint_id
	build_mode = true
	build_distance = 3.0
	
	current_ghost = preload("res://blueprints/ghost/ghost.tscn").instantiate()
	add_child(current_ghost)
	current_ghost.setup(blueprint)
	crosshair.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func exit_build_mode():
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	build_mode = false
	current_blueprint_id = ""
	crosshair.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_ghost_position():
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var target_pos = camera.global_position + forward * build_distance
	
	var space_state = get_world_3d().direct_space_state
	var ray_start = target_pos + Vector3(0, 2, 0)
	var ray_end = target_pos - Vector3(0, 10, 0)
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		target_pos.y = result.position.y
	
	current_ghost.global_position = target_pos

func try_build():
	if not current_ghost or not current_ghost.get_valid():
		return
	
	var blueprint = BlueprintRegistry.get_blueprint(current_blueprint_id)
	
	for item_id in blueprint.build_costs:
		if get_item_count(item_id) < blueprint.build_costs[item_id]:
			return
	
	for item_id in blueprint.build_costs:
		remove_item_stack(item_id, blueprint.build_costs[item_id])
	
	var building = blueprint.building_scene.instantiate()
	building.global_transform = current_ghost.global_transform
	building.rotation = current_ghost.rotation
	get_parent().add_child(building)
	
	exit_build_mode()
