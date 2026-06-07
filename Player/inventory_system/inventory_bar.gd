extends HBoxContainer

@export var slot_scene: PackedScene
@export var slot_count: int = 9

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
	
	if event.is_action_pressed("use_item"):
		use_current_item()

func set_active_slot(index: int):
	if index == active_slot:
		return
	active_slot = index
	update_active_highlight()

func create_slots():
	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		add_child(slot)
		slots.append(slot)
		slot.set_slot(i, -1, 0, true)
		slot.gui_input.connect(_on_slot_gui_input.bind(i))

func _on_slot_gui_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_active_slot(slot_index)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		use_item_from_slot(slot_index)

func use_item_from_slot(slot_index: int):
	if not player or not player.inventory:
		return
	
	var slot = player.inventory.get_hotbar_slot(slot_index)
	if slot and slot.item:
		use_item(slot.item.id)

func get_active_slot() -> int:
	return active_slot

func use_current_item():
	if not player or not player.inventory:
		return
	
	var slot = player.inventory.get_hotbar_slot(active_slot)
	if slot and slot.item:
		use_item(slot.item.id)

func use_item(item_id: int):
	if ItemActions.use(player, item_id):
		player.inventory.remove_item(item_id, 1)

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
