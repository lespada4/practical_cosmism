extends Node
class_name ElectricConsumer

signal power_changed(powered: bool)

@export var is_powered: bool = false
var power_source: Node = null

func set_power_source(source: Node):
	power_source = source

func update_power_status():
	var had_power = is_powered
	is_powered = power_source and power_source.is_powered
	
	if had_power != is_powered:
		power_changed.emit(is_powered)
		_on_power_changed(is_powered)

func _on_power_changed(powered: bool):
	pass

func has_power() -> bool:
	return is_powered
