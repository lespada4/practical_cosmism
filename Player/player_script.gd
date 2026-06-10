extends CharacterBody3D

@export var speed = 3.0
@export var sprint_speed = 5.0
@export var mouse_sensitivity = 0.002
@export var jump_velocity = 5
@export var head_bob_intensity = 0.05
@export var head_bob_speed = 14.0
@export var coyote_time = 0.1
@export var gravity_up = 10.0
@export var gravity_down = 32.0
@export var jump_cut_multiplier = 0.4
@export var air_control = 3
@export var acceleration = 32.0
@export var friction = 32.0

@onready var inventory: Inventory = $Inventory
@onready var interaction_ray: RayCast3D = $Camera3D/interaction_ray
@onready var camera: Camera3D = $Camera3D
@onready var dropper: Marker3D = $Camera3D/Dropper
@onready var crosshair: TextureRect = $UI_LAYER/Control/crosshair
@onready var inventory_label: Label = $UI_LAYER/Control/inventory_label
@onready var health_label: Label = $UI_LAYER/Control/health_label
@onready var inventory_bar: HBoxContainer = $UI_LAYER/Control/InventoryBar
@onready var full_inventory: Panel = $UI_LAYER/Control/FullInventory
@onready var crafting_ui: Panel = $UI_LAYER/Control/craftingUI

var head_bob_time = 0.0
var is_moving = false
var camera_default_height = 0.0
var coyote_timer = 0.0
var radiation = 0.0
var current_damage = 0.0
var build_distance: float = 3.0
var is_jumping: bool = false
var jump_horizontal_velocity: Vector3 = Vector3.ZERO

# Строительство
var build_mode: bool = false
var current_ghost: Area3D = null
var current_blueprint_id: String = ""

# Спринт
var is_sprinting: bool = false

func _ready():
	camera_default_height = camera.transform.origin.y
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_health_display()
	add_to_group("player")
	
	inventory.add_item(1, 10)
	inventory.add_item(2, 5)
	inventory.add_item(3, 2)
	
	inventory.inventory_updated.connect(update_inventory_display)
	update_inventory_display()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
		
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
	if event.is_action_pressed("craft"):
		crafting_ui.open("player")
	if build_mode and event.is_action_pressed("rotate_building") and current_ghost:
		current_ghost.rotate_y(deg_to_rad(45))
	
	if event.is_action_pressed("sprint"):
		is_sprinting = true
	
	if event.is_action_released("sprint"):
		is_sprinting = false
	
	if event.is_action_pressed("drop_item"):
		drop_current_item()

func update_build_distance_by_camera():
	var t = (camera.rotation.x + 1.5) / 3.0
	t = clamp(t, 0.0, 1.0)
	build_distance = lerp(1.0, 5.0, t)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_moving = direction != Vector3.ZERO
	
	var current_speed = sprint_speed if (is_sprinting and is_moving and is_on_floor()) else speed
	
	if is_on_floor():
		coyote_timer = coyote_time
		is_jumping = false
		jump_horizontal_velocity = Vector3.ZERO
		
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)
	else:
		coyote_timer -= delta
		
		if is_jumping:
			if direction:
				velocity.x = lerp(velocity.x, direction.x * current_speed, air_control * delta * 10)
				velocity.z = lerp(velocity.z, direction.z * current_speed, air_control * delta * 10)
			else:
				velocity.x = move_toward(velocity.x, 0, friction * 0.2 * delta)
				velocity.z = move_toward(velocity.z, 0, friction * 0.2 * delta)
	
	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		velocity.y = jump_velocity
		is_jumping = true
		jump_horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
		
		if is_sprinting and direction:
			velocity.x = direction.x * sprint_speed * 1.2
			velocity.z = direction.z * sprint_speed * 1.2
			jump_horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	
	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= jump_cut_multiplier
	
	if velocity.y > 0:
		velocity.y -= gravity_up * delta
	else:
		velocity.y -= gravity_down * delta
	
	move_and_slide()
	
	if current_damage > 0:
		radiation += current_damage * delta
		if radiation >= 100:
			die()
		update_health_display()
	
	if build_mode and current_ghost:
		update_ghost_position()
	
	update_head_bob(delta)

func update_head_bob(delta):
	if is_moving and is_on_floor():
		head_bob_time += delta * head_bob_speed
		var vertical = sin(head_bob_time) * head_bob_intensity
		var horizontal = cos(head_bob_time * 0.5) * head_bob_intensity
		camera.transform.origin = Vector3(horizontal, camera_default_height + vertical, 0)
	else:
		head_bob_time = 0
		camera.transform.origin = Vector3(0, camera_default_height, 0)

func try_interact():
	if not interaction_ray.is_colliding():
		return
	
	var hit = interaction_ray.get_collider()
	
	if hit.is_in_group("resource") and hit.has_method("collect"):
		hit.collect()
	elif hit.has_method("interact"):
		hit.interact(self)

func collect_item(item_id: int, amount: int):
	inventory.add_item(item_id, amount)

func update_inventory_display():
	var iron = inventory.get_item_count(1)
	var steel = inventory.get_item_count(2)
	var moonshine = inventory.get_item_count(3)
	inventory_label.text = "Iron: " + str(iron) + "  Steel: " + str(steel) + "  Moonshine: " + str(moonshine)

func update_health_display():
	health_label.text = "Radiation: " + str(round(radiation)) + "%"

func apply_damage(amount: float, _type):
	current_damage = amount

func stop_damage(_type):
	current_damage = 0.0

func die():
	get_tree().reload_current_scene()

# ========== ВЫКИДЫВАНИЕ ПРЕДМЕТОВ ==========

func drop_current_item():
	if not inventory:
		return
	
	var active_slot = inventory_bar.active_slot
	var slot_data = inventory.get_hotbar_slot(active_slot)
	if not slot_data or not slot_data.item:
		return
	
	var item_id = slot_data.item.id
	var quantity = 1
	
	if inventory.remove_item(item_id, quantity):
		drop_item_in_world(item_id, quantity)

func drop_item_in_world(item_id: int, quantity: int):
	var item_resource = ItemRegistry.get_item(item_id)
	if not item_resource or not item_resource.collectable_scene:
		return
	
	var collectable = item_resource.collectable_scene.instantiate()
	get_parent().add_child(collectable)
	collectable.setup(item_resource, quantity)
	collectable.global_position = dropper.global_position
	
	var forward = -camera.global_transform.basis.z
	var throw_dir = forward + Vector3(0, 0.5, 0)
	throw_dir = throw_dir.normalized()
	throw_dir.x += randf_range(-0.2, 0.2)
	throw_dir.z += randf_range(-0.2, 0.2)
	throw_dir = throw_dir.normalized()
	
	if collectable.has_method("apply_velocity"):
		collectable.apply_velocity(throw_dir * 6.0)

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
	
	if not inventory.has_items(blueprint.build_costs):
		return
	
	inventory.consume_items(blueprint.build_costs)
	
	var building = blueprint.building_scene.instantiate()
	building.global_transform = current_ghost.global_transform
	building.rotation = current_ghost.rotation
	get_parent().add_child(building)
	
	exit_build_mode()
