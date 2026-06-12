extends Area3D

@export var required_iron: int = 10
@export var required_steel: int = 5
@export var required_parts: int = 3
@export var build_scene: PackedScene

func interact(player):
	if player.inventory.get_item_count(1) >= required_iron and player.inventory.get_item_count(2) >= required_steel and player.inventory.get_item_count(7) >= required_parts:
		player.inventory.consume_items({1: required_iron, 2: required_steel, 7: required_parts})
		var instance = build_scene.instantiate()
		instance.global_transform = global_transform
		instance.position.y -= 0.5  # подтопить вниз
		get_parent().add_child(instance)
		player.update_inventory_display()
		
		# Поздравление с завершением демки
		print("Beacon built! Demo completed!")
		if player.has_method("show_demo_complete"):
			player.show_demo_complete()
		
		queue_free()
