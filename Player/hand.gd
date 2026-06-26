extends Node3D
class_name Hand

@onready var hand_model: Node3D = $HandModel
@onready var sprite: Sprite3D = $HandModel/Sprite3D

var current_item: Item = null
var current_mesh: Node3D = null

func update_item(item: Item):
	if current_mesh:
		current_mesh.queue_free()
		current_mesh = null
	
	current_item = item
	
	if not item:
		hand_model.visible = false
		sprite.visible = false
		return
	
	hand_model.visible = true
	
	if item.hand_scene:
		sprite.visible = false
		current_mesh = item.hand_scene.instantiate()
		hand_model.add_child(current_mesh)
		
		current_mesh.position = item.hand_position
		current_mesh.rotation = item.hand_rotation
		current_mesh.scale = Vector3.ONE * item.hand_scale
	else:
		sprite.visible = true
		sprite.texture = item.icon
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.pixel_size = 0.05
		sprite.position = item.hand_position
		sprite.rotation = item.hand_rotation
		sprite.scale = Vector3.ONE * item.hand_scale
