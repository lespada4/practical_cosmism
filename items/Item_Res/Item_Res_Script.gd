extends Resource
class_name Item

@export var id: int = 0
@export var display_name: String = ""
@export var icon: Texture2D
@export var max_stack: int = 99
@export var collectable_scene: PackedScene
@export var radiation_emission: float = 0.0  # радиация в секунду от предмета в инвентаре
