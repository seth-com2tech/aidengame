extends Node2D
class_name Shotgun

var data: WeaponData
var canShoot = true

@onready var cooldownTimer = Timer.new()

func _ready() -> void:
	cooldownTimer.one_shot = true
	cooldownTimer.timeout.connect(_on_cooldown_finished)



func shoot():
	if !canShoot:
		return
	canShoot = false
	cooldownTimer.start(data.fireRate)
	
	

func _on_cooldown_finished():
	canShoot = true
