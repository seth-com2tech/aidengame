extends Node2D
class_name Weapon

var weaponManager = null 
var player = null
var animationPlayer

var isEquipped = false
var isFiring = false
var isReloading = false

@export var weaponName = "Weapon"

func update_ammo(action = "Refresh"):
	var weaponData = {
		"Name" : weaponName
	}
	#weaponManager.update_hud(weapon_data)
