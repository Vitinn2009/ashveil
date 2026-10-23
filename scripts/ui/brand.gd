class_name Brand
extends RefCounted

## Paleta e componentes visuais da marca Ashveil. Ver docs/brand.md.

const NIGHT := Color("1b1036")
const EMBER := Color("ff7a1a")
const GOLD := Color("f2b705")
const PARCHMENT := Color("f4e9d8")
const MOSS := Color("3e6b48")


static func make_button(text: String, min_size := Vector2(260, 64)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", PARCHMENT)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_stylebox_override("normal", _box(Color("3a2566"), GOLD))
	button.add_theme_stylebox_override("hover", _box(Color("4c3080"), GOLD))
	button.add_theme_stylebox_override("pressed", _box(Color("2a1a4d"), EMBER))
	return button


static func make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _box(Color(NIGHT, 0.94), GOLD, 3, 14)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func make_box(background: Color, border: Color, border_width := 3, radius := 12) -> StyleBoxFlat:
	return _box(background, border, border_width, radius)


## Barra de progresso com fundo escuro e preenchimento colorido. Não usa
## `modulate`, que também tingiria o texto e os filhos da barra.
static func make_bar(fill_color: Color, bar_height := 22.0, bar_width := 0.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(bar_width, bar_height)
	var background := _box(Color("2a1f4d"), Color("6a5a9a"), 2, 6)
	var fill := _box(fill_color, fill_color, 0, 5)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func make_label(text := "", font_size := 18, color := PARCHMENT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


static func _box(background: Color, border: Color, border_width := 3, radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
