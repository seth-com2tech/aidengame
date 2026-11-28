extends Resource
class_name WeaponData

@export var weaponName: String = "NewWeapon"
# "Semi" = one shot per click, "Auto" = keeps firing while the button is held
# (was "Default" before, it now shows up as a dropdown in the inspector)
@export_enum("Semi", "Auto") var shotType: String = "Semi"
@export var fireRate: float = 0.0       # seconds between shots

@export var magSize: int = 12           # bullets per magazine (0 = can't shoot, e.g. unarmed)
@export var reloadTime: float = 1.5     # seconds a reload takes
@export var pellets: int = 1            # bullets fired per shot (shotgun = several)
@export var spread: float = 0.0         # total cone in degrees the bullets are randomly spread across

# animations on the player's "body" AnimatedSprite2D
@export var bodyAnim: String = ""       # used when standing still
@export var bodyAnimWalk: String = ""   # used when moving (empty = reuse bodyAnim)
