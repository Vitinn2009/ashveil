extends Node

## Mede, uma a uma, as partes que mais pesam num quadro cheio. Uso: godot --headless --path . res://tools/bench2.tscn


func _time(label: String, work: Callable, repeats := 200) -> void:
	var started := Time.get_ticks_usec()
	for i in repeats:
		work.call()
	print("MICRO %-28s %.3f ms" % [label, float(Time.get_ticks_usec() - started) / 1000.0 / repeats])


func _ready() -> void:
	Session.save_enabled = false
	Session.hero_id = "archer"
	Session.auto_attack = true
	Session.stage_index = 25
	var game: Node = (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in 5:
		await get_tree().process_frame
	game.player.max_health = 1.0e9
	game.player.health = 1.0e9
	game.spawning = false
	var kinds := ["bat", "skeleton", "wolf", "slime", "spider", "brute", "mushroom", "ghost"]
	for i in 58:
		var enemy: Enemy = game._spawn_one(kinds[i % kinds.size()], game.player.global_position + Vector2.from_angle(i * 0.9) * (170.0 + (i % 9) * 55.0))
		enemy.max_health = 1.0e9
		enemy.health = 1.0e9
	var enemies := get_tree().get_nodes_in_group("enemies")
	for i in 12:
		var shot := Projectile.new()
		shot.velocity = Vector2.from_angle(i) * 400.0
		shot.lifetime = 100.0
		shot.radius = 3.0
		game.world.add_child(shot)
	var shots: Array = []
	for node in game.world.get_children():
		if node is Projectile:
			shots.append(node)
	await get_tree().process_frame
	_time("separar inimigos", game._separate_enemies)
	_time("atualizar HUD", game._update_hud)
	_time("aviso mochila", game._update_bag_warning)
	_time("potes", func() -> void: game._tick_jars(0.016))
	_time("58 inimigos (fisica)", func() -> void:
		for enemy in enemies:
			enemy._physics_process(0.016))
	_time("12 projeteis (fisica)", func() -> void:
		for shot in shots:
			shot._physics_process(0.016))
	_time("jogador (fisica)", func() -> void: game.player._physics_process(0.016))
	_time("jogo _process", func() -> void: game._process(0.016))
	_time("arma _process", func() -> void: game.weapon._process(0.016))
	_time("achar alvos (arma)", func() -> void: game.weapon.find_targets(380.0))
	_time("get_nodes_in_group x1", func() -> void: get_tree().get_nodes_in_group("enemies"))
	_time("stat_points (x10)", func() -> void:
		for i in 10:
			game.player.stat_points("attack"))
	_time("get_move_speed", func() -> void: game.player.get_move_speed())
	_time("crit chance", func() -> void: game.player.get_crit_chance())
	_time("desenho de 58 inimigos", func() -> void:
		for enemy in enemies:
			enemy._draw()) if false else null
	get_tree().quit()
