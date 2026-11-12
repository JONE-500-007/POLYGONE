extends Button

@onready var icon_rect: TextureRect = $VBox/IconRect
@onready var name_label: Label = $VBox/NameLabel
@onready var desc_label: Label = $VBox/DescLabel


func setup(card: CardData, number: int) -> void:
	icon_rect.texture = card.icon
	name_label.text = "%d. %s" % [number, card.display_name]
	desc_label.text = card.description
