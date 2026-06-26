extends Resource
class_name Item

@export var id: int = 0
@export var display_name: String = ""
@export var icon: Texture2D
@export var max_stack: int = 99
@export var collectable_scene: PackedScene
@export var radiation_emission: float = 0.0

@export var hand_scene: PackedScene
@export var hand_position: Vector3 = Vector3(0.3, -0.3, -0.5)
@export var hand_rotation: Vector3 = Vector3(0, 0, 0)
@export var hand_scale: float = 0.3
@export var use_sprite: bool = false
