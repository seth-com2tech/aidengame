extends CharacterBody2D
class_name Enemy

var player: Player = null

const CHASESPEED: float = 200.0
const ROAMSPEED: float = 100.0

const ROAM_RADIUS: float = 400.0
const ROAM_MIN_DIST: float = 100.0
const ROAM_WAIT_MIN: float = 1.0
const ROAM_WAIT_MAX: float = 3.0
var speed : float
var direction := Vector2.ZERO
var startpos : Vector2
var lastpos : Vector2
var navready : bool = false
var waiting : bool = false
var roamwait : float = 0.0

var debugPos = Label.new()
var debugState = Label.new()
@export var dead = false
@export var state = "roaming"

@onready var check := $Check 
@onready var nav_agent := $NavigationAgent2D
@onready var bodyanim=$body
@onready var legsanim=$legs
@onready var hitbox=$hitbox



func _ready() -> void:
	$CheckTimer.wait_time = 0.2 
	$StuckTimer.wait_time = 1.0

	await get_tree().physics_frame
	await get_tree().physics_frame
	startpos = global_position
	lastpos = global_position
	navready = true
	state_update("roaming")
	
	debugPos.position = Vector2(-40,-40)
	add_child(debugPos)
	debugState.position = Vector2(-30,30)
	add_child(debugState)
	
	if player:
		nav_agent.target_position = player.global_position
	$StuckTimer.start()

func state_update(newstate):
	state = newstate
	
	debugPos.text = str(nav_agent.target_position)
	debugState.text = state
	debugPos.rotation = -get_parent().global_rotation
	print(state)
	if state == "dead":
		speed = 0
		dead = true
		legsanim.play("dead")
		z_index -= 1
		$CollisionShape2D.queue_free()
		
	if state == "chasing":
		speed = CHASESPEED
		waiting = false
		nav_agent.target_position = player.global_position
		
	if state == "roaming":
		speed = ROAMSPEED
		waiting = false
		pick_roam_target()

func pick_roam_target() -> void:
	var map: RID = nav_agent.get_navigation_map()
	for i in 8:
		var offset: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(ROAM_MIN_DIST, ROAM_RADIUS)
		var point: Vector2 = NavigationServer2D.map_get_closest_point(map, startpos + offset)
		var path: PackedVector2Array = NavigationServer2D.map_get_path(map, global_position, point, true)
		if path.size() > 1 and path[path.size() - 1].distance_to(point) < 10.0:
			nav_agent.target_position = point
			debugPos.text = str(nav_agent.target_position)
			return
	nav_agent.target_position = global_position

#process of updating movement and pathfinding
func _physics_process(delta):
	if state == "dead":
		return
	if not navready:
		return
	if !nav_agent.is_navigation_finished():
		waiting = false
		var next_path = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path)
		velocity =  direction * speed
		if velocity.length() > 0.1:
			self.look_at(next_path)
			legsanim.play("walking")
		
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		legsanim.play("idle")
		
		if state == "chasing" and not player:
			state_update("roaming")
		elif state == "roaming":
			if not waiting:
				waiting = true
				roamwait = randf_range(ROAM_WAIT_MIN, ROAM_WAIT_MAX)
			else:
				roamwait -= delta
				if roamwait <= 0.0:
					waiting = false
					pick_roam_target() 
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
	if state != "dead" and navready:
		if player:
			check.look_at(player.global_position)
			check.force_raycast_update()
			if check.is_colliding() && check.get_collider()==player:
				if state != "chasing":
					state_update("chasing")
				else:
					nav_agent.target_position = player.global_position
					debugPos.text = str(nav_agent.target_position)
				
			$CheckTimer.start()


func _on_stuck_timer_timeout() -> void:
	if state == "dead" or not navready:
		return
	var moved: float = global_position.distance_to(lastpos)
	lastpos = global_position
	if moved < 5.0 and not nav_agent.is_navigation_finished():
		if state == "roaming":
			pick_roam_target()
		elif state == "chasing" and player:
			nav_agent.target_position = player.global_position
