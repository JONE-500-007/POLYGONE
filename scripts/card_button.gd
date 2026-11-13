extends Button

@onready var icon_rect: TextureRect = $VBox/IconRect
@onready var name_label: Label = $VBox/NameLabel
@onready var desc_label: Label = $VBox/DescLabel


func setup(card: CardData, number: int, new_level: int) -> void:
	icon_rect.texture = card.icon
	name_label.text = "%d. %s  Lv.%d" % [number, card.display_name, new_level]
	# Level 1 shows the item description, upgrades show what the new level gives.
	if new_level > 1:
		desc_label.text = card.levels[new_level - 2].description
	else:
		desc_label.text = card.description
