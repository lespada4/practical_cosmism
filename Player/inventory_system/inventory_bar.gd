extends HBoxContainer
signal active_slot_changed
@export var slot_scene: PackedScene
@export var slot_count: int = 9
@onready var item_name_label: Label = $"../item name"

var slots: Array = []
var active_slot: int = 0
var player: CharacterBody3D = null

func _ready():
	add_to_group("hotbar")
	create_slots()
	set_active_slot(0)
	await get_tree().process_frame
	find_player_and_connect()

func find_player_and_connect():
	player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		player.inventory.inventory_updated.connect(update_hotbar)
		update_hotbar()
	else:
		await get_tree().create_timer(0.1).timeout
		find_player_and_connect()

func _input(event):
	for i in range(slot_count):
		if event.is_action_pressed("hotbar_" + str(i + 1)):
			set_active_slot(i)
			break
	
	if event.is_action_pressed("scroll_up"):
		var new_slot = active_slot - 1
		if new_slot < 0:
			new_slot = slot_count - 1
		set_active_slot(new_slot)
	
	if event.is_action_pressed("scroll_down"):
		var new_slot = active_slot + 1
		if new_slot >= slot_count:
			new_slot = 0
		set_active_slot(new_slot)
	
	if event.is_action_pressed("use_item"):
		use_current_item()

func is_build_mode_active() -> bool:
	if not player:
		return false
	if player.has_node("BuildingSystem"):
		var building_system = player.get_node("BuildingSystem")
		return building_system.is_build_mode
	return false

func set_active_slot(index: int):
	if index == active_slot:
		return
	active_slot = index
	active_slot_changed.emit()
	update_active_highlight()
	update_item_name_display()

func create_slots():
	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		add_child(slot)
		slots.append(slot)
		slot.set_slot(i, -1, 0, true)

func _on_slot_gui_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			set_active_slot(slot_index)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			use_item_from_slot(slot_index)

func use_item_from_slot(slot_index: int):
	if is_build_mode_active():
		return
	
	if not player or not player.inventory:
		return
	
	var slot = player.inventory.get_hotbar_slot(slot_index)
	if slot and slot.item:
		var target = _get_interaction_target() if slot.item.id == 11 else null
		ItemActions.use(player, slot.item.id, target)

func _get_interaction_target():
	if not player:
		return null
	return player.get_interaction_target()

func use_current_item():
	if is_build_mode_active():
		return
	
	if not player or not player.inventory:
		return
	
	var slot = player.inventory.get_hotbar_slot(active_slot)
	if slot and slot.item:
		var target = _get_interaction_target() if slot.item.id == 11 else null
		ItemActions.use(player, slot.item.id, target)

func update_hotbar():
	if not player or not player.inventory:
		return
	for i in range(slot_count):
		var slot_data = player.inventory.get_hotbar_slot(i)
		if slot_data and slot_data.item:
			slots[i].set_slot(i, slot_data.item.id, slot_data.quantity, true)
		else:
			slots[i].clear_slot()
	update_active_highlight()
	update_item_name_display()

func get_inventory():
	return player.inventory if player else null

func update_active_highlight():
	for i in range(slot_count):
		if i == active_slot:
			var active_style = StyleBoxFlat.new()
			active_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
			active_style.border_width_left = 2
			active_style.border_width_right = 2
			active_style.border_width_top = 2
			active_style.border_width_bottom = 2
			active_style.border_color = Color(1, 0.8, 0, 1)
			slots[i].add_theme_stylebox_override("panel", active_style)
		else:
			var inactive_style = StyleBoxFlat.new()
			inactive_style.bg_color = Color(0, 0, 0, 0.6)
			slots[i].add_theme_stylebox_override("panel", inactive_style)

func update_item_name_display():
	if not player or not player.inventory:
		item_name_label.text = ""
		return
	
	var slot = player.inventory.get_hotbar_slot(active_slot)
	if slot and slot.item:
		item_name_label.text = slot.item.display_name
	else:
		item_name_label.text = ""
