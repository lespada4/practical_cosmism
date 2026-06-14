extends CharacterBody3D

@export var speed = 3.0
@export var sprint_speed = 5.0
@export var jump_velocity = 5
@export var coyote_time = 0.1

@export var jump_cut_multiplier = 0.4
@export var air_control = 3
@export var acceleration = 32.0
@export var friction = 32.0
const GRAVITY_UP = 10.0
const GRAVITY_DOWN = 32.0

@onready var inventory: Inventory = $Inventory
@onready var health_system: HealthSystem = $HealthSystem
@onready var building_system: Node = $BuildingSystem
@onready var camera_controller: CameraController = $CameraController
@onready var camera: Camera3D = $CameraController/Camera3D
@onready var interaction_ray: RayCast3D = $CameraController/Camera3D/interaction_ray
@onready var dropper: Marker3D = $CameraController/Camera3D/Dropper
@onready var stair_stepper: Node = $StairStepper

@onready var crosshair: TextureRect = $UI_LAYER/Control/crosshair
@onready var inventory_label: Label = $UI_LAYER/Control/inventory_label
@onready var health_label: Label = $UI_LAYER/Control/health_label
@onready var radiation_label: Label = $UI_LAYER/Control/radiation_label
@onready var inventory_bar: HBoxContainer = $UI_LAYER/Control/InventoryBar
@onready var full_inventory: Panel = $UI_LAYER/Control/FullInventory
@onready var crafting_ui: Panel = $UI_LAYER/Control/craftingUI
@onready var protection_label: Label = $UI_LAYER/Control/protection_label

var coyote_timer = 0.0
var is_jumping: bool = false
var is_sprinting: bool = false
var jump_held: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")

	stair_stepper.initialize(self, camera)
	building_system.initialize(self, camera_controller.get_camera(), crosshair)

	health_system.died.connect(_on_death)
	health_system.health_changed.connect(update_health_display)
	health_system.radiation_changed.connect(update_radiation_display)

	inventory.inventory_updated.connect(_on_inventory_updated)
	inventory.inventory_updated.connect(update_inventory_display)
	update_inventory_display()
	update_health_display(health_system.health)
	update_radiation_display(health_system.radiation, health_system.radiation_stage)
	health_system.protection_changed.connect(update_protection_display)

func _input(event):
	camera_controller.handle_input(event)

	if event is InputEventMouseMotion and building_system.is_build_mode:
		building_system.update_build_distance_by_camera()

	if event.is_action_pressed("interact"):
		if building_system.is_build_mode:
			building_system.try_build(inventory)
		else:
			try_interact()

	if event.is_action_pressed("craft"):
		crafting_ui.open("player")

	if event.is_action_pressed("sprint"):
		is_sprinting = true
	if event.is_action_released("sprint"):
		is_sprinting = false

	if event.is_action_pressed("drop_item"):
		drop_current_item()

	if event.is_action_pressed("jump"):
		jump_held = true
	if event.is_action_released("jump"):
		jump_held = false

func _process(delta: float) -> void:
	rotation.y = camera_controller.get_h_rotation()
	camera_controller.update_rotation(delta)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")

	var camera_forward = camera_controller.get_camera_forward()
	camera_forward.y = 0
	camera_forward = camera_forward.normalized()

	var camera_right = camera_controller.get_camera().global_transform.basis.x
	camera_right.y = 0
	camera_right = camera_right.normalized()

	var direction = (camera_forward * -input_dir.y + camera_right * input_dir.x).normalized()
	var current_speed = sprint_speed if (is_sprinting and direction != Vector3.ZERO and is_on_floor()) else speed

	if is_on_floor():
		coyote_timer = coyote_time
		is_jumping = false

		if direction != Vector3.ZERO:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)

		if jump_held and coyote_timer > 0:
			velocity.y = jump_velocity
			is_jumping = true
			coyote_timer = 0
	else:
		coyote_timer -= delta

		if is_jumping:
			if direction != Vector3.ZERO:
				velocity.x = lerp(velocity.x, direction.x * current_speed, air_control * delta * 10)
				velocity.z = lerp(velocity.z, direction.z * current_speed, air_control * delta * 10)
			else:
				velocity.x = move_toward(velocity.x, 0, friction * 0.2 * delta)
				velocity.z = move_toward(velocity.z, 0, friction * 0.2 * delta)

	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		velocity.y = jump_velocity
		is_jumping = true
		if is_sprinting and direction != Vector3.ZERO:
			velocity.x = direction.x * sprint_speed * 1.2
			velocity.z = direction.z * sprint_speed * 1.2

	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= jump_cut_multiplier

	if velocity.y > 0:
		velocity.y -= GRAVITY_UP * delta
	else:
		velocity.y -= GRAVITY_DOWN * delta

	stair_stepper.process_stairs(delta, direction, current_speed)
	stair_stepper.process_camera_smooth(delta, current_speed)

	camera_controller.update_head_bob(delta, direction != Vector3.ZERO, is_on_floor())

	if building_system.is_build_mode:
		building_system.update_ghost_position()

func try_interact():
	if not interaction_ray.is_colliding():
		return
	var hit = interaction_ray.get_collider()
	if not is_instance_valid(hit):
		return
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

func update_health_display(new_health: float):
	health_label.text = "HP: " + str(round(new_health)) + "%"

func update_radiation_display(radiation: float, stage: int):
	var color = Color.WHITE
	match stage:
		0: color = Color.GREEN
		1: color = Color.YELLOW
		2: color = Color.ORANGE
		3: color = Color.RED
	radiation_label.text = "Rad: " + str(round(radiation)) + "%"
	radiation_label.modulate = color

func update_protection_display(resistance: float, timer: float):
	if resistance > 0:
		var resistance_str = "%.1f" % resistance
		protection_label.text = "Prot: " + resistance_str + "% (" + str(round(timer)) + "s)"
		protection_label.visible = true
	else:
		protection_label.visible = false

func apply_damage(amount: float, damage_type: int):
	match damage_type:
		1: health_system.apply_environment_radiation(amount)
		2: health_system.apply_poison_damage(amount)

func stop_damage(damage_type: int):
	match damage_type:
		1: health_system.stop_environment_radiation()
		2: health_system.stop_poison_damage()

func _on_death():
	if get_tree():
		get_tree().reload_current_scene()

func _on_inventory_updated():
	var emission = inventory.get_total_radiation_emission()
	health_system.apply_inventory_radiation(emission)

func use_moonshine():
	health_system.use_moonshine()

func use_antirad():
	health_system.use_antirad()

func use_cockroach():
	health_system.use_cockroach()

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
	var forward = camera_controller.get_camera_forward()
	var throw_dir = forward + Vector3(0, 0.5, 0)
	throw_dir = throw_dir.normalized()
	throw_dir.x += randf_range(-0.2, 0.2)
	throw_dir.z += randf_range(-0.2, 0.2)
	throw_dir = throw_dir.normalized()
	if collectable.has_method("apply_velocity"):
		collectable.apply_velocity(throw_dir * 6.0)

func show_demo_complete():
	print("DEMO COMPLETE! Congratulations!")
	if has_node("UI_LAYER/Control/DemoCompleteLabel"):
		$UI_LAYER/Control/DemoCompleteLabel.visible = true
		await get_tree().create_timer(3.0).timeout
		$UI_LAYER/Control/DemoCompleteLabel.visible = false
