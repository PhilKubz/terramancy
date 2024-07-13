extends Node

var Health = 5

func Hit_Successful(Damage):
	Health -= 1
	print("Target Health: " + str(Health))
	
	if Health <= 0:
		queue_free()
