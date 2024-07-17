extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack
signal Weapon_Type

@onready var Animation_Player = $FPS_Rig/AnimationPlayer
@onready var Bullet_Point = $FPS_Rig/Bullet_Point

var Debug_Bullet = preload("res://Scenes/bullet_debug.tscn")

var Current_Weapon = null
var Weapon_Stack = []
var Weapon_Indicator = 0
var Next_Weapon: String
var Weapon_List = {}

@export var _weapon_resources: Array[Weapon_Resource] = []
@export var Start_Weapons: Array[String] = []

enum {NULL, HITSCAN, PROJECTILE}

var Collision_Exclusion = []

func _ready():
	Initialize(Start_Weapons)

func _input(event):
	
	# if event.is_action_pressed("Weapon_Down"):
	#	Weapon_Indicator = min(Weapon_Indicator + 1, Weapon_Stack.size() - 1)
	#	exit(Weapon_Stack[Weapon_Indicator])
		
	#if event.is_action_pressed("Weapon_Up"):
	#	Weapon_Indicator = max(Weapon_Indicator - 1, 0)
	#	exit(Weapon_Stack[Weapon_Indicator])
	
	if event.is_action_pressed("Select_Weapon_1"):
		select_weapon(0)
	
	if event.is_action_pressed("Select_Weapon_2"):
		select_weapon(1)
	
	if event.is_action_pressed("Select_Weapon_3"):
		select_weapon(2)
		
	if event.is_action("Scroll_Up"):
		Weapon_Indicator = max(Weapon_Indicator - 1, 0)
		exit(Weapon_Stack[Weapon_Indicator])
		
	if event.is_action("Scroll_Down"):
		Weapon_Indicator = min(Weapon_Indicator + 1, Weapon_Stack.size() - 1)
		exit(Weapon_Stack[Weapon_Indicator])
	
	if event.is_action_pressed("Shoot"):
		shoot()
	
	if event.is_action_pressed("Reload"):
		reload()
	
#	if event.is_action_pressed("Drop"):
#		Drop(Current_Weapon.Weapon_Name)
		
func select_weapon(index: int):
	if index < Weapon_Stack.size():
		Weapon_Indicator = index
		exit(Weapon_Stack[Weapon_Indicator])

func Initialize(_start_weapons: Array):
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
	
	for i in _start_weapons:
		Weapon_Stack.push_back(i)
		
	Current_Weapon = Weapon_List[Weapon_Stack[0]]
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	emit_signal("Weapon_Type", Current_Weapon.Type)  # Emit the weapon type signal here
	enter()
	
func enter():
	Animation_Player.queue(Current_Weapon.Activate_Animation)
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	emit_signal("Weapon_Type", Current_Weapon.Type)  # Emit the weapon type signal here

func exit(_next_weapon: String):
	# Call exit in order to first change weapons
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Deactivate_Animation:
			Animation_Player.play(Current_Weapon.Deactivate_Animation)
			Next_Weapon = _next_weapon
	
func Change_Weapon(weapon_name):
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == Current_Weapon.Deactivate_Animation:
		Change_Weapon(Next_Weapon)
	
	if anim_name == Current_Weapon.Shoot_Animation and Current_Weapon.Auto_Fire == true:
		if Input.is_action_pressed("Shoot"):
			shoot()


func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if !Animation_Player.is_playing():
			Animation_Player.play(Current_Weapon.Shoot_Animation)
			Current_Weapon.Current_Ammo -= 1
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			var Camera_Collision = Get_Camera_Collision()
			match Current_Weapon.Type:
				NULL:
					print("Weapon not chosen")
				HITSCAN:
					Hit_Scan_Collision(Camera_Collision)
				PROJECTILE:
					Launch_Projectile(Camera_Collision)
	
	else:
		Animation_Player.play(Current_Weapon.Out_Of_Ammo_Animation)
	
func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		# If the current ammo is at the magazine capacity, no need to reload
		return
	
	if !Animation_Player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			# Reload if there's reserve ammo available
			Animation_Player.play(Current_Weapon.Reload_Animation)
			var Reload_Amount = min(Current_Weapon.Magazine - Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo)
			
			Current_Weapon.Current_Ammo += Reload_Amount
			Current_Weapon.Reserve_Ammo -= Reload_Amount
			
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			
		else:
			# If there is no reserve ammo, play the Out_Of_Ammo_Animation
			if Current_Weapon.Current_Ammo < Current_Weapon.Magazine:
				Animation_Player.play(Current_Weapon.Out_Of_Ammo_Animation)
			

func Get_Camera_Collision()->Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2) * Current_Weapon.Weapon_Range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	New_Intersection.set_exclude(Collision_Exclusion)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Collision_Point = Intersection.position
		return Collision_Point
	else:
		return Ray_End
	
	
