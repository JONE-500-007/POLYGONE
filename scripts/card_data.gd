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
