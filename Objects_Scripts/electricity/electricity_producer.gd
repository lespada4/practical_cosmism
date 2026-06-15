extends Node
class_name ElectricProducer

signal running_changed(is_running: bool)

@export var is_running: bool = false:
	set(value):
		if is_running != value:
			is_running = value
			running_changed.emit(is_running)

@export var power_output: float = 100.0

func get_power_output() -> float:
	return power_output if is_running else 0.0
