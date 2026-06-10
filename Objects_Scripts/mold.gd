extends StaticBody3D

@export var item_id: int = 4
@export var collectable_scene: PackedScene



func collect():
	var collectable = collectable_scene.instantiate()
	
	get_parent().add_child(collectable)
	
	collectable.setup(ItemRegistry.get_item(item_id), 1)

	collectable.global_position = global_position + Vector3(0, 0.5, 0)
	
	queue_free()
