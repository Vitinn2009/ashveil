extends SceneTree

## Gera a textura de grama seamless (assets/world/grass.png). Rodar com:
##   godot --headless --path . --script res://tools/make_grass.gd

const SIZE := 256
const DARK := Color("2f5d29")
const MID := Color("3f7c35")
const LIGHT := Color("5b9e45")
const DRY := Color("80a042")


func _initialize() -> void:
	var large := FastNoiseLite.new()
	large.seed = 7
	large.frequency = 0.012
	large.fractal_octaves = 3
	var fine := FastNoiseLite.new()
	fine.seed = 21
	fine.frequency = 0.09
	var large_map := large.get_seamless_image(SIZE, SIZE, false, false, 0.2, true)
	var fine_map := fine.get_seamless_image(SIZE, SIZE, false, false, 0.2, true)

	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var patch := large_map.get_pixel(x, y).r
			var grain := fine_map.get_pixel(x, y).r
			var color := DARK.lerp(MID, smoothstep(0.2, 0.55, patch)).lerp(LIGHT, smoothstep(0.55, 0.9, patch))
			color = color.lerp(DRY, smoothstep(0.7, 1.0, grain) * 0.3)
			var shade := 1.0 + (grain - 0.5) * 0.22
			image.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, 1.0))

	# Folhas de grama: traços curtos que dão textura de perto. As coordenadas
	# dão a volta nas bordas, então a textura continua sem emendas.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 4200:
		var x := rng.randf() * SIZE
		var y := rng.randf() * SIZE
		var length := rng.randi_range(3, 8)
		var angle := rng.randf_range(-2.0, -1.1)
		var base := LIGHT if rng.randf() < 0.55 else DARK
		var blade := base.lerp(Color.WHITE if rng.randf() < 0.3 else Color.BLACK, rng.randf_range(0.05, 0.22))
		for step in length:
			var px := posmod(int(x + cos(angle) * step), SIZE)
			var py := posmod(int(y + sin(angle) * step), SIZE)
			var fade := 0.85 - 0.5 * float(step) / length
			image.set_pixel(px, py, image.get_pixel(px, py).lerp(blade, fade))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/world"))
	image.save_png(ProjectSettings.globalize_path("res://assets/world/grass.png"))
	print("grama gerada: %dx%d" % [SIZE, SIZE])
	quit(0)
