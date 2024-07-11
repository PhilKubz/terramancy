extends Node3D

@onready var Animation_Player = $FPS_Rig/AnimationPlayer

var Current_Weapon = null

var Weapon_Stack = []

var Weapon_Indicator = 0

var Next_Weapon: String

var Weapon_List = {}

@export var _weapon_resources: Array(Weapon_Resource)

@export var Start_Weapons: Array(String)

