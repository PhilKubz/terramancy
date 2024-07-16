extends RigidBody3D

var Damage: int = 0


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Target") and body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
		queue_free()

	queue_free()
	
func _on_timer_timeout() -> void:
	queue_free()
