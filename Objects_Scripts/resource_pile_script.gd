extends StaticBody3D

@export var item: Item
@export var visual_scene: PackedScene
@export var initial_sink: float = 0.3  # Вдавливание по умолчанию (при создании)
@export var sink_per_collect: float = 0.08  # Погружение за каждый сбор
@export var final_sink_depth: float = 1.5  # Финальная глубина погружения (абсолютное значение)

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

func _ready():
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
			var new_scale = original_scale * scale_mult
			child.scale = new_scale
			
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
			
			var rot_y = randf_range(0, 360)
			child.rotate_y(deg_to_rad(rot_y))
			
			add_child(child)
			visual_nodes.append(child)
		
		visual_instance.queue_free()
		
		$MeshInstance3D.hide()
		
		if visual_nodes.size() > 0:
			# Применяем начальное вдавливание
			for child in visual_nodes:
				child.position.y -= initial_sink
			base_y = visual_nodes[0].position.y
			current_sink = initial_sink

func collect():
	if amount <= 0:
		return
	
	var is_last = (amount == 1)
	
	amount -= 1
	
	if is_last:
		# Финальное погружение вниз
		var target_y = base_y - (final_sink_depth - initial_sink)
		
		for child in visual_nodes:
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_QUINT)
			tween.tween_property(child, "position:y", target_y, 0.3)
			tween.finished.connect(queue_free)
	else:
		# Обычное погружение вниз
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
