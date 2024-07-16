extends Resource

class_name Weapon_Resource

@export var Weapon_Name: String
@export var Activate_Animation: String
@export var Shoot_Animation: String
@export var Reload_Animation: String
@export var Deactivate_Animation: String
@export var Out_Of_Ammo_Animation: String

@export var Current_Ammo: int
@export var Reserve_Ammo: int
@export var Magazine: int
@export var Max_Ammo: int

@export var Auto_Fire: bool = false
@export var Weapon_Range : int
@export var Damage: int
@export_flags("Hitscan", "Projectile") var Type
@export var Projectile_To_Load: PackedScene
@export var Projectile_Velocity: int

@export var Weapon_Drop: PackedScene
