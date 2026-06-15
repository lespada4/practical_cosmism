extends Panel

@export var slot_scene: PackedScene
@export var grid_container: GridContainer
@export var slot_count: int = 28

var slots: Array = []
var is_open: bool = false

func _ready():
	create_slots()
	hide()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		player.inventory.inventory_updated.connect(update_inventory)

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		toggle()

func toggle():
	is_open = not is_open
	visible = is_open
	if is_open:
		update_inventory()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func create_slots():
	for i in range(slot_count):
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot)
		slots.append(slot)
		slot.set_slot(i, -1, 0, false)

func update_inventory():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		return
	for i in range(slot_count):
		if i < player.inventory.main_slots.size():
			var slot_data = player.inventory.get_main_slot(i)
			if slot_data and slot_data.item:
				slots[i].set_slot(i, slot_data.item.id, slot_data.quantity, false)
			else:
				slots[i].clear_slot()
		else:
			slots[i].clear_slot()

func get_inventory():
	var player = get_tree().get_first_node_in_group("player")
	return player.inventory if player else null

func close():
	if is_open:
		toggle()


func _on_button_pressed() -> void:
	toggle()
