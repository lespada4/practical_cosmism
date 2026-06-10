extends Panel

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var recipe_list: ItemList = $VBoxContainer/RecipeList
@onready var craft_button: Button = $VBoxContainer/HBoxContainer/CraftButton
@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton

var current_recipes: Array = []
var current_station: String = "player"
var is_open: bool = false
var current_recipe_index: int = -1

func _ready():
	hide()
	craft_button.disabled = true
	
	close_button.pressed.connect(_on_close_pressed)
	craft_button.pressed.connect(_on_craft_pressed)
	recipe_list.item_selected.connect(_on_recipe_selected)

func _input(event):
	if event.is_action_pressed("craft") and is_open:
		close()
	elif event.is_action_pressed("craft") and not is_open:
		open("player")

func open(station: String):
	current_station = station
	current_recipes = RecipeRegistry.get_recipes_for_station(station)
	
	match station:
		"player":
			title_label.text = "Ручной крафт"
		"workbench":
			title_label.text = "Верстак"
		"still":
			title_label.text = "Самогонный аппарат"
		"furnace":
			title_label.text = "Печка"
		_:
			title_label.text = station.capitalize() + " крафт"
	
	refresh_recipe_list()
	
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close():
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	craft_button.disabled = true
	current_recipe_index = -1

func refresh_recipe_list():
	recipe_list.clear()
	
	for recipe in current_recipes:
		var item = ItemRegistry.get_item(recipe["result"])
		var item_name = item.display_name if item else "Unknown"
		
		var ingredients_text = ""
		for ing_id in recipe["ingredients"]:
			var ing_item = ItemRegistry.get_item(ing_id)
			var ing_name = ing_item.display_name if ing_item else "Unknown"
			ingredients_text += ing_name + " x" + str(recipe["ingredients"][ing_id]) + " "
		
		recipe_list.add_item(item_name + " — " + ingredients_text)

func _on_recipe_selected(index: int):
	current_recipe_index = index
	craft_button.disabled = false

func _on_craft_pressed():
	if current_recipe_index < 0 or current_recipe_index >= current_recipes.size():
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		return
	
	var recipe = current_recipes[current_recipe_index]
	
	if RecipeRegistry.can_craft(player.inventory, recipe):
		RecipeRegistry.craft(player.inventory, recipe)
		refresh_recipe_list()
		print("Crafted!")
	else:
		print("Not enough materials")

func _on_close_pressed():
	close()
