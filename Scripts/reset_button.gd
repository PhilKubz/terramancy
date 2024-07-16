extends Area3D


func _on_body_entered(body: Node) -> void:
	print("Collision detected with: ", body.name)
	get_tree().reload_current_scene()
