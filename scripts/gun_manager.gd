extends Node2D


var weapons = {}

var hud 
var currentWeapon
var currentWeaponSlot = "Empty"

var changingWeapon = false
var unequippedWeapon = false


func _ready() -> void:
	hud = owner.get_node("HUD")
	weapons = {
		"Empty" : $unarmed
	}
