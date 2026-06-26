extends Node
class_name UIManager

enum UIType {
	NONE,
	INVENTORY,
	CRAFTING,
	BUILDING,
	CHECKLIST,
}

var current_window: UIType = UIType.NONE
var window_stack: Array = []

@onready var full_inventory: Panel = $"../FullInventory"
@onready var crafting_ui: Panel = $"../craftingUI"
@onready var building_ui: Control = $"../BuildingUI"
@onready var checklist: Panel = $"../Checklist"
@onready var crosshair: TextureRect = $"../crosshair"

var building_system: Node = null

func _ready():
	close_all()
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		building_system = player.get_node("BuildingSystem")

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if current_window != UIType.NONE:
			close_current()

func is_build_mode_active() -> bool:
	return building_system and building_system.is_build_mode

func exit_build_mode():
	if building_system and building_system.is_build_mode:
		building_system.exit_build_mode()

func open_window(window: UIType):
	# Если открываем НЕ строительство, а оно активно — выходим из стройки
	if is_build_mode_active() and window != UIType.BUILDING:
		exit_build_mode()
	
	close_current()
	current_window = window
	_update_visibility()

func close_current():
	current_window = UIType.NONE
	_update_visibility()

func close_all():
	current_window = UIType.NONE
	_update_visibility()

func _update_visibility():
	full_inventory.visible = (current_window == UIType.INVENTORY)
	crafting_ui.visible = (current_window == UIType.CRAFTING)
	building_ui.visible = (current_window == UIType.BUILDING)
	checklist.visible = (current_window == UIType.CHECKLIST)
	
	if current_window == UIType.NONE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func toggle_inventory():
	if current_window == UIType.INVENTORY:
		close_current()
	else:
		open_window(UIType.INVENTORY)

func toggle_crafting():
	if current_window == UIType.CRAFTING:
		close_current()
	else:
		open_window(UIType.CRAFTING)

func toggle_building():
	if current_window == UIType.BUILDING:
		close_current()
	else:
		open_window(UIType.BUILDING)

func toggle_checklist():
	if current_window == UIType.CHECKLIST:
		close_current()
	else:
		open_window(UIType.CHECKLIST)

func is_window_open() -> bool:
	return current_window != UIType.NONE

func get_current_window() -> UIType:
	return current_window
