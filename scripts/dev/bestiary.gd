extends Node2D

## Cena de desenvolvimento: mostra todos os inimigos lado a lado, com nome e
## característica. Não faz parte do fluxo do jogo.

const COLUMNS := 6
const SPACING := Vector2(215.0, 300.0)
const ENEMY_SCALE := 1.7


func _ready() -> void:
	var camera := Camera2D.new()
	add_child(camera)
	var kinds := EnemyTypes.DATA.keys()
	var rows := ceili(float(kinds.size()) / COLUMNS)
	camera.position = Vector2(0, 40)

	var title := Brand.make_label("Bestiário de Ashveil", 38, Brand.GOLD)
	title.position = Vector2(-300, -SPACING.y * rows * 0.5 - 90.0)
	title.custom_minimum_size = Vector2(600, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	for i in kinds.size():
		var kind: String = kinds[i]
		var data := EnemyTypes.get_type(kind)
		var column := i % COLUMNS
		var row := i / COLUMNS
		var in_row := mini(COLUMNS, kinds.size() - row * COLUMNS)
		var x := (column - (in_row - 1) * 0.5) * SPACING.x
		var y := (row - (rows - 1) * 0.5) * SPACING.y - 30.0

		var enemy := Enemy.new()
		enemy.setup(kind, 0.0)
		enemy.scale = Vector2(ENEMY_SCALE, ENEMY_SCALE)
		enemy.position = Vector2(x, y)
		if kind == "bomber":
			enemy._fuse = 0.5
		if kind == "wolf":
			enemy._wolf_state = "windup"
			enemy._wolf_dir = Vector2.RIGHT
		add_child(enemy)

		var name_label := Brand.make_label(data["name"], 20, Brand.GOLD)
		name_label.position = Vector2(x - SPACING.x * 0.47, y + 70)
		name_label.custom_minimum_size = Vector2(SPACING.x * 0.94, 0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)

		var trait_label := Brand.make_label(data["trait"], 13)
		trait_label.position = Vector2(x - SPACING.x * 0.47, y + 98)
		trait_label.custom_minimum_size = Vector2(SPACING.x * 0.94, 0)
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(trait_label)

		var stats := Brand.make_label("Vida %d · Vel. %d · Dano %d · XP %d" % [
			data["health"], data["speed"], data["damage"], data["xp"]], 12, Color("a8a2c8"))
		stats.position = Vector2(x - SPACING.x * 0.47, y + 158)
		stats.custom_minimum_size = Vector2(SPACING.x * 0.94, 0)
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(stats)
