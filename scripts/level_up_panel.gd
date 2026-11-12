extends CanvasLayer

@export var card_scene: PackedScene
@export var card_pool: Array[CardData] = []
@export var choices := 3

@onready var root: Control = $Root
@onready var cards_box: HBoxContainer = $Root/Center/Cards

var _available: Array = []
var _shown: Array = []
var _pending := 0
var _open := false


func _ready() -> void:
	_available = card_pool.duplicate()
	root.hide()
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var xp := player.get_node("Experience") as Experience
	xp.leveled_up.connect(_on_leveled_up)


func _on_leveled_up(_level: int) -> void:
	_pending += 1  # level-ups queue up while cards are open
	if not _open:
		_show_next()


func _show_next() -> void:
	if _pending <= 0 or _available.is_empty():
		_close()
		return
	_pending -= 1
	_open = true
	_available.shuffle()
	_shown = _available.slice(0, choices)

	for old in cards_box.get_children():
		cards_box.remove_child(old)
		old.queue_free()
	for i in _shown.size():
		var button := card_scene.instantiate()
		cards_box.add_child(button)
		button.setup(_shown[i], i + 1)
		button.pressed.connect(_pick.bind(i))

	root.show()
	# Solo: time stops. Co-op: time keeps running.
	if get_tree().get_nodes_in_group("player").size() == 1:
		get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	for i in _shown.size():
		if event.is_action_pressed("card_%d" % (i + 1)):
			_pick(i)
			get_viewport().set_input_as_handled()
			return


func _pick(index: int) -> void:
	var card: CardData = _shown[index]
	_available.erase(card)
	print("Picked: ", card.display_name)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_item(card)
	_show_next()  # next queued level-up, or close if none


func _close() -> void:
	_open = false
	root.hide()
	get_tree().paused = false
