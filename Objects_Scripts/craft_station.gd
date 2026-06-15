extends StaticBody3D

@export var station_type: String = "still"

var is_crafting_open: bool = false
var crafting_ui_ref: Control = null
var consumer: ElectricConsumer

func _ready():
	consumer = $ElectricConsumer

func interact(player):
	if not consumer.has_power():
		return
	
	crafting_ui_ref = player.crafting_ui
	crafting_ui_ref.open(station_type)
	is_crafting_open = true

func _process(delta: float) -> void:
	if is_crafting_open and crafting_ui_ref and not consumer.has_power():
		crafting_ui_ref.close()
		is_crafting_open = false

func can_craft() -> bool:
	return consumer.has_power()
