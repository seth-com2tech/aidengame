extends CharacterBody2D
class_name Enemy

var player: Player = null

const CHASESPEED: float = 200.0
const ROAMSPEED: float = 100.0
var speed : float
var direction := Vector2.ZERO
var startpos : Vector2

@export var dead = false
@export var state = "roaming"

@onready var check := $Check 
@onready var nav_agent := $NavigationAgent2D
@onready var enemy=$enemy
@onready var hitbox=$hitbox
@onready var debugPos=$dbgTargetPos
@onready var debugState=$dbgState



func _ready() -> void:
	await get_tree().process_frame
	startpos = global_position
	state_update("roaming")
	if player:
		nav_agent.target_position = player.global_position
	

func state_update(newstate):
	state = newstate
	debugPos.text = str(nav_agent.target_position)
	debugState.text = state
	print(state)
	if state == "dead":
		speed = 0
		dead = true
		enemy.play("death")
		z_index -= 1
		$CollisionShape2D.queue_free()
		
	if state == "chasing":
		nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_CORRIDORFUNNEL
		speed = CHASESPEED
		nav_agent.target_position = player.global_position
		
	if state == "roaming":
		nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED
		speed = ROAMSPEED
		nav_agent.target_position = startpos

#process of updating movement and pathfinding
func _physics_process(delta):
	if state == "dead":
		return
	if !nav_agent.is_navigation_finished():
		var next_path = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path)
		velocity =  direction * speed
		if velocity.length() > 0.1:
			enemy.look_at(next_path)
			enemy.play("walking")
		
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		enemy.play("idle")
		
		if not player:
			state_update("roaming")
				
	move_and_slide()


func _on_playerdetector_body_entered(body: Node2D) -> void:
	if body is Player:
		if player == null:
			player = body


func _on_playerdetector_body_exited(body: Node2D) -> void:
	if body is Player:
		if player != null:
			player = null
			



func _on_hitbox_area_entered(area: Area2D) -> void:
	if state != "dead":
		if area is Bullet:
			print("enemy dead")
			state_update("dead")


func _on_timer_timeout() -> void:
	if state != "dead":
		if player:
			check.look_at(player.global_position)
			if (check.is_colliding() && check.get_collider()==player) && nav_agent.target_position != player.global_position:
				state_update("chasing")
			
			$CheckTimer.start()
			$StuckTimer.start()


func _on_stuck_timer_timeout() -> void:
	var lastpos= position
	if state != "dead":
		if position == lastpos:
			state_update("roaming")
