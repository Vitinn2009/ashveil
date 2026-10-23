extends SceneTree

## Renderiza os três heróis lado a lado em docs/personagens.png. Rodar com:
##   godot --headless --path . --script res://tools/render_characters.gd

const HEROES := ["mage", "archer", "warrior"]
const SCALE := 2.5


func _initialize() -> void:
	var card_w := int(128 * SCALE) + 60
	var card_h := int(160 * SCALE) + 60
	var sheet := Image.create(card_w * HEROES.size(), card_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("1b1036"))
	for i in HEROES.size():
		var svg := FileAccess.get_file_as_string("res://assets/characters/%s.svg" % HEROES[i])
		var art := Image.new()
		art.load_svg_from_string(svg, SCALE)
		sheet.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), Vector2i(i * card_w + 30, 30))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/personagens.png"))
	print("render salvo em docs/personagens.png (%dx%d)" % [sheet.get_width(), sheet.get_height()])
	quit(0)
