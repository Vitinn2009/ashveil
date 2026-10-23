extends Control

const SELECT_SCENE := "res://scenes/CharacterSelect.tscn"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Brand.NIGHT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Chão e brasas ao fundo, para dar clima à tela inicial.
	var ground := ColorRect.new()
	ground.color = Color("120a24")
	ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -210.0
	add_child(ground)

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

	var version := _make_title("Protótipo v0.4", 14, Brand.MOSS.lightened(0.4))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -200.0
	version.offset_top = -30.0
	version.offset_right = -12.0
	version.offset_bottom = -8.0
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)


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
