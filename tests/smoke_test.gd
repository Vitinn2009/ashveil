extends SceneTree

## Teste de fumaça de toda a partida, para os três heróis. Rodar com:
##   godot --headless --path . --script res://tests/smoke_test.gd
## Sai com código 0 se tudo passar, 1 se alguma verificação falhar.

var _failures := 0
var _game: Node


func _initialize() -> void:
	_run()


func _run() -> void:
	await _test_screens()
	for hero_id in ["mage", "archer", "warrior"]:
		await _test_hero(hero_id)
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

	_test_combat(hero)
	_test_skills(hero_id)
	await _test_inventory_and_stats()
	await _test_levels()

	player.take_damage(99999.0)
	_check(_game.game_over, "fim de jogo ao zerar a vida")
	_game.queue_free()
	paused = false
	await _frames(2)


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
		var near := _spawn_enemy(Vector2(10, 0), 1000.0)
		var far := _spawn_enemy(Vector2(0, 90), 1000.0)
		_game.weapon._cooldown = 0.0
		_game.weapon._process(0.0)
		_check(near.max_health - near.health > far.max_health - far.health, "guerreiro causa mais dano quanto mais perto")
		near.free()
		far.free()


func _test_skills(hero_id: String) -> void:
	var player: Player = _game.player
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


func _count_projectiles() -> int:
	var total := 0
	for node in _game.world.get_children():
		if node is Projectile:
			total += 1
	return total


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
	_check(_game.stat_popup.points_left == 3, "popup dá 3 pontos")
	_game.stat_popup.confirm()
	_check(_game.stat_popup.visible, "não fecha enquanto sobram pontos")
	for stat in ["attack", "attack", "luck"]:
		_game.stat_popup.add_point(stat)
	_check(_game.player.attributes["attack"] == 2, "pontos de ataque aplicados")
	_game.stat_popup.confirm()
	_check(not _game.stat_popup.visible and not paused, "confirmar fecha o popup e retoma o jogo")
