extends StaticBody3D

var Health = 1

func Hit_Successful(Damage: int, _Direction := Vector3.ZERO, _Position := Vector3.ZERO):
	Health -= Damage
	
	if Health <= 0:
		queue_free()
