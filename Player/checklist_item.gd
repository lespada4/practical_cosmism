extends HBoxContainer

@onready var checkmark: Label = $Checkmark
@onready var task_label: Label = $TaskLabel

func setup(task_text: String, done: bool = false):
	task_label.text = task_text
	update_status(done)

func update_status(done: bool):
	checkmark.text = "[X]" if done else "[ ]"
