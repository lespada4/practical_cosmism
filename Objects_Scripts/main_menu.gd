extends CanvasLayer
class_name MainMenu

@export var rotation_speed: float = 0.5
@onready var model: MeshInstance3D = $Model
@onready var new_game_button: Button = $Control/MenuButtons/NEWGAME
@onready var continue_button: Button = $Control/MenuButtons/CONTINUE
@onready var options_button: Button = $Control/MenuButtons/OPTIONS
@onready var quit_button: Button = $Control/MenuButtons/QUIT
@onready var version_label: Label = $Control/MenuButtons/version

func _ready():
	version_label.text = "v0.1.0"
	
	var has_save = SaveManager.has_save()
	continue_button.disabled = not has_save
	
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	if model:
		model.rotation.y += rotation_speed * delta

func _on_new_game_pressed():
	if SaveManager.has_save():
		SaveManager.delete_save()
	get_tree().change_scene_to_file("res://levels/level_scenes/level1_KORDON.tscn")

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://levels/level_scenes/level1_KORDON.tscn")

func _on_options_pressed():
	print("Options pressed")

func _on_quit_pressed():
	get_tree().quit()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
