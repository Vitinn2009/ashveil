extends SceneTree

## Teste de fumaça de toda a partida, para os três heróis. Rodar com:
##   godot --headless --path . --script res://tests/smoke_test.gd
## Sai com código 0 se tudo passar, 1 se alguma verificação falhar.

var _failures := 0
var _stages_done := 0
var _game: Node


func _initialize() -> void:
	_run()


func _run() -> void:
	await _test_screens()
	await _test_enemies()
	await _test_mission()
	for hero_id in ["mage", "archer", "warrior"]:
		await _test_hero(hero_id)
	# Um erro de script dentro de uma etapa a interrompe em silêncio.
	_check(_stages_done == 6, "todas as 6 etapas do teste terminaram")
	print("SMOKE TEST: %s" % ("PASSOU" if _failures == 0 else "FALHOU (%d)" % _failures))
	quit(1 if _failures > 0 else 0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   - %s" % description)
	else:
		print("  FALHA - %s" % description)
		_failures += 1


func _test_screens() -> void:
	print("[telas]")
	var menu: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(menu)
	await _frames(3)
	_check(menu.get_child_count() > 0, "tela inicial monta")
	menu.queue_free()
	var select: Node = load("res://scenes/CharacterSelect.tscn").instantiate()
	root.add_child(select)
	await _frames(3)
	_check(select._cards.size() == 3, "tela de seleção mostra 3 personagens")
	select.select_hero("archer")
	_check(select._selected == "archer", "clicar em um cartão seleciona o herói")
	select.start_game()
	_check(root.get_node("Session").hero_id == "archer", "Começar grava o herói escolhido")
	select.queue_free()
	await _frames(2)
	_stages_done += 1


func _make_enemy(kind: String, offset: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.target = _game.player
	enemy.setup(kind, 0.0)
	_game.world.add_child(enemy)
	enemy.global_position = _game.player.global_position + offset
	return enemy


func _count_nodes_of(script_class) -> int:
	var total := 0
	for node in _game.world.get_children():
		if is_instance_of(node, script_class):
			total += 1
	return total


func _test_enemies() -> void:
	print("[inimigos]")
	root.get_node("Session").hero_id = "warrior"
	_game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(_game)
	await _frames(3)
	var player: Player = _game.player

	_check(EnemyTypes.DATA.size() == 5, "catálogo com 5 tipos de inimigo")
	var traits := {}
	for kind in EnemyTypes.DATA:
		traits[EnemyTypes.DATA[kind]["trait"]] = true
	_check(traits.size() == 5, "cada tipo tem uma característica diferente")
	_check(EnemyTypes.pick(0.0) == "slime", "no início só aparecem gosmas")
	var seen := {}
	for i in 600:
		seen[EnemyTypes.pick(200.0)] = true
	_check(seen.size() == 5, "depois de 100s os 5 tipos aparecem")
	for kind in EnemyTypes.DATA:
		var enemy := _make_enemy(kind, Vector2(900, 0))
		var data := EnemyTypes.get_type(kind)
		_check(enemy.kind == kind and is_equal_approx(enemy.max_health, data["health"]) and enemy.radius == data["radius"], "setup aplica os atributos de %s" % kind)
		enemy.free()

	# Gosma: se divide em duas menores.
	var slime := _make_enemy("slime", Vector2(900, 0))
	var slime_radius := slime.radius
	slime.take_damage(99999.0)
	await _frames(2)
	var minis: Array = []
	for node in get_nodes_in_group("enemies"):
		if node.generation == 1:
			minis.append(node)
	_check(minis.size() == 2, "gosma se divide em duas ao morrer")
	_check(minis.size() == 2 and minis[0].radius < slime_radius and not minis[0].loot, "gosmas pequenas são menores e não soltam itens")
	for mini in minis:
		mini.take_damage(99999.0)
	await _frames(2)
	var generation_one := 0
	for node in get_nodes_in_group("enemies"):
		if node.generation == 1:
			generation_one += 1
	_check(generation_one == 0, "gosma pequena não se divide de novo")

	# Morcego: zigue-zague e velocidade alta.
	var bat := _make_enemy("bat", Vector2(900, 0))
	var start := bat.global_position
	var line := (player.global_position - start).normalized()
	var deviation := 0.0
	for i in 40:
		bat._physics_process(0.03)
		deviation = max(deviation, abs((bat.global_position - start).cross(line)))
	_check(deviation > 8.0, "morcego voa em zigue-zague")
	_check(bat.speed > EnemyTypes.DATA["slime"]["speed"] * 2.0, "morcego é bem mais rápido que a gosma")
	bat.free()

	# Esqueleto: mantém distância e atira.
	var near_skeleton := _make_enemy("skeleton", Vector2(150, 0))
	var near_before := near_skeleton.global_position.distance_to(player.global_position)
	for i in 20:
		near_skeleton._physics_process(0.05)
	_check(near_skeleton.global_position.distance_to(player.global_position) > near_before, "esqueleto recua quando o herói chega perto")
	var far_skeleton := _make_enemy("skeleton", Vector2(480, 0))
	var far_before := far_skeleton.global_position.distance_to(player.global_position)
	for i in 20:
		far_skeleton._physics_process(0.05)
	_check(far_skeleton.global_position.distance_to(player.global_position) < far_before, "esqueleto se aproxima quando está longe")
	var shots_before := _count_nodes_of(EnemyShot)
	near_skeleton._shot_timer = 0.0
	near_skeleton._physics_process(0.016)
	_check(_count_nodes_of(EnemyShot) == shots_before + 1, "esqueleto atira ossos")
	var shot := EnemyShot.new()
	shot.target = player
	shot.damage = 7.0
	_game.world.add_child(shot)
	shot.global_position = player.global_position
	var health_before_shot := player.health
	shot._physics_process(0.016)
	_check(player.health < health_before_shot, "osso fere o herói")
	near_skeleton.free()
	far_skeleton.free()

	# Bruto: ignora empurrão e reduz o dano.
	var brute := _make_enemy("brute", Vector2(900, 0))
	brute.knockback(Vector2(500, 0))
	_check(brute._push == Vector2.ZERO, "bruto ignora empurrão")
	var pushed := _make_enemy("slime", Vector2(900, 100))
	pushed.knockback(Vector2(500, 0))
	_check(pushed._push != Vector2.ZERO, "gosma é empurrada")
	var brute_health := brute.health
	brute.take_damage(100.0)
	_check(is_equal_approx(brute_health - brute.health, 75.0), "bruto reduz o dano em 25%")
	_check(brute.radius > 2.0 * pushed.radius * 0.75, "bruto é enorme")
	brute.free()
	pushed.free()

	# Bomba-viva: acende o pavio e explode em área.
	var bomber := _make_enemy("bomber", Vector2(60, 0))
	var kills_before: int = _game.kills
	var health_before_bomb := player.health
	bomber._physics_process(0.016)
	_check(bomber._fuse > 0.0, "bomba-viva acende o pavio perto do herói")
	bomber._physics_process(1.0)
	_check(player.health < health_before_bomb, "explosão fere o herói dentro da área")
	_check(bomber.is_queued_for_deletion() and _game.kills == kills_before, "explosão não conta como abate")
	var distant_bomber := _make_enemy("bomber", Vector2(300, 0))
	var health_before_far := player.health
	distant_bomber._explode()
	_check(is_equal_approx(player.health, health_before_far), "explosão longe não fere o herói")

	# O spawner usa o catálogo.
	_game.elapsed = 200.0
	for i in 60:
		_game._spawn_enemy()
	var kinds := {}
	for node in get_nodes_in_group("enemies"):
		kinds[node.kind] = true
	_check(kinds.size() >= 4, "spawner sorteia vários tipos de inimigo")

	_game.queue_free()
	paused = false
	await _frames(2)
	_stages_done += 1


## Missão: barra de progresso, fim do spawn e vitória quando não restar inimigo.
func _test_mission() -> void:
	print("[missão]")
	root.get_node("Session").hero_id = "warrior"
	_game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(_game)
	await _frames(3)
	var duration: float = _game.MISSION_DURATION
	_check(_game.spawning and _game.mission_progress() < 0.01, "missão começa com inimigos surgindo e progresso zero")
	_game.elapsed = duration * 0.5
	_game._update_hud()
	_check(is_equal_approx(_game.mission_progress(), 0.5) and is_equal_approx(_game.mission_bar.value, 0.5), "barra da missão acompanha o progresso")
	_check(_game.mission_status.text.begins_with("Inimigos surgindo"), "barra avisa que ainda surgem inimigos")

	_game.elapsed = duration - 0.1
	_game._process(0.5)
	_check(not _game.spawning, "o spawn para quando a missão chega ao fim")
	_check(is_equal_approx(_game.mission_progress(), 1.0), "progresso chega a 100%")
	_spawn_enemy(Vector2(900, 0), 100.0)
	var before: int = _game.enemies_left()
	_game.spawn_cooldown = 0.0
	for i in 20:
		_game._process(0.5)
	_check(_game.enemies_left() == before, "nenhum inimigo novo surge depois do fim do spawn")
	_check(not _game.mission_complete, "a missão não termina enquanto restam inimigos")
	_check(_game.mission_status.text.begins_with("Todos surgiram"), "barra mostra quantos inimigos restam")

	for node in get_nodes_in_group("enemies"):
		node.free()
	var gold_before: int = _game.player.inventory.gold
	_game._process(0.3)
	_check(not _game.mission_complete, "espera um instante antes de dar a missão por cumprida")
	_game._process(0.4)
	_check(_game.mission_complete and _game.victory_panel.visible and paused, "missão cumprida quando o último inimigo morre")
	_check(_game.player.inventory.gold == gold_before + _game.MISSION_REWARD, "missão cumprida dá bônus de ouro")
	_game.queue_free()
	paused = false
	await _frames(2)
	_stages_done += 1


func _spawn_enemy(offset: Vector2, health := 30.0) -> Enemy:
	var enemy := Enemy.new()
	enemy.max_health = health
	enemy.target = _game.player
	enemy.speed = 0.0
	_game.world.add_child(enemy)
	enemy.global_position = _game.player.global_position + offset
	return enemy


func _test_hero(hero_id: String) -> void:
	print("[%s]" % hero_id)
	root.get_node("Session").hero_id = hero_id
	_game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(_game)
	await _frames(3)
	var player: Player = _game.player
	var hero := Heroes.get_hero(hero_id)

	_check(player.hero_id == hero_id, "herói da sessão chegou na partida")
	_check(is_equal_approx(player.max_health, hero["health"]), "vida inicial do herói")
	_check(_game.skill_buttons.size() == hero["skills"].size(), "barra de habilidades com %d botões" % hero["skills"].size())
	_check(_game.inventory_panel.visible, "inventário visível na direita")

	_test_hud_bars()
	_test_combat(hero)
	await _test_skills(hero_id)
	_test_skill_attributes(hero_id)
	await _test_inventory_and_stats()
	await _test_levels()

	player.take_damage(99999.0)
	_check(_game.game_over, "fim de jogo ao zerar a vida")
	_game.queue_free()
	paused = false
	await _frames(2)
	_stages_done += 1


func _test_combat(hero: Dictionary) -> void:
	var enemy := _spawn_enemy(Vector2(60, 0))
	_game.weapon._cooldown = 0.0
	_game.weapon._process(0.0)
	if hero["attack"] != "melee":
		for projectile in _game.world.get_children():
			if projectile is Projectile:
				for i in 6:
					projectile._physics_process(0.05)
	_check(enemy.health < enemy.max_health or enemy.is_queued_for_deletion(), "ataque automático acerta o inimigo")
	enemy.free()

	if hero["attack"] == "melee":
		var player: Player = _game.player
		player.facing = Vector2.RIGHT
		var near := _spawn_enemy(Vector2(10, 0), 1000.0)
		var far := _spawn_enemy(Vector2(85, 0), 1000.0)
		_game.weapon._cooldown = 0.0
		_game.weapon._process(0.0)
		_check(near.max_health - near.health > far.max_health - far.health, "guerreiro causa mais dano quanto mais perto")
		near.free()
		far.free()

		# O golpe é em leque: só atinge o que está à frente, na direção do movimento.
		var front := _spawn_enemy(Vector2(70, 0), 1000.0)
		var behind := _spawn_enemy(Vector2(-70, 0), 1000.0)
		var side := _spawn_enemy(Vector2(0, 70), 1000.0)
		_game.weapon._cooldown = 0.0
		_game.weapon._process(0.0)
		_check(front.health < front.max_health, "golpe atinge o inimigo à frente")
		_check(behind.health == behind.max_health, "golpe não atinge o inimigo atrás")
		_check(side.health == side.max_health, "golpe não atinge o inimigo ao lado")
		player.facing = Vector2.LEFT
		_game.weapon._cooldown = 0.0
		_game.weapon._process(0.0)
		_check(behind.health < behind.max_health, "ao virar, o golpe passa a atingir o novo lado")
		_check(_count_nodes_of(SlashEffect) > 0, "golpe mostra o efeito de corte em leque")
		player.facing = Vector2.RIGHT
		# Sem inimigo à frente, o herói não golpeia.
		_game.weapon._cooldown = 0.0
		var health_snapshot := behind.health
		front.free()
		behind.global_position = player.global_position + Vector2(-70, 0)
		_game.weapon._process(0.0)
		_check(behind.health == health_snapshot, "não golpeia quando só há inimigo atrás")
		behind.free()
		side.free()


func _test_skills(hero_id: String) -> void:
	var player: Player = _game.player
	player.facing = Vector2.RIGHT
	var mage_target: Enemy = _spawn_enemy(Vector2(50, 0), 1000.0) if hero_id == "mage" else null
	for id in Heroes.get_hero(hero_id)["skills"]:
		_check(_game.try_cast(id), "habilidade %s dispara" % id)
		_check(not _game.try_cast(id), "habilidade %s entra em recarga" % id)
		_check(_game.skill_buttons[id].cooldown_total > 0.0, "botão %s existe" % id)
	match hero_id:
		"mage":
			var enemy := mage_target
			for node in _game.world.get_children():
				if node is SkillZone:
					node._physics_process(0.016)
				elif node is Projectile and node.burn_ticks == 3:
					node.global_position = enemy.global_position
					node._physics_process(0.016)
			_check(enemy._slow_time > 0.0, "gelo deixa o inimigo mais lento")
			_check(enemy._burn_ticks == 3, "fogo aplica queimadura de 3 ticks")
			var health_before := enemy.health
			enemy._burn_timer = 0.0
			enemy._physics_process(0.016)
			_check(enemy.health < health_before and enemy._burn_ticks == 2, "queimadura causa dano a cada tick")
			_check(enemy._push != Vector2.ZERO, "vento empurra o inimigo")
			enemy.free()
		"archer":
			_check(player.double_time > 0.0, "flecha dupla ativa")
			var base_speed: float = player.hero["speed"]
			_check(player.get_move_speed() > base_speed * 1.4, "velocidade aumenta o movimento")
			_game.weapon._cooldown = 0.0
			var enemy := _spawn_enemy(Vector2(80, 0), 1000.0)
			var before := _count_projectiles()
			_game.weapon._process(0.0)
			_check(_count_projectiles() - before == 2, "flecha dupla dispara 2 flechas")
			enemy.free()
		"warrior":
			_check(player.shield_hp > 0.0, "escudo ativo")
			var health_before := player.health
			player.take_damage(10.0)
			_check(is_equal_approx(player.health, health_before), "escudo absorve o dano")
			await _test_double_slash()


func _waves() -> Array:
	var waves: Array = []
	for node in _game.world.get_children():
		if node is Projectile and node.style == "slash":
			waves.append(node)
	return waves


## Corte Duplo: duas ondas de espada à frente, cada uma com o dobro do dano.
func _test_double_slash() -> void:
	var player: Player = _game.player
	_check(Heroes.get_hero("warrior")["skills"].has("slash"), "guerreiro tem a habilidade Corte Duplo")
	var waves := _waves()
	_check(waves.size() == 1, "primeiro corte sai na hora")
	var expected: float = _game.weapon.damage * 2.0 * player.get_damage_mult() * player.skill_power_mult()
	_check(waves.size() == 1 and is_equal_approx(waves[0].damage, expected), "corte causa dano x2")
	_check(waves.size() == 1 and waves[0].velocity.normalized().is_equal_approx(Vector2.RIGHT), "corte vai na direção em que o herói anda")
	await create_timer(Skills.SLASH_GAP + 0.15).timeout
	_check(_waves().size() == 2, "segundo corte sai logo depois")
	# Uma onda atravessa vários inimigos em linha.
	for wave in _waves():
		wave.free()
	var first := _spawn_enemy(Vector2(70, 0), 1000.0)
	var second := _spawn_enemy(Vector2(110, 0), 1000.0)
	Skills.cast("slash", _game)
	var wave: Projectile = _waves()[0]
	for i in 8:
		wave._physics_process(0.03)
	_check(first.health < first.max_health and second.health < second.max_health, "corte atravessa inimigos em linha")
	_check(first.max_health - first.health >= expected - 0.01, "inimigo recebe o dano dobrado do corte")
	first.free()
	second.free()
	for node in _waves():
		node.free()


func _count_projectiles() -> int:
	var total := 0
	for node in _game.world.get_children():
		if node is Projectile:
			total += 1
	return total


func _test_hud_bars() -> void:
	var hp_bar: ProgressBar = _game.hp_bar
	var xp_bar: ProgressBar = _game.xp_bar
	_check(hp_bar.modulate == Color.WHITE and xp_bar.modulate == Color.WHITE, "barras do HUD não tingem o texto")
	_check(hp_bar.get_theme_stylebox("fill") is StyleBoxFlat and hp_bar.get_theme_stylebox("background") is StyleBoxFlat, "barras do HUD têm fundo e preenchimento próprios")
	var expected_text := "%d / %d" % [int(ceil(_game.player.health)), int(_game.player.max_health)]
	_check(_game.hp_text.text == expected_text and _game.hp_text.modulate == Color.WHITE, "barra de vida mostra vida atual e máxima, legível")
	_check(_game.mission_bar.max_value == 1.0, "barra da missão existe")


## Atributos de habilidade: alcance, x2, recarga e poder, com limite por atributo.
func _test_skill_attributes(hero_id: String) -> void:
	var player: Player = _game.player
	_check(is_equal_approx(player.skill_cooldown_mult(), 1.0) and is_equal_approx(player.skill_power_mult(), 1.0)
		and is_equal_approx(player.skill_range_mult(), 1.0) and player.skill_echo_chance() == 0.0, "atributos de habilidade começam zerados")
	var first_skill: String = Heroes.get_hero(hero_id)["skills"][0]
	var cooldown_before := Skills.cooldown_for(first_skill, _game)
	_check(player.add_point("skill", "cooldown"), "ponto de Recarga é aceito")
	_check(Skills.cooldown_for(first_skill, _game) < cooldown_before, "Recarga reduz o tempo de recarga")
	for stat in ["power", "range", "echo"]:
		player.add_point("skill", stat)
	_check(player.skill_power_mult() > 1.0 and player.skill_range_mult() > 1.0 and player.skill_echo_chance() > 0.0, "Poder, Alcance e x2 aumentam")
	for i in 10:
		player.add_point("skill", "power")
	_check(player.get_points("skill", "power") == Player.MAX_SKILL_POINTS, "atributo de habilidade para no limite")
	_check(not player.can_add_point("skill", "power") and not player.add_point("skill", "power"), "não aceita ponto além do limite")

	match hero_id:
		"mage":
			Skills.cast("freeze", _game)
			var zone: SkillZone
			for node in _game.world.get_children():
				if node is SkillZone:
					zone = node
			_check(is_equal_approx(zone.radius, 170.0 * player.skill_range_mult()), "Alcance aumenta a área do Gelo")
			_check(is_equal_approx(zone.duration, 5.0 * player.skill_power_mult()), "Poder aumenta a duração do Gelo")
			_check(zone.slow_factor < 0.4, "Poder deixa o Gelo mais forte")
		"archer":
			player.double_time = 0.0
			Skills.cast("double", _game, false)
			var single := player.double_time
			Skills.cast("double", _game, true)
			_check(is_equal_approx(single, 6.0 * player.skill_power_mult()), "Poder aumenta a duração da Flecha Dupla")
			_check(player.double_time > single * 1.9, "x2 repete a habilidade e soma a duração")
		"warrior":
			Skills.cast("slash", _game)
			var wave: Projectile = _waves().back()
			_check(wave.damage > _game.weapon.damage * 2.0 * player.get_damage_mult(), "Poder aumenta o dano do Corte Duplo")
			_check(wave.lifetime > 270.0 / 520.0, "Alcance aumenta a distância do Corte Duplo")
			for node in _waves():
				node.free()
	for stat in player.skill_attributes:
		player.skill_attributes[stat] = 0


func _test_inventory_and_stats() -> void:
	var player: Player = _game.player
	var inventory := player.inventory
	var item := Item.new()
	item.item_name = "Espada de Teste"
	item.slot = "weapon"
	item.rarity = 2
	item.stats = {"attack": 5, "luck": 2}
	_check(inventory.add_item(item), "item entra na mochila")
	var damage_before := player.get_damage_mult()
	inventory.equip(item)
	_check(inventory.equipped["weapon"] == item and inventory.bag.is_empty(), "equipar move o item da mochila")
	_check(player.get_damage_mult() > damage_before, "equipamento aumenta o ataque")
	_check(player.get_luck() >= 2, "equipamento aumenta a sorte")
	inventory.unequip("weapon")
	_check(inventory.bag.has(item), "desequipar devolve o item à mochila")
	inventory.add_gold(25)
	_check(inventory.gold >= 25, "ouro entra no inventário")
	player.health = player.max_health - 20.0
	var health_before := player.health
	inventory.potions = 1
	_check(inventory.use_potion(player) and player.health > health_before, "poção cura o herói")
	for i in Inventory.BAG_SIZE:
		inventory.add_item(Item.roll(0, 1))
	var gold_before := inventory.gold
	_check(not inventory.add_item(Item.roll(0, 1)) and inventory.gold > gold_before, "mochila cheia vende o item")
	await _frames(2)

	var max_before := player.max_health
	player.add_attribute("hp")
	_check(player.max_health > max_before, "ponto de HP aumenta a vida máxima")
	var defense_before := player.get_defense()
	player.add_attribute("defense")
	_check(player.get_defense() > defense_before, "ponto de Defesa aumenta a defesa")
	var luck_before := player.get_xp_mult()
	player.add_attribute("luck")
	_check(player.get_xp_mult() > luck_before, "Sorte aumenta o XP ganho")
	var speed_before := player.get_move_speed()
	player.add_attribute("speed")
	_check(player.get_move_speed() > speed_before, "Rapidez aumenta o movimento")

	# Limites: por atributo (10 pontos) e no total com equipamentos (20).
	for i in 20:
		player.add_attribute("defense")
	_check(player.attributes["defense"] == Player.MAX_ATTRIBUTE_POINTS, "atributo para no limite de pontos")
	_check(not player.add_attribute("defense"), "ponto além do limite é recusado")
	inventory.bag.clear()
	var ring := Item.new()
	ring.item_name = "Anel Absurdo"
	ring.slot = "ring"
	ring.stats = {"defense": 15}
	inventory.add_item(ring)
	inventory.equip(ring)
	_check(player.stat_points("defense") == Player.MAX_TOTAL_POINTS, "atributo mais equipamento respeita o limite total")
	inventory.unequip("ring")
	player.attributes["defense"] = 0


func _test_levels() -> void:
	_game.level = 4
	_game.xp = 0.0
	_game.xp_to_next = 1.0
	_game.pending_level_ups = 0
	_game.pending_stat_popups = 0
	root.get_node("EventBus").pickup_collected.emit("xp", 5)
	_check(paused and _game.level_panel.visible, "level-up abre as cartas de melhoria")
	_check(_game.level == 5, "nível 5 alcançado")
	var options := 0
	for button in _game.cards_box.get_children():
		if button is Button:
			options += 1
	_check(options == 3, "três cartas de melhoria")
	if _game.weapon.kind == "melee":
		var offered_ranged := false
		for button in _game.cards_box.get_children():
			if button is Button and (button.text.begins_with("Tiro múltiplo") or button.text.begins_with("Mira longa")):
				offered_ranged = true
		_check(not offered_ranged, "guerreiro não recebe cartas de projétil")
	_game._choose_upgrade(_game.upgrades[0])
	_check(_game.stat_popup.visible, "no nível 5 abre o popup de atributos")
	_check(_game.stat_popup.group == "hero" and _game.stat_popup.points_left == 3, "popup dá 3 pontos de atributo do herói")
	await _frames(3)
	var panel: Control = _game.stat_popup.get_child(1).get_child(0)
	var popup_center: Vector2 = _game.stat_popup.get_global_rect().get_center()
	_check(panel.size.x > 300.0 and panel.get_global_rect().get_center().distance_to(popup_center) < 4.0, "popup de atributos fica centralizado")
	_game.stat_popup.confirm()
	_check(_game.stat_popup.visible, "não fecha enquanto sobram pontos")
	for stat in ["attack", "attack", "luck"]:
		_game.stat_popup.add_point(stat)
	_check(_game.player.attributes["attack"] == 2, "pontos de ataque aplicados")
	_game.stat_popup.confirm()
	_check(not _game.stat_popup.visible and not paused, "confirmar fecha o popup e retoma o jogo")
	_check(_game.pending_skill_popups == 0, "nível 5 não abre atributos de habilidade")

	# Com todos os atributos no limite, o popup deixa fechar mesmo sobrando pontos.
	for stat in _game.player.attributes:
		_game.player.attributes[stat] = Player.MAX_ATTRIBUTE_POINTS
	_game.stat_popup.open(_game.player, 3, 5, "hero")
	_check(_game.stat_popup._add_buttons["hp"].disabled, "botão + fica desativado no limite")
	_game.stat_popup.confirm()
	_check(not _game.stat_popup.visible, "pontos que não cabem em nenhum atributo são perdidos")
	for stat in _game.player.attributes:
		_game.player.attributes[stat] = 0
	paused = false
	_game.modal_open = false

	# Cada carta de melhoria tem limite de repetições.
	_game.card_counts["Lâmina afiada"] = _game.CARD_MAX_STACK
	var offered_capped := false
	for i in 14:
		_game.modal_open = false
		_game.pending_level_ups = 1
		_game._open_level_up()
		await _frames(2)
		for button in _game.cards_box.get_children():
			if button is Button and button.text.begins_with("Lâmina afiada"):
				offered_capped = true
	_check(not offered_capped, "carta no limite de repetições não é mais oferecida")
	_game.card_counts.clear()
	_game.level_panel.hide()
	_game.modal_open = false
	paused = false

	# A cada 10 níveis: atributos do herói e, depois, os das habilidades.
	_game.level = 9
	_game.xp = 0.0
	_game.xp_to_next = 1.0
	_game.pending_level_ups = 0
	_game.pending_stat_popups = 0
	_game.pending_skill_popups = 0
	root.get_node("EventBus").pickup_collected.emit("xp", 5)
	_check(_game.level == 10, "nível 10 alcançado")
	_game._choose_upgrade(_game.upgrades[0])
	_check(_game.stat_popup.visible and _game.stat_popup.group == "hero", "nível 10 abre primeiro os atributos do herói")
	for stat in ["hp", "attack", "speed"]:
		_game.stat_popup.add_point(stat)
	_game.stat_popup.confirm()
	_check(_game.stat_popup.visible and _game.stat_popup.group == "skill", "em seguida abre os atributos das habilidades")
	_check(_game.stat_popup.points_left == 4, "popup das habilidades dá 4 pontos")
	var skill_ids: Array = []
	for stat in _game.stat_popup.stats():
		skill_ids.append(stat["id"])
	_check(skill_ids == ["range", "echo", "cooldown", "power"], "atributos das habilidades: alcance, x2, recarga e poder")
	for stat in skill_ids:
		_game.stat_popup.add_point(stat)
	var all_one := true
	for stat in skill_ids:
		all_one = all_one and _game.player.skill_attributes[stat] == 1
	_check(all_one, "pontos de habilidade aplicados")
	_game.stat_popup.confirm()
	_check(not _game.stat_popup.visible and not paused, "confirmar fecha o popup das habilidades")
	for stat in _game.player.skill_attributes:
		_game.player.skill_attributes[stat] = 0
