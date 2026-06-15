extends Node

var recipes = []

func _ready():
	register_recipes()

func register_recipes():
	# Ручной крафт
	#add_recipe(4, 1, {1: 2, 2: 1}, "player")
	
	# Верстак
	add_recipe(5, 1, {1: 3, 2: 2}, "workbench")
	
	# Самогонный аппарат
	add_recipe(3, 1, {4: 1,}, "still")
	
	# Печка (furnace)
	add_recipe(6, 1, {1: 2}, "furnace")  # 2 iron = 1 molten iron
	# recipe_registry.gd


func add_recipe(result_id: int, quantity: int, ingredients: Dictionary, station: String):
	recipes.append({
		"result": result_id,
		"quantity": quantity,
		"ingredients": ingredients,
		"station": station
	})

func get_recipes_for_station(station: String) -> Array:
	var filtered = []
	for recipe in recipes:
		if recipe["station"] == station:
			filtered.append(recipe)
	return filtered

func get_recipe_for_item(item_id: int, station: String = ""):
	for recipe in recipes:
		if recipe["result"] == item_id:
			if station == "" or recipe["station"] == station:
				return recipe
	return null

func can_craft(inventory, recipe) -> bool:
	for item_id in recipe["ingredients"]:
		if inventory.get_item_count(item_id) < recipe["ingredients"][item_id]:
			return false
	return true

func craft(inventory, recipe) -> bool:
	if not can_craft(inventory, recipe):
		return false
	
	for item_id in recipe["ingredients"]:
		inventory.remove_item(item_id, recipe["ingredients"][item_id])
	
	inventory.add_item(recipe["result"], recipe["quantity"])
	return true
