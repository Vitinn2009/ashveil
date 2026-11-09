extends Node

## Simulação de balanceamento: o herói fica parado (cenário pessimista, sem desviar) e o jogo roda
## acelerado até o fim da fase. Mostra abates, nível, vida e o pico de inimigos vivos.
## Uso: godot --headless --path . res://tools/sim_balance.tscn -- <fase 1-5> <herói> [aceleração]

var _game: Node


func _ready() -> void:
	Session.save_enabled = false
	var args := OS.get_cmdline_user_args()
	var stage := int(args[0]) - 1 if args.size() > 0 else 0
	var hero := args[1] if args.size() > 1 else "warrior"
	var speed := float(args[2]) if args.size() > 2 else 8.0
	_run.call_deferred(stage, hero, speed)


func _run(stage: int, hero: String, speed: float) -> void:
	Session.reset_progress()
	Session.hero_id = hero
	Session.stage_index = stage
	_game = load("res://scenes/Game.tscn").instantiate()
	add_child(_game)
	await get_tree().process_frame
	_equip(stage)
	Engine.time_scale = speed
	var peak := 0
	var low_hp := 1.0
	var guard := 0
	while not _game.game_over and _game.elapsed < _game.mission_duration + 150.0:
		await get_tree().physics_frame
		guard += 1
		peak = maxi(peak, _game.enemies_left())
		low_hp = minf(low_hp, _game.player.health / maxf(_game.player.max_health, 1.0))
		_game.joystick.output = _steer(hero)
		_game.attack_button.held = true
		if OS.get_environment("SIM_DEBUG") != "" and guard % 60 == 0:
			var kinds := {}
			for node in get_tree().get_nodes_in_group("enemies"):
				kinds[(node as Enemy).kind] = int(kinds.get((node as Enemy).kind, 0)) + 1
			print("t=%d hp=%d %s" % [int(_game.elapsed), int(_game.player.health), kinds])
		if _game.enemies_left() > 5:
			for id in _game.cooldowns.keys():
				_game.try_cast(id)
		# Poções e comida: o herói usa uma quando a vida cai abaixo de 40%.
		if _game.player.health < _game.player.max_health * 0.4:
			_game._use_consumable("potion")
		if _game.choice_strip.is_open():
			_game.choice_strip.pick(_game.choice_strip.recommended_index())
	Engine.time_scale = 1.0
	var result := "VENCEU" if _game.mission_complete else ("MORREU" if _game.player.health <= 0.0 else "TEMPO ESGOTADO")
	print("%s | fase %d %s | herói %s | %s aos %ds | abates %d (meta %d) | nível %d | pico %d inimigos | vida mínima %d%% | estrelas %d" % [
		"SIM", stage + 1, _game.mission_name, hero, result, int(_game.elapsed), _game.kills,
		_game.stage["kill_goal"], _game.level, peak, int(low_hp * 100.0), _game.stars])
	get_tree().quit()


## Piloto simples: heróis de longe fogem dos monstros próximos; o guerreiro encara os monstros
## enquanto a vida está boa e foge quando baixa; sem perigo por perto, vai buscar os drops.
func _steer(hero: String) -> Vector2:
	var player: Player = _game.player
	var here := player.global_position
	var flee := Vector2.ZERO
	var nearest: Node2D = null
	var nearest_distance := 99999.0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		var offset := here - enemy.global_position
		var distance := maxf(offset.length(), 1.0)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
		if distance < 230.0:
			flee += offset / (distance * distance) * 230.0
	var best: Node2D = null
	var best_distance := 340.0
	for child in _game.world.get_children():
		if child is Pickup:
			var distance := here.distance_to(child.global_position)
			if distance < best_distance:
				best_distance = distance
				best = child
	if best != null and nearest_distance > 110.0:
		return (best.global_position - here).normalized()
	var healthy: bool = player.health > player.max_health * 0.5
	if hero == "warrior" and healthy and nearest != null and nearest_distance < 360.0:
		return (nearest.global_position - here).normalized()
	if flee != Vector2.ZERO:
		return flee.normalized()
	return Vector2.ZERO


## Equipamento de quem chega nesta fase depois de vencer as anteriores: itens raros de nível
## crescente nas 9 casas (a fase 1 começa sem nada).
func _equip(stage: int) -> void:
	if stage == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for slot in Item.SLOTS:
		var item := Item.create(rng, slot, 0, stage * 7 + 1, 2, 1)
		_game.player.inventory.bag.append(item)
		_game.player.inventory.equip(item)
