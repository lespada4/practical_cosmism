extends Resource
class_name Item

@export var id: int = 0
@export var display_name: String = ""
@export var icon: Texture2D
@export var max_stack: int = 99
@export var collectable_scene: PackedScene

# Виртуальный метод, переопределяется в наследниках
func use(_player) -> bool:
	print(display_name, " cannot be used")
	return false
