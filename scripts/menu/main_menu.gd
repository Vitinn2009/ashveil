extends Control

const GAME_SCENE := "res://scenes/Game.tscn"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Brand.NIGHT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	add_child(column)

	var logo := TextureRect.new()
	logo.texture = load("res://assets/brand/logo.svg")
	logo.custom_minimum_size = Vector2(0, 180)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(logo)

	column.add_child(_make_title("ASHVEIL", 56, Brand.GOLD))
	column.add_child(_make_title("Sobreviva. Evolua. Forje seu destino.", 20, Brand.PARCHMENT))

	var play := Brand.make_button("Jogar")
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
	column.add_child(play)

	column.add_child(_make_title("Protótipo M1", 14, Brand.MOSS))


func _make_title(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
