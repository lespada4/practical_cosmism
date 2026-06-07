extends StaticBody3D

@export var iron_cost: int = 5
@export var steel_cost: int = 5
@export var moonshine_item_id: int = 3

func interact(player):
	if player.inventory.get_item_count(1) >= iron_cost and player.inventory.get_item_count(2) >= steel_cost:
		player.inventory.remove_item(1, iron_cost)
		player.inventory.remove_item(2, steel_cost)
		player.inventory.add_item(moonshine_item_id, 1)
		player.update_inventory_display()
