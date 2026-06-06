extends StaticBody3D

@export var item: Item
@export var amount: int = 10
const COLLECTABLE_SCENE = preload("uid://c3hfprlw4lu7g")

func collect():
	if amount <= 0:
		return
	
	amount -= 1
	
	var collectable = COLLECTABLE_SCENE.instantiate()
	get_parent().add_child(collectable)
	collectable.setup(item, 1)
	collectable.global_position = global_position + Vector3(0, 1.5, 0)
	
	if amount <= 0:
		queue_free()
