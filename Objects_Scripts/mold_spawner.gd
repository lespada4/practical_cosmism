extends Node3D

signal mold_count_changed(count: int)

@export var mold_scene: PackedScene
@export var spawn_points: Array[Node3D]
@export var spawn_interval: float = 60.0
@export var max_mold: int = 5
@export var initial_delay: float = 30.0

var current_mold: Array = []
var is_spawning: bool = false

func _ready():
	await get_tree().process_frame
	start_initial_delay()

func start_initial_delay():
	await get_tree().create_timer(initial_delay).timeout
	is_spawning = true
	# Первая плесень — только одна
	spawn_single_mold()
	# Запускаем цикл периодического спавна
	start_spawn_timer()

func spawn_single_mold():
	var free_points = get_free_spawn_points()
	if free_points.size() > 0:
		var point = free_points[randi() % free_points.size()]
		spawn_mold_at(point)

func start_spawn_timer():
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		if is_spawning and current_mold.size() < max_mold:
			var free_points = get_free_spawn_points()
			if free_points.size() > 0:
				var point = free_points[randi() % free_points.size()]
				spawn_mold_at(point)

func get_free_spawn_points() -> Array:
	var free = []
	for point in spawn_points:
		if not point or not is_instance_valid(point):
			continue
		var occupied = false
		for mold in current_mold:
			if mold and is_instance_valid(mold):
				if mold.global_position.distance_to(point.global_position) < 0.5:
					occupied = true
					break
		if not occupied:
			free.append(point)
	return free

func spawn_mold_at(point: Node3D):
	if not point or not is_instance_valid(point):
		return
	var mold = mold_scene.instantiate()
	add_child(mold)
	mold.global_position = point.global_position
	current_mold.append(mold)
	mold.tree_exited.connect(_on_mold_removed.bind(mold))
	mold_count_changed.emit(current_mold.size())

func _on_mold_removed(mold):
	current_mold.erase(mold)
	mold_count_changed.emit(current_mold.size())
