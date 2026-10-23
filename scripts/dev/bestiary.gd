extends Node2D

## Cena de desenvolvimento: mostra os 5 inimigos lado a lado, com nome e
## característica. Não faz parte do fluxo do jogo.

const SPACING := 240.0
const ENEMY_SCALE := 2.0


func _ready() -> void:
	var camera := Camera2D.new()
	add_child(camera)
	var kinds := EnemyTypes.DATA.keys()
	var first_x := -SPACING * (kinds.size() - 1) * 0.5
	camera.position = Vector2(0, 60)

	var title := Brand.make_label("Bestiário de Ashveil", 40, Brand.GOLD)
	title.position = Vector2(-300, -250)
	title.custom_minimum_size = Vector2(600, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	for i in kinds.size():
		var kind: String = kinds[i]
		var data := EnemyTypes.get_type(kind)
		var x := first_x + i * SPACING

		var enemy := Enemy.new()
		enemy.setup(kind, 0.0)
		enemy.scale = Vector2(ENEMY_SCALE, ENEMY_SCALE)
		enemy.position = Vector2(x, 20)
		if kind == "bomber":
			enemy._fuse = 0.5
		add_child(enemy)

		var name_label := Brand.make_label(data["name"], 26, Brand.GOLD)
		name_label.position = Vector2(x - SPACING * 0.45, 130)
		name_label.custom_minimum_size = Vector2(SPACING * 0.9, 0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)

		var trait_label := Brand.make_label(data["trait"], 17)
		trait_label.position = Vector2(x - SPACING * 0.45, 170)
		trait_label.custom_minimum_size = Vector2(SPACING * 0.9, 0)
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(trait_label)

		var stats := Brand.make_label("Vida %d · Vel. %d · Dano %d · XP %d" % [
			data["health"], data["speed"], data["damage"], data["xp"]], 14, Color("a8a2c8"))
		stats.position = Vector2(x - SPACING * 0.45, 240)
		stats.custom_minimum_size = Vector2(SPACING * 0.9, 0)
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(stats)
