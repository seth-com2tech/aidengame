extends Node
class_name WeaponManager
# Add this as a child node of Player (a plain Node named "WeaponManager").
# It handles shooting, reloading, ammo and weapon switching, so player.gd doesn't have to.

signal ammo_changed(current: int, max: int)   # connect to hud.update_ammo_count
signal weapon_changed(data: WeaponData)

# Leave empty to use the built-in weapons below, or drag WeaponData resources in here.
@export var weapons: Array[WeaponData] = []
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var start_weapon: int = 1        # index into the weapon list (0 = unarmed, 1 = pistol)
@export var auto_reload: bool = true     # reload automatically when you shoot an empty gun

var current: int = 0
var ammo: Array[int] = []                # rounds left in each weapon's magazine, same order as weapons
var reloading: bool = false
var next_shot_time: float = 0.0          # seconds (game clock) when the gun can fire again
var reload_timer := Timer.new()

# these are looked up from the Player this node is a child of
@onready var player = get_parent()
@onready var muzzle: Node2D = player.get_node("body/gun")
@onready var gunshot: AudioStreamPlayer2D = player.get_node("gunshot")
@onready var reload_sound: AudioStreamPlayer2D = player.get_node("reloadsound")


func _ready() -> void:
	if weapons.is_empty():
		weapons = _default_weapons()
	for w in weapons:
		ammo.append(w.magSize)           # every weapon starts with a full magazine
	current = clampi(start_weapon, 0, weapons.size() - 1)

	# A Timer only runs if it's in the scene tree (the old pistol.gd never added its Timer,
	# so start() failed). Adding it as a child fixes that.
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_finished)
	add_child(reload_timer)


func _physics_process(_delta: float) -> void:
	if player.dead:
		return
	var data := get_weapon()
	# Auto weapons fire while held, Semi weapons fire once per click
	var wants_fire: bool
	if data.shotType == "Auto":
		wants_fire = Input.is_action_pressed("shoot")
	else:
		wants_fire = Input.is_action_just_pressed("shoot")
	if wants_fire:
		try_fire()
	if Input.is_action_just_pressed("reload"):
		start_reload()


func _unhandled_input(event: InputEvent) -> void:
	if player.dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < weapons.size():
			switch_to(index)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			switch_to(wrapi(current - 1, 0, weapons.size()))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			switch_to(wrapi(current + 1, 0, weapons.size()))


func get_weapon() -> WeaponData:
	return weapons[current]


func try_fire() -> void:
	var data := get_weapon()
	if data.magSize <= 0 or reloading:
		return                                    # unarmed, or mid-reload
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < next_shot_time:
		return                                    # still cooling down
	if ammo[current] <= 0:
		if auto_reload:
			start_reload()
		return

	next_shot_time = now + data.fireRate
	ammo[current] -= 1

	# one bullet per pellet, each rotated randomly inside the spread cone
	var aim: Vector2 = (player.get_global_mouse_position() - player.global_position).normalized()
	for i in data.pellets:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position
		bullet.direction = aim.rotated(deg_to_rad(randf_range(-data.spread / 2.0, data.spread / 2.0)))

	gunshot.play(0.13)
	_emit_ammo()


func start_reload() -> void:
	var data := get_weapon()
	if data.magSize <= 0 or reloading or ammo[current] == data.magSize:
		return
	reloading = true
	reload_timer.start(data.reloadTime)
	reload_sound.play()
	_emit_ammo()                                  # HUD shows 0 while reloading, like before


func _on_reload_finished() -> void:
	reloading = false
	ammo[current] = get_weapon().magSize
	_emit_ammo()


func switch_to(index: int) -> void:
	if index == current:
		return
	# switching cancels an in-progress reload
	reload_timer.stop()
	reload_sound.stop()
	reloading = false
	current = index
	weapon_changed.emit(get_weapon())
	_emit_ammo()


# Which animation the player's "body" sprite should play for the current weapon.
func body_animation(moving: bool) -> String:
	var data := get_weapon()
	if moving and data.bodyAnimWalk != "":
		return data.bodyAnimWalk
	return data.bodyAnim


# Call once from player.gd after connecting the signals, so the HUD gets the starting values.
func refresh() -> void:
	weapon_changed.emit(get_weapon())
	_emit_ammo()


func _emit_ammo() -> void:
	ammo_changed.emit(0 if reloading else ammo[current], get_weapon().magSize)


# ---- built-in weapons (edit the numbers here, or replace with .tres resources later) ----
func _default_weapons() -> Array[WeaponData]:
	var list: Array[WeaponData] = []
	#                 name        type    rate  mag reload pellets spread anim        walk anim
	list.append(_make("Unarmed", "Semi", 0.0,  0,  0.0,   1,      0.0,   "fistidle", "fistwalk"))
	list.append(_make("Pistol",  "Semi", 0.2,  12, 1.5,   1,      0.0,   "pistol"))
	list.append(_make("Shotgun", "Semi", 0.9,  6,  2.5,   6,      25.0,  "shotgun"))
	list.append(_make("SMG",     "Auto", 0.07, 30, 2.0,   1,      6.0,   "pistol"))
	return list


func _make(weapon_name: String, shot_type: String, fire_rate: float, mag: int, reload_time: float,
		pellet_count: int, spread_deg: float, anim: String, anim_walk: String = "") -> WeaponData:
	var data := WeaponData.new()
	data.weaponName = weapon_name
	data.shotType = shot_type
	data.fireRate = fire_rate
	data.magSize = mag
	data.reloadTime = reload_time
	data.pellets = pellet_count
	data.spread = spread_deg
	data.bodyAnim = anim
	data.bodyAnimWalk = anim_walk
	return data
