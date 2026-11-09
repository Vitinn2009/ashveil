class_name StatusFrame
extends PanelContainer

## Quadro de status no canto da tela: retrato do herói numa moldura, nome e
## nível, barra de vida (rubi), de energia (safira) e de XP (ouro).

const WIDTH := 316.0

var hp_bar: MedievalBar
var energy_bar: MedievalBar
var stamina_bar: MedievalBar
var xp_bar: MedievalBar
var _portrait: Portrait
var _name_label: Label


## Retrato quadrado com moldura de latão e um medalhão com o nível.
class Portrait extends Control:
	var texture: Texture2D
	var level := 1:
		set(value):
			if value != level:
				level = value
				queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(76, 76)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("120a05"))
		draw_rect(rect.grow(-3.0), Color("3a2a52"))
		if texture:
			draw_texture_rect(texture, rect.grow(-4.0), false)
		draw_rect(rect, Brand.BRASS_DARK, false, 3.0)
		draw_rect(rect.grow(-1.5), Color(Brand.BRASS, 0.55), false, 1.0)
		var badge := Vector2(size.x - 10.0, size.y - 8.0)
		draw_circle(badge, 15.0, Color("120a05"))
		draw_circle(badge, 13.0, Brand.BRASS)
		draw_circle(badge, 10.5, Color("3a2414"))
		var font := get_theme_default_font()
		var text := str(level)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 15)
		draw_string(font, badge + Vector2(-text_size.x * 0.5, 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe9a8"))


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := Brand.make_box(Color(Brand.WOOD, 0.9), Brand.BRASS_DARK, 3, 10)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 5
	add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	_portrait = Portrait.new()
	row.add_child(_portrait)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	_name_label = Brand.make_label("", 17, Color("ffe9a8"))
	_name_label.add_theme_color_override("font_outline_color", Color("120a05"))
	_name_label.add_theme_constant_override("outline_size", 4)
	column.add_child(_name_label)
	hp_bar = MedievalBar.new(20.0)
	hp_bar.icon_kind = "heart"
	hp_bar.fill_top = Color("ec5a48")
	hp_bar.fill_bottom = Color("9a2620")
	column.add_child(hp_bar)
	energy_bar = MedievalBar.new(16.0)
	energy_bar.icon_kind = "bolt"
	energy_bar.fill_top = Color("5aa8ff")
	energy_bar.fill_bottom = Color("2358b0")
	column.add_child(energy_bar)
	stamina_bar = MedievalBar.new(14.0)
	stamina_bar.fill_top = Color("e8c64a")
	stamina_bar.fill_bottom = Color("a8861a")
	stamina_bar.show_ticks = false
	column.add_child(stamina_bar)
	xp_bar = MedievalBar.new(16.0)
	xp_bar.fill_top = Color("f2c94a")
	xp_bar.fill_bottom = Color("b8861a")
	xp_bar.show_ticks = false
	column.add_child(xp_bar)
	add_child(Ornaments.new())


func setup_hero(hero: Dictionary) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(hero["art"])
	atlas.region = Rect2(14, 4, 100, 100)
	_portrait.texture = atlas
	_portrait.queue_redraw()


func set_title(hero_name: String, level: int) -> void:
	_name_label.text = hero_name
	_portrait.level = level
