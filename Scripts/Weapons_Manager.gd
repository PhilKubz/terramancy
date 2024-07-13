extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var Animation_Player = $FPS_Rig/AnimationPlayer
@onready var Bullet_Point = $FPS_Rig/Bullet_Point

var Current_Weapon = null
var Weapon_Stack = []
var Weapon_Indicator = 0
var Next_Weapon: String
var Weapon_List = {}

@export var _weapon_resources: Array[Weapon_Resource] = []
@export var Start_Weapons: Array[String] = []

enum {NULL, HITSCAN, PROJECTILE}

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
	enter()
	
func enter():
	Animation_Player.queue(Current_Weapon.Activate_Animation)
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])

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
					pass
	
	else:
		Animation_Player.play(Current_Weapon.Out_Of_Ammo_Animation)
	
func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif !Animation_Player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			Animation_Player.play(Current_Weapon.Reload_Animation)
			var Reload_Amount = min(Current_Weapon.Magazine - Current_Weapon.Current_Ammo, Current_Weapon.Magazine, Current_Weapon.Reserve_Ammo)
			
			Current_Weapon.Current_Ammo += Reload_Amount
			Current_Weapon.Reserve_Ammo -= Reload_Amount
			
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			
		else:
			Animation_Player.play(Current_Weapon.Out_Of_Ammo_Animation)
			

func Get_Camera_Collision()->Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2) * Current_Weapon.Weapon_Range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
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
		Hit_Scan_Damage(Bullet_Collision.collider)
	

func Hit_Scan_Damage(Collider):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Collider.Hit_Successful(Current_Weapon.Damage)
