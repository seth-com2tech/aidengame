extends Node2D

@onready var player = $Player

func _ready() -> void:
	player.died.connect(_on_player_died)
	$NavigationRegion/FLOOR.navigation_enabled = false

	await get_tree().physics_frame
	await get_tree().physics_frame
	var map: RID = get_world_2d().get_navigation_map()
	print("nav regions in map: ", NavigationServer2D.map_get_regions(map).size())


func _on_player_died():
	print("you died")
	get_tree().create_timer(3).timeout.connect(get_tree().reload_current_scene)
