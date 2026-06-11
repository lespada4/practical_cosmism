extends Area3D

enum DamageType {RADIATION = 1, POISON = 2}
enum Grade {LOW = 1, MEDIUM = 2, HIGH = 3, DEADLY = 4, INSTANT = 5}

@export var damage_type: DamageType = DamageType.RADIATION
@export var grade: Grade = Grade.HIGH
@export var damage_per_second: float = 10.0  

func _ready():
	match grade:
		Grade.LOW: damage_per_second = 10.0
		Grade.MEDIUM: damage_per_second = 25.0
		Grade.HIGH: damage_per_second = 50.0
		Grade.DEADLY: damage_per_second = 100.0
		Grade.INSTANT: damage_per_second = 200.0

func _on_body_entered(body):
	if body.has_method("apply_damage"):
		body.apply_damage(damage_per_second, damage_type)

func _on_body_exited(body):
	if body.has_method("stop_damage"):
		body.stop_damage(damage_type)
