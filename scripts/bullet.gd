extends Area2D
class_name Bullet

var direction: Vector2
const SPEED = 30


func _physics_process(delta: float) -> void:
	global_position+=direction*SPEED
	scale *=0.99


func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	queue_free()
