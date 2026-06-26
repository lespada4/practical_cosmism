# ResourcePile.gd
extends StaticBody3D
class_name ResourcePile

@export var item: Item
@export var visual_scene: PackedScene
@export var initial_sink: float = 0.3
@export var sink_per_collect: float = 0.08
@export var final_sink_depth: float = 1.5

enum SizePreset {SMALL, MEDIUM, LARGE, CUSTOM}
@export var size_preset: SizePreset = SizePreset.MEDIUM

@export var custom_scale: float = 1.0
@export var custom_amount: int = 10
@export var small_amount: int = 5
@export var medium_amount: int = 10
@export var large_amount: int = 15
@export var small_scale: float = 0.7
@export var medium_scale: float = 1.0
@export var large_scale: float = 1.3

const COLLECTABLE_SCENE = preload("uid://c3hfprlw4lu7g")

var amount: int = 10
var visual_nodes: Array = []
var base_y: float = 0.0
var current_sink: float = 0.0
var is_queued: bool = false

func _ready():
	add_to_group("resource")
	add_to_group("resource_piles")
	
	match size_preset:
		SizePreset.SMALL:
			amount = small_amount
			apply_visual(small_scale)
		SizePreset.MEDIUM:
			amount = medium_amount
			apply_visual(medium_scale)
		SizePreset.LARGE:
			amount = large_amount
			apply_visual(large_scale)
		SizePreset.CUSTOM:
			amount = custom_amount
			apply_visual(custom_scale)

func apply_visual(scale_mult: float):
	if visual_scene:
		var visual_instance = visual_scene.instantiate()
		
		for child in visual_instance.get_children():
			visual_instance.remove_child(child)
			child.owner = null
			
			var original_scale = child.scale
			child.scale = original_scale * scale_mult
			
			if child is CollisionShape3D and child.shape:
				var shape = child.shape.duplicate()
				if shape is BoxShape3D:
					shape.size = shape.size * scale_mult
				elif shape is SphereShape3D:
					shape.radius = shape.radius * scale_mult
				elif shape is CylinderShape3D:
					shape.height = shape.height * scale_mult
					shape.radius = shape.radius * scale_mult
				elif shape is CapsuleShape3D:
					shape.height = shape.height * scale_mult
					shape.radius = shape.radius * scale_mult
				child.shape = shape
			
			child.rotate_y(deg_to_rad(randf_range(0, 360)))
			add_child(child)
			visual_nodes.append(child)
		
		visual_instance.queue_free()
		$MeshInstance3D.hide()
		
		if visual_nodes.size() > 0:
			for child in visual_nodes:
				child.position.y -= initial_sink
			base_y = visual_nodes[0].position.y
			current_sink = initial_sink

func restore_state(state: Dictionary):
	amount = int(state.get("amount", amount))
	current_sink = float(state.get("current_sink", current_sink))
	is_queued = state.get("is_queued", false)
	
	if visual_nodes.size() > 0:
		var target_y = base_y - (current_sink - initial_sink)
		for child in visual_nodes:
			child.position.y = target_y

func collect():
	if amount <= 0 or is_queued:
		return
	
	amount -= 1
	
	# Сохраняем сразу после каждого сбора
	_save_state()
	
	if amount <= 0:
		is_queued = true
		_save_state()
		
		$CollisionShape3D.disabled = true
		
		for child in visual_nodes:
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_QUINT)
			var target_y = base_y - (final_sink_depth - initial_sink)
			tween.tween_property(child, "position:y", target_y, 0.3)
			tween.finished.connect(_safe_queue_free)
	else:
		current_sink += sink_per_collect
		var target_y = base_y - (current_sink - initial_sink)
		
		for child in visual_nodes:
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUART)
			tween.tween_property(child, "position:y", target_y, 0.15)
	
	var collectable = COLLECTABLE_SCENE.instantiate()
	get_parent().add_child(collectable)
	collectable.setup(item, 1)
	collectable.global_position = global_position + Vector3(0, 1.5, 0)

func get_state() -> Dictionary:
	print("get_state called: amount=", amount, " is_queued=", is_queued)
	return {
		"amount": amount,
		"current_sink": current_sink,
		"is_queued": is_queued,
	}

func _save_state():
	var key = "pile_" + str(global_position.x) + "_" + str(global_position.y) + "_" + str(global_position.z)
	print("_save_state: key=", key, " amount=", amount, " is_queued=", is_queued)
	SaveManager.save_world_state({key: get_state()})

func _safe_queue_free():
	if is_instance_valid(self):
		queue_free()
