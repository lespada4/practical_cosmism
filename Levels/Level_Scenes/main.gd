extends Node3D

func _ready():
	var save_data = SaveManager.load_game()
	
	if save_data and not save_data.is_empty():
		print("=== LOADING SAVE ===")
		_restore_save(save_data)
	else:
		print("No save found, starting new game")

func _restore_save(data: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	player.inventory.inventory_updated.disconnect(player._on_inventory_updated)
	
	if data.has("position"):
		var pos = Vector3(data["position"][0], data["position"][1], data["position"][2])
		player.global_position = pos
	
	if data.has("rotation"):
		player.rotation.y = data["rotation"]
		if player.has_method("set_initial_rotation"):
			player.set_initial_rotation(data["rotation"])
	
	if data.has("health"):
		player.health_system.health = data["health"]
		player.health_system.health_changed.emit(player.health_system.health)
	
	if data.has("radiation"):
		player.health_system.radiation = data["radiation"]
		player.health_system.radiation_changed.emit(player.health_system.radiation, player.health_system.radiation_stage)
	
	if data.has("inventory"):
		_restore_inventory(data["inventory"], player)
	
	if data.has("buildings"):
		_restore_buildings(data["buildings"], player)
	
	# Откладываем удаление куч на следующий кадр — к этому моменту все _ready() уже выполнены
	if data.has("world_state"):
		call_deferred("_restore_world_state", data["world_state"])
	
	# Reconnect тоже откладываем, чтобы он случился после _restore_world_state
	call_deferred("_reconnect_inventory_signal", player)
	
	print("Game restored from save")

func _reconnect_inventory_signal(player):
	player.inventory.inventory_updated.connect(player._on_inventory_updated)

func _restore_world_state(world_state: Dictionary):
	var piles = get_tree().get_nodes_in_group("resource")
	print("_restore_world_state: piles=", piles.size())
	
	for pile in piles:
		var key = "pile_" + str(pile.global_position.x) + "_" + str(pile.global_position.y) + "_" + str(pile.global_position.z)
		if world_state.has(key):
			var state = world_state[key]
			print("RESTORE: ", key, " -> amount=", state.get("amount"), " is_queued=", state.get("is_queued"))
			if state.get("is_queued", false) or state.get("amount", 0) <= 0:
				pile.queue_free()
			else:
				pile.restore_state(state)
		else:
			print("NO STATE FOR: ", key)
	
func _restore_inventory(inv_data: Dictionary, player):
	for slot_key in inv_data:
		var slot_index = int(slot_key)
		var slot_data = inv_data[slot_key]
		var item = ItemRegistry.get_item(slot_data["id"])
		if item:
			var stack = ItemStack.new()
			stack.item = item
			stack.quantity = slot_data["quantity"]
			player.inventory.hotbar_slots[slot_index] = stack
	
	player.inventory.inventory_updated.emit()

func _restore_buildings(buildings_data: Array, player):
	for building_data in buildings_data:
		var blueprint_id = building_data["blueprint_id"]
		var blueprint = BlueprintRegistry.get_blueprint(blueprint_id)
		if not blueprint:
			continue
		
		var building = blueprint.building_scene.instantiate()
		
		add_child(building)
		building.add_to_group("buildings")
		building.set_meta("blueprint_id", blueprint_id)
		
		var pos = Vector3(
			building_data["position"][0],
			building_data["position"][1],
			building_data["position"][2]
		)
		building.global_position = pos
		building.rotation.y = building_data["rotation"]
		
		if building.is_in_group("derad_zones"):
			var health_system = get_tree().get_first_node_in_group("health_system")
			if health_system and health_system.has_method("_connect_to_zone"):
				health_system._connect_to_zone(building)
