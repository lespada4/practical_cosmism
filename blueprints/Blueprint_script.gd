extends Resource
class_name Blueprint

@export var display_name: String = "Building"
@export var building_scene: PackedScene
@export var build_costs: Dictionary = {}
@export var preview_color: Color = Color(0, 1, 0, 0.5)
