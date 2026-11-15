extends CanvasLayer
class_name hudUI

@onready var ammolabel: Label = $MarginContainer/Ammo

func update_ammo_count(currentammo: int, maxammo: int) -> void:
	ammolabel.text = "Ammo: %d / %d" % [currentammo, maxammo]
