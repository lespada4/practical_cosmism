extends Area3D

@export var required_iron: int = 10
@export var required_steel: int = 5
@export var build_scene: PackedScene

func interact(player):
	if player.inventory.get_item_count(1) >= required_iron and player.inventory.get_item_count(2) >= required_steel:
		player.inventory.remove_item(1, required_iron)
		player.inventory.remove_item(2, required_steel)
		var instance = build_scene.instantiate()
		instance.global_transform = global_transform
		get_parent().add_child(instance)
		player.update_inventory_display()
		queue_free()
