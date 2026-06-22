extends Node

var hint_label: Label = null
var message_timer: float = 0.0
var is_showing: bool = false

func _ready():
	# Ищем hint_label при старте
	call_deferred("find_hint_label")

func find_hint_label():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		hint_label = player.get_node("UI_LAYER/Control/hint_label")
		if hint_label:
			hint_label.visible = false

func show_message(text: String, duration: float = 3.0):
	if not hint_label:
		# Если hint_label ещё не найден — ищем
		find_hint_label()
		if not hint_label:
			print("MessageSystem: hint_label not found!")
			return
	
	hint_label.text = text
	hint_label.visible = true
	is_showing = true
	message_timer = duration
	
	# Ждём, пока пройдёт время
	await get_tree().create_timer(duration).timeout
	hint_label.visible = false
	is_showing = false

func hide_message():
	if hint_label:
		hint_label.visible = false
	is_showing = false
