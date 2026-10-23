extends Control

const SELECT_SCENE := "res://scenes/CharacterSelect.tscn"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Brand.NIGHT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Campo de grama com árvores atrás dos heróis.
	var ground := TextureRect.new()
	ground.texture = load("res://assets/world/grass.png")
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -210.0
	add_child(ground)
	_add_scenery("res://assets/world/tree_pine.svg", 0.07, Vector2(150, 285), 232.0)
	_add_scenery("res://assets/world/tree_oak.svg", 0.93, Vector2(260, 325), 232.0)
	_add_scenery("res://assets/world/tree_pine.svg", 0.18, Vector2(110, 210), 200.0)
	_add_scenery("res://assets/world/bush.svg", 0.84, Vector2(150, 107), 180.0)
	_add_scenery("res://assets/world/rock_a.svg", 0.27, Vector2(110, 77), 168.0)

	var heroes := HBoxContainer.new()
	heroes.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	heroes.offset_top = -330.0
	heroes.offset_bottom = -30.0
	heroes.alignment = BoxContainer.ALIGNMENT_CENTER
	heroes.add_theme_constant_override("separation", 70)
	add_child(heroes)
	for id in ["mage", "warrior", "archer"]:
		heroes.add_child(_make_hero_art(id, 1.0 if id == "warrior" else 0.82))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.offset_top = 36.0
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	var logo := TextureRect.new()
	logo.texture = load("res://assets/brand/logo.svg")
	logo.custom_minimum_size = Vector2(150, 150)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(logo)

	column.add_child(_make_title("ASHVEIL", 64, Brand.GOLD))
	column.add_child(_make_title("Sobreviva. Evolua. Forje seu destino.", 22, Brand.PARCHMENT))

	var play := Brand.make_button("Jogar", Vector2(280, 68))
	play.add_theme_font_size_override("font_size", 30)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void: get_tree().change_scene_to_file(SELECT_SCENE))
	column.add_child(play)

	var version := _make_title("Protótipo v0.5", 14, Brand.MOSS.lightened(0.4))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -200.0
	version.offset_top = -30.0
	version.offset_right = -12.0
	version.offset_bottom = -8.0
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)


## Coloca um elemento do cenário com a base na altura `base_y` acima do rodapé.
func _add_scenery(path: String, anchor_x: float, size: Vector2, base_y: float) -> void:
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.anchor_left = anchor_x
	art.anchor_right = anchor_x
	art.anchor_top = 1.0
	art.anchor_bottom = 1.0
	art.offset_left = -size.x * 0.5
	art.offset_right = size.x * 0.5
	art.offset_bottom = -base_y + 12.0
	art.offset_top = art.offset_bottom - size.y
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)


func _make_hero_art(id: String, scale_factor: float) -> TextureRect:
	var art := TextureRect.new()
	art.texture = load(Heroes.get_hero(id)["art"])
	art.custom_minimum_size = Vector2(192, 240) * scale_factor
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_SHRINK_END
	return art


func _make_title(text: String, font_size: int, color: Color) -> Label:
	var label := Brand.make_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
