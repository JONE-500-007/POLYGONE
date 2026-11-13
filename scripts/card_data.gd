class_name CardData
extends Resource

enum Kind { WEAPON, PASSIVE }

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var kind: Kind = Kind.WEAPON
# For weapon cards: the scene that is added to the player when this weapon is equipped.
@export var weapon_scene: PackedScene
# Bonus already given at level 1 (used by passives; weapons can leave it empty).
@export var base_bonus: CardLevel
# Bonuses for level 2, 3, 4 ... (index 0 = level 2). Max level = size + 1.
@export var levels: Array[CardLevel] = []

var max_level: int:
	get:
		return levels.size() + 1
