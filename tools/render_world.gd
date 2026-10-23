extends SceneTree

## Renderiza os elementos do cenário sobre a grama em docs/cenario.png. Rodar com:
##   godot --headless --path . --script res://tools/render_world.gd

const KINDS := ["oak", "pine", "bush", "rock_a", "rock_b", "log", "stump", "mushroom",
	"flowers_white", "flowers_red", "flowers_blue", "tuft", "dirt"]
const COLUMNS := 5
const CELL := Vector2i(300, 300)
const SCALE := 1.0


func _initialize() -> void:
	var grass := Image.load_from_file(ProjectSettings.globalize_path("res://assets/world/grass.png"))
	var rows := ceili(float(KINDS.size()) / COLUMNS)
	var sheet := Image.create(CELL.x * COLUMNS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	for y in sheet.get_height():
		for x in sheet.get_width():
			sheet.set_pixel(x, y, grass.get_pixel(x % grass.get_width(), y % grass.get_height()))
	for i in KINDS.size():
		var svg := FileAccess.get_file_as_string(WorldDecor.TYPES[KINDS[i]]["path"])
		var art := Image.new()
		art.load_svg_from_string(svg, SCALE)
		var column := i % COLUMNS
		var row := i / COLUMNS
		var target := Vector2i(column * CELL.x + (CELL.x - art.get_width()) / 2, row * CELL.y + (CELL.y - art.get_height()) / 2)
		sheet.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), target)
	sheet.save_png(ProjectSettings.globalize_path("res://docs/cenario.png"))
	print("cenário salvo em docs/cenario.png (%dx%d)" % [sheet.get_width(), sheet.get_height()])
	quit(0)
