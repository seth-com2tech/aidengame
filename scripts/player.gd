extends CharacterBody2D
class_name Player

signal died

var bulletscene = preload("res://scenes/bullet.tscn")
var delaying: bool = false
var dead: bool = false
var reloading: bool = false
var currentammo: int = 20
var maxammo: int = 20
const SPEED: float = 500.0

@onready var playeranim=$body
@onready var gun=$body/barrel
@onready var gunshot = $gunshot
@onready var reloadsound = $reloadsound
@export var hud: hudUI

func _ready() -> void:
	hud.update_ammo_count(currentammo, maxammo)
	hud.show()
	
func _process(delta):
	if dead==false:
		look_at(get_global_mouse_position())

func _physics_process(delta):
	if dead==false:
		var move_dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
		
		if move_dir != Vector2.ZERO:
			velocity = SPEED * move_dir.normalized()
			playeranim.play("walking")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.y = move_toward(velocity.y, 0, SPEED)
			playeranim.play("idle")
		
		#gun
		if Input.is_action_pressed("shoot") && !delaying && !reloading && currentammo > 0:
			var bullet=bulletscene.instantiate()
			bullet.global_position = gun.global_position
			bullet.direction = (get_global_mouse_position()-global_position).normalized()
			$/root/Main.add_child(bullet)
			gunshot.play(0.13)
			$shootdelay.start()
			delaying = true
			currentammo -= 1
			hud.update_ammo_count(currentammo, maxammo)
			
		if Input.is_action_just_pressed("reload") && currentammo != maxammo:
			reloading = true
			$reload.start()
			hud.update_ammo_count(0, maxammo)
			reloadsound.play()
		move_and_slide()


func _on_hitbox_body_entered(body):
	if body is Enemy:
		var enemy = body
		if enemy.state != "dead":
			playeranim.play("dead")
			dead = true
			died.emit()
			z_index -= 1
		
		


func _on_shootdelay_timeout() -> void:
	delaying = false # Replace with function body.


func _on_reload_timeout() -> void:
	reloading = false
	currentammo = maxammo
	hud.update_ammo_count(currentammo, maxammo)