func Hit_Scan_Collision(Collision_Point):
	var Bullet_Direction = (Collision_Point - Bullet_Point.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(Bullet_Point.get_global_transform().origin, Collision_Point + Bullet_Direction * 2)
	
	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Bullet_Collision:
		var Hit_Indicator = Debug_Bullet.instantiate()
		var world = get_tree().get_root().get_child(0)
		world.add_child(Hit_Indicator)
		Hit_Indicator.global_translate(Bullet_Collision.position)
		
		Hit_Scan_Damage(Bullet_Collision.collider, Bullet_Direction, Bullet_Collision.position)
	

func Hit_Scan_Damage(Collider, Direction, Position):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Collider.Hit_Successful(Current_Weapon.Damage, Direction, Position)

func Launch_Projectile(Point: Vector3):
	var Direction = (Point - Bullet_Point.get_global_transform().origin).normalized()
	var Projectile = Current_Weapon.Projectile_To_Load.instantiate()
	
	var Projectile_RID = Projectile.get_rid()
	Collision_Exclusion.push_front(Projectile_RID)
	Projectile.tree_exited.connect(Remove_Exclusion.bind(Projectile.get_rid()))
	
	Bullet_Point.add_child(Projectile)
	Projectile.Damage = Current_Weapon.Damage
	Projectile.set_linear_velocity(Direction * Current_Weapon.Projectile_Velocity)

func Remove_Exclusion(projectile_rid):
	Collision_Exclusion.erase(projectile_rid)


func _on_pick_up_detection_body_entered(body: Node3D) -> void:
	# Ensure the body is of the expected type
	if body is RigidBody3D:
		# Accessing weapon details from the body directly
		var weapon_name = body.weapon_name
		var current_ammo = body.current_ammo
		var reserve_ammo = body.reserve_ammo
		print(body.weapon_name)

		# Check if Weapon_Stack is initialized properly
		if Weapon_Stack == null:
			return

		var Weapon_In_Stack = Weapon_Stack.find(weapon_name)

		# Pick up Weapon if not already in inventory
		if Weapon_In_Stack == -1:
			Weapon_Stack.push_front(weapon_name)

		# Check if Weapon_List has the weapon_name key
		if not Weapon_List.has(weapon_name):
			return

		# Zero out ammo on weapon pickup
		Weapon_List[weapon_name].Current_Ammo = current_ammo
		Weapon_List[weapon_name].Reserve_Ammo = reserve_ammo

		emit_signal("Update_Weapon_Stack", Weapon_Stack)
		exit(weapon_name)

		# Correct the method call to queue_free
		body.queue_free()
		
		var remaining = Add_Ammo(body.weapon_name, body.current_ammo + body.reserve_ammo)
		if remaining == 0:
			body.queue_free()
		
		body.current_ammo = min(remaining, Weapon_List[body.weapon_name].Magazine)
		body.reserve_ammo = max(remaining - body.current_ammo, 0)

# func Drop(_name: String):
# 	var Weapon_Reference = Weapon_Stack.find(_name, 0)
# 	
# 	if Weapon_Reference != -1:
# 		Weapon_Stack.pop_at(Weapon_Reference)
# 		emit_signal("Update_Weapon_Stack", Weapon_Stack)
# 		
# 		if Weapon_List.has(_name):
# 			var weapon_resource = Weapon_List[_name]
# 			
# 			if weapon_resource.Weapon_Drop:
# 				var Weapon_Dropped = weapon_resource.Weapon_Drop.instantiate()
# 				Weapon_Dropped.current_ammo = weapon_resource.Current_Ammo
# 				Weapon_Dropped.reserve_ammo = weapon_resource.Reserve_Ammo
# 				
# 				Weapon_Dropped.set_global_transform(Bullet_Point.get_global_transform())
# 				var World = get_tree().get_root().get_child(0)
# 				World.add_child(Weapon_Dropped)
# 				
# 				if Weapon_Stack.size() > 0:
# 					exit(Weapon_Stack[0])
# 				else:
# 					exit("")
# 			else:
# 				print("Error: Weapon_Drop is null for weapon: " + _name)
# 		else:
# 			print("Error: Weapon_List does not contain weapon: " + _name)

func Add_Ammo(_Weapon: String, Ammo: int)-> int:
		var _weapon = Weapon_List[_Weapon]
		
		var Required = _weapon.Max_Ammo - _weapon.Reserve_Ammo
		var Remaining = max(Ammo - Required, 0)
		
		_weapon.Reserve_Ammo += min(Ammo, Required)
		emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
		return Remaining
