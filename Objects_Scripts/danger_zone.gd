extends Area3D

enum DamageType {RADIATION = 1, POISON = 2}

@export var damage_type: DamageType = DamageType.RADIATION
@export var damage_per_second: float = 10.0


func _on_body_entered(body):
	if body.has_method("apply_damage"):
		body.apply_damage(damage_per_second, damage_type)

func _on_body_exited(body):
	if body.has_method("stop_damage"):
		body.stop_damage(damage_type)
