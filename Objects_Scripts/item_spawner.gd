extends Node3D

signal item_count_changed(count: int)

@export var item_scene: PackedScene
@export var spawn_points: Array[Node3D]
@export var spawn_interval: float = 60.0
@export var max_items: int = 5
@export var initial_delay: float = 30.0

@export var possible_items: Array[Item] = []
@export var possible_quantities: Array[int] = []

var current_items: Array = []
var is_spawning: bool = false

func _ready():
	await get_tree().process_frame
	start_initial_delay()

func start_initial_delay():
	await get_tree().create_timer(initial_delay).timeout
	is_spawning = true
	spawn_single_item()
	start_spawn_timer()

func spawn_single_item():
	var free_points = get_free_spawn_points()
	if free_points.size() > 0:
		var point = free_points[randi() % free_points.size()]
		spawn_item_at(point)

func start_spawn_timer():
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		if is_spawning and current_items.size() < max_items:
			var free_points = get_free_spawn_points()
			if free_points.size() > 0:
				var point = free_points[randi() % free_points.size()]
				spawn_item_at(point)

func get_free_spawn_points() -> Array:
	var free = []
	for point in spawn_points:
		if not point or not is_instance_valid(point):
			continue
		var occupied = false
		for item in current_items:
			if item and is_instance_valid(item):
				if item.global_position.distance_to(point.global_position) < 0.5:
					occupied = true
					break
		if not occupied:
			free.append(point)
	return free

func spawn_item_at(point: Node3D):
	if not point or not is_instance_valid(point):
		return
	
	if possible_items.is_empty():
		return
	
	var index = randi() % possible_items.size()
	var item = possible_items[index]
	var qty = possible_quantities[index] if index < possible_quantities.size() else 1
	
	if not item:
		return
	
	var collectable = item_scene.instantiate()
	add_child(collectable)
	collectable.global_position = point.global_position
	collectable.setup(item, qty)
	current_items.append(collectable)
	collectable.tree_exited.connect(_on_item_removed.bind(collectable))
	item_count_changed.emit(current_items.size())

func _on_item_removed(item):
	current_items.erase(item)
	item_count_changed.emit(current_items.size())

func stop_spawning():
	is_spawning = false

func start_spawning():
	is_spawning = true
