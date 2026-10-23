extends Control

const GAME_SCENE := "res://scenes/Game.tscn"
const MENU_SCENE := "res://scenes/Main.tscn"
const MAX_HEALTH := 150.0
const MAX_SPEED := 240.0
const MAX_DAMAGE := 20.0

var _selected := "mage"
var _cards := {}
var _start_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Brand.NIGHT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 24.0
	column.offset_right = -24.0
	column.offset_top = 16.0
	column.offset_bottom = -16.0
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	var title := Brand.make_label("Escolha seu herói", 38, Brand.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 22)
	column.add_child(cards)
	for id in Heroes.ids():
		var card := _make_card(id)
		_cards[id] = card
		cards.add_child(card)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	column.add_child(buttons)
	var back := Brand.make_button("Voltar", Vector2(200, 60))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	buttons.add_child(back)
	_start_button = Brand.make_button("Começar", Vector2(380, 60))
	_start_button.pressed.connect(start_game)
	buttons.add_child(_start_button)

	select_hero(Session.hero_id if Heroes.DATA.has(Session.hero_id) else "mage")


func select_hero(id: String) -> void:
	_selected = id
	for card_id in _cards:
		var chosen: bool = card_id == id
		var border: Color = Brand.GOLD if chosen else Color("5a4a8a")
		var bg := Color("2a1a4d") if chosen else Color(Brand.NIGHT, 0.9)
		_cards[card_id].add_theme_stylebox_override("panel", _card_style(bg, border, 5 if chosen else 2))
		_cards[card_id].modulate = Color.WHITE if chosen else Color(0.82, 0.82, 0.88)
	_start_button.text = "Começar com %s" % Heroes.get_hero(id)["name"]


func start_game() -> void:
	Session.hero_id = _selected
	get_tree().change_scene_to_file(GAME_SCENE)


func _card_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := Brand.make_box(background, border, width, 16)
	style.set_content_margin_all(14)
	return style


func _make_card(id: String) -> PanelContainer:
	var hero := Heroes.get_hero(id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 0)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			select_hero(id))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)

	var art := TextureRect.new()
	art.texture = load(hero["art"])
	art.custom_minimum_size = Vector2(0, 210)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(art)

	var name_label := Brand.make_label(hero["name"], 30, hero["color"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var role := Brand.make_label(hero["title"], 15, Brand.GOLD)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(role)

	var description := Brand.make_label(hero["description"], 14)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(300, 40)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)

	box.add_child(_make_stat_row("Vida", hero["health"] / MAX_HEALTH, Brand.EMBER))
	box.add_child(_make_stat_row("Dano", hero["damage"] / MAX_DAMAGE, Brand.GOLD))
	box.add_child(_make_stat_row("Veloc.", hero["speed"] / MAX_SPEED, Brand.MOSS.lightened(0.3)))

	box.add_child(Brand.make_label("Habilidades", 15, Brand.GOLD))
	for skill_id in hero["skills"]:
		var skill := Skills.def(skill_id)
		var line := Brand.make_label("• %s: %s" % [skill["name"], skill["desc"]], 13, Color("d8d2f0"))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(300, 0)
		box.add_child(line)

	_ignore_mouse(card, card)
	return card


func _make_stat_row(label_text: String, ratio: float, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Brand.make_label(label_text, 14)
	label.custom_minimum_size = Vector2(56, 0)
	row.add_child(label)
	var bar := Brand.make_bar(color, 14.0)
	bar.max_value = 1.0
	bar.value = clampf(ratio, 0.05, 1.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	return row


## Só o cartão recebe cliques; os filhos deixam o clique passar.
func _ignore_mouse(node: Node, root: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(child, root)
