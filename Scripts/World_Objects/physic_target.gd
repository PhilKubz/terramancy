extends RigidBody3D

var Health = 5

func Hit_Successful(Damage: int, _Direction := Vector3.ZERO, _Position := Vector3.ZERO):
	var Hit_Position = _Position - get_global_transform().origin
	
	Health -= Damage
	print("Target Health: " + str(Health))
	if Health <= 0:
		queue_free()
	
	if _Direction != Vector3.ZERO:
		apply_impulse((_Direction * Damage), Hit_Position)
