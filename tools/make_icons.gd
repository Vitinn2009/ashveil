extends SceneTree

## Gera os ícones PNG da marca a partir dos SVGs. Rodar com:
##   godot --headless --path . --script res://tools/make_icons.gd

const OUT := "res://assets/brand/"


func _initialize() -> void:
	var icon_svg := FileAccess.get_file_as_string("res://assets/brand/icon.svg")
	var logo_svg := FileAccess.get_file_as_string("res://assets/brand/logo.svg")

	_save_svg(icon_svg, 512.0 / 512.0, "icon_512.png")
	_save_svg(icon_svg, 192.0 / 512.0, "icon_192.png")

	# Ícone adaptativo: 432x432 com o emblema dentro da zona segura central.
	var night := Color("1b1036")
	var background := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	background.fill(night)
	background.save_png(ProjectSettings.globalize_path(OUT + "icon_adaptive_background.png"))

	var emblem := Image.new()
	emblem.load_svg_from_string(logo_svg, 1.25)  # 250x300
	var foreground := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	var offset := Vector2i((432 - emblem.get_width()) / 2, (432 - emblem.get_height()) / 2)
	foreground.blend_rect(emblem, Rect2i(Vector2i.ZERO, emblem.get_size()), offset)
	foreground.save_png(ProjectSettings.globalize_path(OUT + "icon_adaptive_foreground.png"))

	print("ícones gerados em ", ProjectSettings.globalize_path(OUT))
	quit(0)


func _save_svg(svg: String, scale: float, file_name: String) -> void:
	var image := Image.new()
	image.load_svg_from_string(svg, scale)
	image.save_png(ProjectSettings.globalize_path(OUT + file_name))
