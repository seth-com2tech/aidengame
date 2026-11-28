extends CharacterBody2D
class_name Player

signal died

var dead: bool = false
const SPEED: float = 500.0

@onready var legsanim = $legs
@onready var bodyanim = $body
@onready var weapon_manager: WeaponManager = $WeaponManager
@export var hud: hudUI

func _ready() -> void:
	hud.show()
	weapon_manager.ammo_changed.connect(hud.update_ammo_count)
	weapon_manager.refresh()

func _process(delta):
	if dead==false:
		look_at(get_global_mouse_position())

func _physics_process(delta):
	if dead==false:
		var move_dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
		var moving: bool = move_dir != Vector2.ZERO

		if moving:
			velocity = SPEED * move_dir.normalized()
			legsanim.play("walking")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.y = move_toward(velocity.y, 0, SPEED)
			legsanim.play("idle")

		bodyanim.play(weapon_manager.body_animation(moving))

		move_and_slide()


func _on_hitbox_body_entered(body):
	if body is Enemy:
		var enemy = body
		if enemy.state != "dead":
			legsanim.play("dead")
			bodyanim.hide()
			dead = true
			died.emit()
			z_index -= 1
