extends Node2D

@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.died.connect(_on_player_died)
	#player.camera_remote_transform.remote_path = camera.get_path()



 #Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_player_died():
	print("you died")
	get_tree().create_timer(3).timeout.connect(get_tree().reload_current_scene)
