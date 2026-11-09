extends SceneTree

## Teste de fumaça do jogo todo. Rodar com:
##   godot --headless --path . --script res://tests/smoke_test.gd
## Sai com código 0 se tudo passar, 1 se alguma verificação falhar.

const STAGES := 10

var _failures := 0
var _stages_done := 0
var _game: Node
var _castle: Control


func _initialize() -> void:
	_run()


func _run() -> void:
	var session = root.get_node("Session")
	session.save_enabled = false
	await _test_screens()
	await _test_data()
	await _test_castle()
	await _test_enemies()
	await _test_scenery()
	await _test_mission()
	for hero_id in Heroes.ids():
		await _test_hero(hero_id)
	# Um erro de script dentro de uma etapa a interrompe em silêncio.
	_check(_stages_done == STAGES, "todas as %d etapas do teste terminaram" % STAGES)
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


func _new_game(hero_id: String) -> void:
	var session = root.get_node("Session")
	session.save_enabled = false
	session.reset_progress()
	session.hero_id = hero_id
	# Fase 4: todas as habilidades comuns já liberadas (a 1ª fase não tem nenhuma).
	session.stage_index = 3
	_game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(_game)
	_game.weapon.auto_enabled = true
	_game.player.accuracy_bonus = 1.0
	await _frames(3)


func _end_game() -> void:
	_game.queue_free()
	paused = false
	await _frames(2)


# --- Telas ------------------------------------------------------------------

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
	_check(select._cards.size() == 4, "tela de seleção mostra 4 personagens")
	_check(select._cards.has("gnome"), "o Gnomo está entre os personagens")
	select.select_hero("gnome")
	_check(select._selected == "gnome", "clicar em um cartão seleciona o herói")
	select.start_game()
	_check(root.get_node("Session").hero_id == "gnome", "Ir ao castelo grava o herói escolhido")
	await _frames(3)
	if current_scene:
		current_scene.queue_free()
	select.queue_free()
	await _frames(2)
	_stages_done += 1


# --- Dados: consumíveis, inventário, save e loja -----------------------------

func _test_data() -> void:
	print("[dados]")
	var session = root.get_node("Session")
	session.reset_progress()
	var inv: Inventory = session.inventory
	_check(inv.gold == 60 and inv.potions == 2 and inv.count("bread") == 1, "inventário inicial: 60 de ouro, 2 poções e 1 pão")

	# Heróis
	_check(Heroes.ids().size() == 4, "o jogo tem 4 heróis")
	var gnome := Heroes.get_hero("gnome")
	var all_slower := true
	for id in ["mage", "archer", "warrior"]:
		all_slower = all_slower and gnome["speed"] < Heroes.get_hero(id)["speed"]
	_check(all_slower, "o Gnomo é o mais lento")
	_check(gnome["base_luck"] > 0 and gnome["bag_bonus"] > 0 and gnome["attack"] == "blunderbuss", "o Gnomo tem mais sorte, mochila maior e bacamarte")
	for id in Heroes.ids():
		var hero := Heroes.get_hero(id)
		_check(hero["unlock"]["level"] == 20 and Skills.DEFS.has(hero["unlock"]["id"]), "%s tem uma habilidade que destrava no nível 20" % id)
		_check(Heroes.skill_entries(hero).back()["unlock_level"] == 20, "%s: a última habilidade da lista é a travada" % id)

	# Compras de consumíveis
	_check(Shop.buy_consumable(inv, "potion") == "" and inv.gold == 60 - Consumables.def("potion")["price"] and inv.potions == 3, "comprar poção gasta o preço em ouro")
	inv.gold = 5
	_check(Shop.buy_consumable(inv, "roast") == "Ouro insuficiente" and inv.count("roast") == 0, "sem ouro, a compra é recusada")
	inv.gold = 500

	# Comidas e poção em um herói
	var player := Player.new()
	player.hero_id = "warrior"
	player.inventory = inv
	root.add_child(player)
	await _frames(2)
	player.health = 40.0
	_check(inv.use_consumable("bread", player) and is_equal_approx(player.health, 40.0 + player.max_health * 0.25), "pão cura 25% da vida")
	_check(inv.count("bread") == 0 and not inv.foods.has("bread"), "o pão gasto some do inventário")
	player.health = player.max_health
	inv.add_consumable("roast")
	_check(not inv.use_consumable("roast", player) and inv.count("roast") == 1, "comida de cura não é gasta com a vida cheia")
	player.health = 10.0
	_check(inv.use_consumable("roast", player) and player.health >= 10.0 + player.max_health * 0.6 - 0.01, "carne assada cura 60% da vida")
	var speed_before := player.get_attack_speed_mult()
	inv.add_consumable("stew", 2)
	_check(inv.use_consumable("stew", player) and player.attack_buff_time > 29.0, "sopa de cogumelo dá bônus por 30s")
	_check(player.get_attack_speed_mult() > speed_before * 1.2, "a sopa aumenta a velocidade de ataque")
	_check(not inv.use_consumable("stew", player) and inv.count("stew") == 1, "a sopa não é gasta com o bônus ativo")
	_check(not inv.use_consumable("ghost_pepper", player), "consumível inexistente é ignorado")
	player.free()

	# Itens: salvar e carregar
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sword := Item.create(rng, "weapon", 0, 10)
	var copy := Item.from_dict(sword.to_dict())
	_check(copy.item_name == sword.item_name and copy.slot == sword.slot and copy.rarity == sword.rarity and copy.stats == sword.stats, "item sobrevive ao salvar e carregar")
	_check(sword.buy_price() == sword.base_value() * 8, "o item custa 8x o valor de referência")

	var full := Inventory.new()
	full.gold = 777
	full.potions = 4
	full.foods = {"roast": 2}
	full.add_item(Item.create(rng, "armor", 0, 5))
	full.add_item(Item.create(rng, "ring", 0, 5))
	var worn := Item.create(rng, "boots", 0, 5)
	full.add_item(worn)
	full.equip(worn)
	var loaded := Inventory.from_dict(full.to_dict())
	_check(loaded.gold == 777 and loaded.potions == 4 and loaded.count("roast") == 2, "ouro, poções e comidas sobrevivem ao salvar")
	_check(loaded.bag.size() == full.bag.size() and loaded.equipped.has("boots") and loaded.equipped["boots"].item_name == worn.item_name, "mochila e equipamentos sobrevivem ao salvar")
	var corrupt := Inventory.from_dict({
		"gold": -50, "foods": {"unicorn": 3, "bread": 2, "stew": 0},
		"bag": [1, "x", {"slot": "alien", "rarity": 99, "stats": {"hp": 500, "foo": 3}}],
		"equipped": {"alien": {"name": "x"}, "weapon": 5}})
	_check(corrupt.gold == 0 and corrupt.foods == {"bread": 2}, "save corrompido: ouro e comidas inválidos são descartados")
	_check(corrupt.bag.size() == 1 and corrupt.bag[0].slot == "weapon" and corrupt.bag[0].rarity == 3 and corrupt.bag[0].stats == {"hp": 99}, "save corrompido: item inválido vira um item seguro")
	_check(corrupt.equipped.is_empty(), "save corrompido: equipamento inválido é descartado")

	# Arquivo de save
	session.save_enabled = true
	session.save_path = "user://smoke_test_save.json"
	session.reset_progress()
	session.inventory.gold = 321
	session.inventory.add_consumable("stew")
	session.missions_done = 3
	session.hero_id = "gnome"
	_check(session.save_game(), "o jogo grava o save no disco")
	session.reset_progress()
	session.hero_id = "warrior"
	_check(session.load_game(), "o jogo lê o save do disco")
	_check(session.inventory.gold == 321 and session.inventory.count("stew") == 1 and session.missions_done == 3 and session.hero_id == "gnome", "ouro, comida, missões e herói voltam do save")
	var bad := FileAccess.open(session.save_path, FileAccess.WRITE)
	bad.store_string("isto não é json")
	bad = null
	_check(not session.load_game(), "save ilegível é ignorado sem travar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.save_path))
	session.save_enabled = false
	session.save_path = "user://ashveil_save.json"
	session.reset_progress()

	# Mercado
	var stock_a := Shop.generate_stock(42, 0)
	var stock_b := Shop.generate_stock(42, 0)
	var same := true
	for group in ["weapons", "armor", "accessories"]:
		for i in stock_a[group].size():
			same = same and stock_a[group][i]["item"].item_name == stock_b[group][i]["item"].item_name
	_check(same and stock_a["weapons"].size() == Shop.STOCK_SIZE, "o mesmo seed gera o mesmo estoque")
	var no_legendary := true
	var weak_total := 0
	var strong_total := 0
	for shop_seed in 40:
		var weak := Shop.generate_stock(shop_seed, 0)
		var strong := Shop.generate_stock(shop_seed, 10)
		for group in ["weapons", "armor", "accessories"]:
			for entry in weak[group]:
				no_legendary = no_legendary and entry["item"].rarity <= Shop.MAX_SHOP_RARITY
				weak_total += entry["item"].stats.values().reduce(func(a, b): return a + b, 0)
			for entry in strong[group]:
				strong_total += entry["item"].stats.values().reduce(func(a, b): return a + b, 0)
	_check(no_legendary, "o mercado não vende itens lendários")
	_check(strong_total > weak_total, "missões cumpridas melhoram os equipamentos do mercado")

	var shop_inv := Inventory.new()
	shop_inv.gold = 1000
	var stock: Array = Shop.generate_stock(5, 0)["weapons"]
	var first_price: int = stock[0]["price"]
	var first_item: Item = stock[0]["item"]
	_check(Shop.buy_item(shop_inv, stock, 0) == "" and shop_inv.gold == 1000 - first_price and shop_inv.bag.has(first_item) and stock.size() == Shop.STOCK_SIZE - 1, "comprar equipamento: gasta ouro, vai para a mochila e sai do estoque")
	shop_inv.gold = 0
	_check(Shop.buy_item(shop_inv, stock, 0) == "Ouro insuficiente", "equipamento sem ouro é recusado")
	shop_inv.gold = 1000
	shop_inv.bag_capacity = shop_inv.bag.size()
	_check(Shop.buy_item(shop_inv, stock, 0) == "Mochila cheia", "equipamento com a mochila cheia é recusado")
	_check(Shop.buy_item(shop_inv, stock, 99) == "Item indisponível", "índice inválido é recusado")
	shop_inv.bag_capacity = 20
	shop_inv.bag.clear()
	var common := Item.new()
	common.rarity = 0
	common.stats = {"attack": 1}
	var rare := Item.new()
	rare.rarity = 1
	rare.stats = {"attack": 2}
	shop_inv.bag.append(common)
	shop_inv.bag.append(rare)
	var gold_before := shop_inv.gold
	_check(Shop.sell_commons(shop_inv) == common.sell_value() and shop_inv.gold == gold_before + common.sell_value() and shop_inv.bag == [rare], "vender comuns paga só os comuns e mantém os raros")
	shop_inv.sell(rare)
	_check(shop_inv.bag.is_empty() and shop_inv.gold == gold_before + common.sell_value() + rare.sell_value(), "vender item da mochila paga o valor dele")
	_stages_done += 1


# --- Castelo e mercado ------------------------------------------------------

func _list_rows() -> int:
	var rows := 0
	for child in _castle._list.get_children():
		if not child.is_queued_for_deletion():
			rows += 1
	return rows


func _test_castle() -> void:
	print("[castelo]")
	var session = root.get_node("Session")
	session.save_enabled = false
	session.reset_progress()
	session.hero_id = "gnome"
	_castle = load("res://scenes/Castle.tscn").instantiate()
	root.add_child(_castle)
	await _frames(3)
	var inv: Inventory = session.inventory

	_check(_castle._tabs.size() == 7, "mercado com 7 abas: poções, comida, armas, armaduras, acessórios, materiais e vender")
	_check(inv.bag_capacity == Inventory.BASE_BAG_SIZE + 8, "no castelo, a mochila do Gnomo já tem 8 espaços a mais")
	_check(_list_rows() == 1, "aba de poções tem a poção de vida")
	_castle.select_category("food")
	await _frames(2)
	_check(_list_rows() == 3, "aba de comida tem pão, carne assada e sopa")
	for group in ["weapons", "armor", "accessories"]:
		_castle.select_category(group)
		await _frames(2)
		_check(_list_rows() == Shop.STOCK_SIZE, "aba %s mostra %d equipamentos" % [group, Shop.STOCK_SIZE])

	inv.gold = 100
	var potions_before := inv.potions
	_check(_castle.buy_consumable("potion") == "" and inv.gold == 100 - Consumables.def("potion")["price"] and inv.potions == potions_before + 1, "comprar poção no mercado")
	inv.gold = 3
	_check(_castle.buy_consumable("potion") == "Ouro insuficiente" and _castle._message.text == "Ouro insuficiente", "sem ouro, o mercado avisa o motivo")

	_castle.select_category("weapons")
	inv.gold = 5000
	var bought: Item = session.shop_stock["weapons"][0]["item"]
	_check(_castle.buy_item("weapons", 0) == "" and inv.bag.has(bought), "comprar arma no mercado coloca na mochila")
	await _frames(2)
	_check(_list_rows() == Shop.STOCK_SIZE - 1, "o item comprado sai do estoque")

	_castle.select_category("sell")
	await _frames(2)
	_check(_list_rows() == inv.bag.size(), "aba vender lista os itens da mochila")
	var gold_before := inv.gold
	var value := bought.sell_value()
	_castle.sell_item(bought)
	_check(inv.gold == gold_before + value and inv.bag.is_empty(), "vender no castelo paga o valor do item")
	await _frames(2)
	_check(_list_rows() == 1, "mochila vazia mostra um aviso")

	_castle.select_category("armor")
	_castle.buy_item("armor", 0)
	var armor_item: Item = inv.bag.back()
	_castle.equip_item(armor_item)
	_check(inv.equipped.values().has(armor_item) and inv.bag.is_empty(), "equipar um item comprado")
	await _frames(2)
	_check(_castle.has_method("open_inventory"), "o castelo tem o botão da mochila")
	inv.unequip(armor_item.slot)
	var junk := Item.new()
	junk.rarity = 0
	junk.stats = {"hp": 1}
	inv.bag.append(junk)
	_castle.select_category("sell")
	_check(_castle.sell_commons() > 0, "vender comuns funciona pelo botão")
	_castle._sell_commons.visible = true
	_check(_castle.sell_commons() == 0 and _castle._message.text == "Nenhum item comum para vender", "sem comuns, o botão avisa")

	_castle.queue_free()
	await _frames(2)
	_stages_done += 1


# --- Inimigos ---------------------------------------------------------------

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


func _enemies_of(kind: String, generation := -1) -> Array:
	var found: Array = []
	for node in get_nodes_in_group("enemies"):
		if node.kind == kind and (generation < 0 or node.generation == generation):
			found.append(node)
	return found


func _test_enemies() -> void:
	print("[inimigos]")
	await _new_game("warrior")
	var player: Player = _game.player

	var spawnable := EnemyTypes.spawnable_kinds()
	_check(spawnable.size() == 15, "catálogo com 15 tipos de inimigo no sorteio (%d)" % spawnable.size())
	var traits := {}
	for kind in EnemyTypes.DATA:
		traits[EnemyTypes.DATA[kind]["trait"]] = true
	_check(traits.size() == EnemyTypes.DATA.size(), "cada tipo tem uma característica diferente")
	for kind in ["spider", "wolf", "ghost", "necromancer", "mushroom"]:
		_check(spawnable.has(kind), "novo inimigo no sorteio: %s" % kind)
	_check(not spawnable.has("skull"), "a caveirinha só aparece invocada")
	_check(EnemyTypes.pick(0.0) == "slime", "no início só aparecem gosmas")
	var seen := {}
	for i in 1500:
		seen[EnemyTypes.pick(300.0)] = true
	_check(seen.size() == 15 and not seen.has("skull"), "depois de 150s os 15 tipos aparecem")
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
	var minis := _enemies_of("slime", 1)
	_check(minis.size() == 2, "gosma se divide em duas ao morrer")
	_check(minis.size() == 2 and minis[0].radius < slime_radius and not minis[0].loot, "gosmas pequenas são menores e não soltam itens")
	for mini in minis:
		mini.take_damage(99999.0)
	await _frames(2)
	_check(_enemies_of("slime", 1).is_empty(), "gosma pequena não se divide de novo")

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

	# Paralisia: usada pela Poção do Gnomo e pela Pancada no Chão.
	var paralyzed := _make_enemy("slime", Vector2(300, 0))
	paralyzed.stun(2.0)
	var spot := paralyzed.global_position
	paralyzed._physics_process(0.5)
	_check(paralyzed.is_stunned() and paralyzed.global_position == spot, "inimigo paralisado não anda")
	paralyzed.global_position = player.global_position
	var health_before_stun := player.health
	paralyzed._physics_process(0.3)
	_check(is_equal_approx(player.health, health_before_stun), "inimigo paralisado não ataca")
	paralyzed._physics_process(2.0)
	_check(not paralyzed.is_stunned(), "a paralisia acaba depois do tempo")
	paralyzed.free()

	# Aranha Venenosa: mantém distância e cospe teias que deixam o herói lento.
	var spider := _make_enemy("spider", Vector2(130, 0))
	var spider_before := spider.global_position.distance_to(player.global_position)
	for i in 20:
		spider._physics_process(0.05)
	_check(spider.global_position.distance_to(player.global_position) > spider_before, "aranha recua quando o herói chega perto")
	var webs_before := _count_nodes_of(EnemyShot)
	spider._shot_timer = 0.0
	spider._physics_process(0.016)
	var web: EnemyShot
	for node in _game.world.get_children():
		if node is EnemyShot and node.kind == "web":
			web = node
	_check(_count_nodes_of(EnemyShot) == webs_before + 1 and web != null, "aranha cospe uma teia")
	var base_speed := player.get_move_speed()
	var web_health := player.health
	web.global_position = player.global_position
	web._physics_process(0.016)
	_check(player.slow_time > 1.5 and player.get_move_speed() < base_speed * 0.6, "a teia deixa o herói lento")
	_check(player.health < web_health and web_health - player.health < 6.0, "a teia fere pouco")
	player._tick_buffs(3.0)
	_check(is_equal_approx(player.get_move_speed(), base_speed), "a lentidão da teia passa")
	spider.free()

	# Fantasma: sólido ele sofre dano; etéreo ignora tudo.
	var ghost := _make_enemy("ghost", Vector2(900, 0))
	ghost._ethereal = false
	ghost._phase_time = Enemy.GHOST_SOLID_TIME
	ghost._tick_status(0.016)
	_check(ghost.is_intangible(), "fantasma fica etéreo depois do tempo sólido")
	var ghost_health := ghost.health
	ghost.take_damage(10.0)
	_check(ghost.health == ghost_health, "fantasma etéreo ignora o dano")
	_check(not _game.weapon.find_targets(2000.0).has(ghost), "fantasma etéreo não é escolhido como alvo")
	ghost._phase_time = Enemy.GHOST_ETHEREAL_TIME
	ghost._tick_status(0.016)
	_check(not ghost.is_intangible(), "fantasma volta a ficar sólido")
	ghost.take_damage(10.0)
	_check(ghost.health < ghost_health, "fantasma sólido sofre dano")
	ghost.free()

	# Lobo: avisa, investe em linha reta e descansa.
	var wolf := _make_enemy("wolf", Vector2(220, 0))
	wolf._wolf_time = 0.0
	wolf._physics_process(0.016)
	_check(wolf._wolf_state == "windup", "lobo avisa antes de investir")
	wolf._physics_process(0.7)
	_check(wolf._wolf_state == "dash", "depois do aviso o lobo investe")
	var dash_start := wolf.global_position
	wolf._physics_process(0.2)
	_check(wolf.global_position.distance_to(dash_start) > 90.0, "a investida é bem mais rápida que a corrida")
	wolf._physics_process(0.4)
	_check(wolf._wolf_state == "recover", "depois da investida o lobo descansa")
	wolf.free()

	# Necromante: invoca caveirinhas (no máximo 4).
	var necro := _make_enemy("necromancer", Vector2(900, 0))
	necro.summon_minions()
	await _frames(2)
	_check(_enemies_of("skull").size() == 2, "necromante invoca duas caveirinhas")
	necro.summon_minions()
	await _frames(2)
	necro.summon_minions()
	await _frames(2)
	_check(_enemies_of("skull").size() == 4, "no máximo 4 caveirinhas vivas")
	var skull: Enemy = _enemies_of("skull")[0]
	_check(not skull.loot and skull.xp_value == 0, "caveirinha não solta nada")
	var pickups_before := _count_nodes_of(Pickup)
	skull.take_damage(99999.0)
	await _frames(2)
	_check(_count_nodes_of(Pickup) == pickups_before, "matar caveirinha não deixa XP nem itens")
	for node in _enemies_of("skull"):
		node.free()
	necro.free()

	# Cogumelo Tóxico: deixa nuvens venenosas e uma grande ao morrer.
	var mushroom := _make_enemy("mushroom", Vector2(900, 0))
	var clouds_before := _count_nodes_of(PoisonCloud)
	mushroom._spore_timer = 0.0
	mushroom._physics_process(0.016)
	_check(_count_nodes_of(PoisonCloud) == clouds_before + 1, "cogumelo deixa uma nuvem venenosa")
	var cloud: PoisonCloud
	for node in _game.world.get_children():
		if node is PoisonCloud:
			cloud = node
	cloud.global_position = player.global_position
	cloud._tick = 0.0
	var cloud_health := player.health
	cloud._physics_process(0.016)
	_check(player.health < cloud_health, "a nuvem venenosa fere quem fica dentro")
	cloud.global_position = player.global_position + Vector2(900, 0)
	cloud._tick = 0.0
	var safe_health := player.health
	cloud._physics_process(0.016)
	_check(is_equal_approx(player.health, safe_health), "a nuvem não fere quem está longe")
	var before_death := _count_nodes_of(PoisonCloud)
	mushroom.take_damage(99999.0)
	await _frames(2)
	var biggest := 0.0
	for node in _game.world.get_children():
		if node is PoisonCloud:
			biggest = maxf(biggest, node.radius)
	_check(_count_nodes_of(PoisonCloud) > before_death and biggest >= 90.0, "cogumelo solta uma nuvem grande ao morrer")

	# O spawner usa o catálogo inteiro.
	_game.elapsed = 300.0
	for i in 80:
		_game._spawn_enemy()
	var kinds := {}
	for node in get_nodes_in_group("enemies"):
		kinds[node.kind] = true
	_check(kinds.size() >= 6, "spawner sorteia vários tipos de inimigo (%d)" % kinds.size())

	await _end_game()
	_stages_done += 1


# --- Cenário ----------------------------------------------------------------

func _scenery_sprites() -> Array:
	var sprites: Array = []
	for node in _game.world.get_children():
		if node is Sprite2D and not node.is_queued_for_deletion():
			sprites.append(node)
	return sprites


## Cenário: grama infinita, árvores e detalhes gerados em volta do herói.
func _test_scenery() -> void:
	print("[cenário]")
	var clear: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
	_check(clear.g > clear.r and clear.g > clear.b, "fundo padrão do jogo é verde, não roxo")
	var menu: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(menu)
	await _frames(2)
	var menu_has_grass := false
	for node in menu.get_children():
		if node is TextureRect and node.texture and node.texture.resource_path.ends_with("grass.png"):
			menu_has_grass = true
	_check(menu_has_grass, "tela inicial tem campo de grama")
	menu.queue_free()

	await _new_game("warrior")
	var player: Player = _game.player
	var ground: GroundLayer = _game.ground
	var decor: WorldDecor = _game.decor

	_check(_game.world.y_sort_enabled, "mundo ordena por profundidade (Y)")
	_check(ground.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED and ground._texture.resource_path.ends_with("grass.png"), "chão usa a textura de grama repetida")
	_check(ground.z_index < WorldDecor.GROUND_Z, "grama fica abaixo de flores e tufos")
	player.global_position = Vector2(1000.0, -700.0)
	ground._process(0.0)
	_check(is_equal_approx(fmod(ground.position.x, GroundLayer.TILE), 0.0) and is_equal_approx(fmod(ground.position.y, GroundLayer.TILE), 0.0), "chão acompanha o herói em múltiplos do ladrilho")
	player.global_position = Vector2.ZERO
	ground._process(0.0)

	# As setas movem o herói (o WASD usa o mesmo caminho, lendo as teclas direto).
	Input.action_press("ui_right")
	var before_move := player.global_position
	player._physics_process(0.1)
	Input.action_release("ui_right")
	_check(player.global_position.x > before_move.x and player.facing.x > 0.9, "setas movem o herói e definem a direção")
	player.global_position = Vector2.ZERO

	_check(decor.loaded_chunk_count() == (WorldDecor.LOAD_RADIUS * 2 + 1) ** 2, "pedaços do cenário carregados em volta do herói")
	var total := decor.decor_count()
	_check(total > 250 and total < 2500, "quantidade de elementos do cenário é razoável (%d)" % total)
	var kinds := {}
	for entry in decor.plan_chunk(Vector2i(0, 0)) + decor.plan_chunk(Vector2i(1, 0)) + decor.plan_chunk(Vector2i(0, 1)) + decor.plan_chunk(Vector2i(-1, -1)):
		kinds[entry["kind"]] = true
	_check(kinds.has("oak") or kinds.has("pine"), "o cenário tem árvores")
	_check(kinds.has("bush") and kinds.has("tuft") and (kinds.has("flowers_white") or kinds.has("flowers_red") or kinds.has("flowers_blue")), "o cenário tem arbustos, flores e tufos de grama")
	_check(kinds.has("rock_a") or kinds.has("rock_b"), "o cenário tem pedras")

	var too_close := 0
	var ground_decor := 0
	for sprite in _scenery_sprites():
		if sprite.z_index == 0 and sprite.position.length() < WorldDecor.SAFE_RADIUS:
			too_close += 1
		if sprite.z_index == WorldDecor.GROUND_Z:
			ground_decor += 1
	_check(too_close == 0, "nenhuma árvore ou pedra nasce em cima do ponto inicial")
	_check(ground_decor > 0, "flores e tufos ficam abaixo dos personagens")

	# O mesmo pedaço nasce sempre igual para o mesmo seed.
	var first := decor.plan_chunk(Vector2i(3, -2))
	var second := decor.plan_chunk(Vector2i(3, -2))
	var same := first.size() == second.size()
	for i in mini(first.size(), second.size()):
		same = same and first[i]["kind"] == second[i]["kind"] and first[i]["position"] == second[i]["position"]
	_check(same, "o mesmo pedaço gera sempre o mesmo cenário")
	var other := WorldDecor.new()
	other.world_seed = decor.world_seed + 1234
	other._noise.seed = other.world_seed
	var different := other.plan_chunk(Vector2i(3, -2))
	var differs := different.size() != first.size()
	for i in mini(first.size(), different.size()):
		differs = differs or first[i]["position"] != different[i]["position"]
	_check(differs, "seeds diferentes geram cenários diferentes")
	other.free()

	# Andar longe carrega cenário novo e descarta o antigo.
	player.global_position = Vector2(1800.0, 0.0)
	decor._process(0.0)
	await _frames(2)
	var near_new := 0
	var near_old := 0
	for sprite in _scenery_sprites():
		if sprite.position.distance_to(player.global_position) < 900.0:
			near_new += 1
		if sprite.position.length() < 600.0:
			near_old += 1
	_check(near_new > 100, "cenário novo aparece onde o herói chegou")
	_check(decor.loaded_chunk_count() <= (WorldDecor.UNLOAD_RADIUS * 2 + 1) ** 2, "pedaços carregados ficam limitados")
	player.global_position = Vector2.ZERO
	decor._process(0.0)

	# Camadas: efeitos acima do cenário, zona de gelo e flores no chão.
	var ring := RingEffect.new()
	_game.world.add_child(ring)
	var zone := SkillZone.new()
	_game.world.add_child(zone)
	var pickup := Pickup.new()
	_game.world.add_child(pickup)
	_check(ring.z_index > 0 and zone.z_index < 0 and zone.z_index > WorldDecor.GROUND_Z and pickup.z_index > 0, "efeitos e drops aparecem acima do cenário; a zona de gelo, no chão")
	ring.free()
	zone.free()
	pickup.free()

	var vignette := false
	for layer in _game.get_children():
		if layer is CanvasLayer:
			for child in layer.get_children():
				if child is TextureRect and child.texture is GradientTexture2D and child.mouse_filter == Control.MOUSE_FILTER_IGNORE:
					vignette = true
	_check(vignette, "vinheta escurece as bordas sem bloquear toques")

	await _end_game()
	_stages_done += 1


# --- Missão -----------------------------------------------------------------

func _spawn_enemy(offset: Vector2, health := 30.0) -> Enemy:
	var enemy := Enemy.new()
	enemy.max_health = health
	enemy.target = _game.player
	enemy.speed = 0.0
	_game.world.add_child(enemy)
	enemy.global_position = _game.player.global_position + offset
	return enemy


## Missão: barra de progresso, fim do spawn e vitória quando não restar inimigo.
func _test_mission() -> void:
	print("[missão]")
	await _new_game("warrior")
	var duration: float = _game.mission_duration
	_check(_game.spawning and _game.mission_progress() < 0.01, "missão começa com inimigos surgindo e progresso zero")
	_game.elapsed = duration * 0.5
	_game._update_hud()
	_check(is_equal_approx(_game.mission_progress(), 0.5) and is_equal_approx(_game.mission_bar.value, 0.5), "barra da missão acompanha o progresso")
	_check(_game.mission_bar.label_text.begins_with("Sobreviva"), "barra avisa que ainda surgem inimigos")

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
	_check(_game.mission_bar.label_text.begins_with("Elimine"), "barra mostra quantos inimigos restam")

	for node in get_nodes_in_group("enemies"):
		node.free()
	var session = root.get_node("Session")
	var gold_before: int = _game.player.inventory.gold
	var missions_before: int = session.missions_done
	_game._process(0.3)
	_check(not _game.mission_complete, "espera um instante antes de dar a missão por cumprida")
	_game._process(0.4)
	_check(_game.mission_complete and not _game.victory_panel.visible, "missão cumprida quando o último inimigo morre (a vitória espera alguns segundos)")
	_game._show_victory()
	_check(_game.victory_panel.visible and paused, "e depois mostra a tela de vitória")
	_check(_game.player.inventory.gold == gold_before + _game.mission_reward, "missão cumprida dá bônus de ouro")
	_check(session.missions_done == missions_before + 1, "a missão cumprida é contada")
	_check(session.shop_stock.is_empty(), "o mercado renova o estoque depois da missão")
	var button_texts: Array = []
	for child in _game.victory_panel.get_child(0).get_children():
		if child is Button:
			button_texts.append(child.text)
	_check(button_texts.has("Voltar ao castelo") and button_texts.has("Voltar ao menu"), "a tela de vitória leva de volta ao castelo")
	await _end_game()
	_stages_done += 1


# --- Heróis -----------------------------------------------------------------

func _test_hero(hero_id: String) -> void:
	print("[%s]" % hero_id)
	await _new_game(hero_id)
	var player: Player = _game.player
	var hero := Heroes.get_hero(hero_id)

	_check(player.hero_id == hero_id, "herói da sessão chegou na partida")
	_check(is_equal_approx(player.max_health, hero["health"]), "vida inicial do herói")
	_check(_game.skill_buttons.size() == hero["skills"].size() + 1, "barra com %d habilidades, a última travada" % (hero["skills"].size() + 1))
	_check(_game.quick_bar.visible and not _game.inventory_window.visible, "barra rápida visível e mochila fechada no começo")
	_check(player.inventory.bag_capacity == Inventory.BASE_BAG_SIZE + hero["bag_bonus"], "mochila do herói: %d espaços" % (Inventory.BASE_BAG_SIZE + hero["bag_bonus"]))
	_check(player.inventory == root.get_node("Session").inventory, "o inventário da missão é o mesmo do castelo")
	_check(player.get_luck() == hero["base_luck"], "sorte inicial do herói")

	_test_hud_bars()
	_test_combat(hero)
	await _test_skills(hero_id)
	await _test_unlock_skill(hero_id)
	_test_energy(hero_id)
	_test_skill_attributes(hero_id)
	await _test_inventory_and_stats()
	await _test_inventory_panel()
	await _test_levels()

	player.take_damage(99999.0)
	_check(_game.game_over, "fim de jogo ao zerar a vida")
	await _end_game()
	_stages_done += 1


func _test_hud_bars() -> void:
	var player: Player = _game.player
	_check(_game.hp_bar is MedievalBar and _game.energy_bar is MedievalBar and _game.xp_bar is MedievalBar, "barras de vida, energia e XP no estilo medieval")
	_check(_game.hp_bar.get_parent() == _game.energy_bar.get_parent(), "as barras ficam juntas no quadro de status")
	var expected_text := "%d / %d" % [int(ceil(player.health)), int(player.max_health)]
	_check(_game.hp_bar.label_text == expected_text, "barra de vida mostra vida atual e máxima")
	_game._update_hud()
	_check(is_equal_approx(_game.energy_bar.max_value, player.get_max_energy()) and is_equal_approx(_game.energy_bar.value, player.energy), "barra de energia acompanha a energia do herói")
	_check(_game.energy_bar.label_text == "%d / %d" % [int(player.energy), int(player.get_max_energy())], "barra de energia mostra o valor")
	_game.hp_bar.value = _game.hp_bar.max_value * 0.5
	_check(is_equal_approx(_game.hp_bar.ratio(), 0.5), "a barra preenche na proporção do valor")
	_game._on_player_health_changed(player.health, player.max_health)
	_check(_game.mission_bar is MedievalBar and _game.mission_bar.max_value == 1.0, "barra da missão existe")


func _count_projectiles() -> int:
	var total := 0
	for node in _game.world.get_children():
		if node is Projectile:
			total += 1
	return total


func _test_combat(hero: Dictionary) -> void:
	var enemy := _spawn_enemy(Vector2(60, 0))
	var projectiles_before := _count_projectiles()
	_game.weapon._cooldown = 0.0
	_game.weapon._process(0.0)
	if hero["attack"] == "blunderbuss":
		_check(_count_projectiles() - projectiles_before == 4, "o bacamarte solta 4 fragmentos por disparo")
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
	var target_enemy: Enemy = _spawn_enemy(Vector2(50, 0) if hero_id == "mage" else Vector2(200, 0), 1000.0) if hero_id in ["mage", "gnome"] else null
	for id in Heroes.get_hero(hero_id)["skills"]:
		_check(_game.try_cast(id), "habilidade %s dispara" % id)
		_check(not _game.try_cast(id), "habilidade %s entra em recarga" % id)
		_check(_game.skill_buttons[id].cooldown_total > 0.0, "botão %s existe" % id)
	match hero_id:
		"mage":
			var enemy := target_enemy
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
		"gnome":
			var enemy := target_enemy
			var thrown: Array = []
			for node in _game.world.get_children():
				if node is ThrownItem:
					thrown.append(node)
			_check(thrown.size() == 2, "o Gnomo arremessa a bomba e a poção")
			for item in thrown:
				item._process(1.0)
			_check(enemy._burn_ticks == 6, "a bomba de fogo queima 6 vezes, o dobro do Fogo")
			_check(enemy.health < enemy.max_health, "a bomba causa dano em área")
			_check(enemy.is_stunned() and enemy._stun_time > 1.8, "a poção paralisa os inimigos por 2s")
			enemy.free()


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


## A quarta habilidade de cada herói só é liberada no nível 20.
func _test_unlock_skill(hero_id: String) -> void:
	var player: Player = _game.player
	var hero := Heroes.get_hero(hero_id)
	var id: String = hero["unlock"]["id"]
	for cooldown_id in _game.cooldowns:
		_game.cooldowns[cooldown_id] = 0.0
	player.energy = player.get_max_energy()
	_game.level = 1
	_game._update_hud()
	_check(not _game.is_unlocked(id) and _game.skill_buttons[id].locked, "%s começa travada no nível 1" % id)
	_check(not _game.try_cast(id) and is_equal_approx(player.energy, player.get_max_energy()), "habilidade travada não dispara nem gasta energia")
	_game.level = 19
	_check(not _game.is_unlocked(id), "continua travada no nível 19")
	_game.level = 20
	_game._announce_unlocks(19)
	_check(_game.toast_label.text.contains(Skills.def(id)["name"]), "ao chegar no nível 20 o jogo avisa a habilidade liberada")
	_game._update_hud()
	_check(_game.is_unlocked(id) and not _game.skill_buttons[id].locked, "%s é liberada no nível 20" % id)

	var cast_player := player
	match hero_id:
		"mage":
			# O vizinho está além do alcance de mira (440): só sofre o dano em área do raio vizinho.
			var primary := _spawn_enemy(Vector2(430, 0), 1000.0)
			var neighbor := _spawn_enemy(Vector2(480, 0), 1000.0)
			var far := _spawn_enemy(Vector2(900, 0), 1000.0)
			_check(_game.try_cast(id), "Raio dispara no nível 20")
			_check(_count_nodes_of(LightningBolt) >= 1, "o raio cai do céu")
			var primary_loss := primary.max_health - primary.health
			var neighbor_loss := neighbor.max_health - neighbor.health
			_check(primary_loss > 0.0, "o raio atinge o inimigo")
			_check(neighbor_loss > 0.0 and neighbor_loss < primary_loss, "o raio também causa dano em área ao redor")
			_check(far.health == far.max_health, "inimigo longe demais não é atingido")
			primary.free()
			neighbor.free()
			far.free()
		"archer":
			_check(_game.try_cast(id), "Flechas de Fogo disparam no nível 20")
			var arrows := 0
			var all_burn := true
			for node in _game.world.get_children():
				if node is Projectile and node.style == "fire_arrow":
					arrows += 1
					all_burn = all_burn and node.burn_ticks == 3
			_check(arrows == 5 and all_burn, "5 flechas de fogo que queimam")
		"warrior":
			var close := _spawn_enemy(Vector2(120, 0), 1000.0)
			var behind := _spawn_enemy(Vector2(-150, 0), 1000.0)
			var away := _spawn_enemy(Vector2(600, 0), 1000.0)
			_check(_game.try_cast(id), "Pancada no Chão dispara no nível 20")
			_check(close.health < close.max_health and behind.health < behind.max_health, "a pancada atinge em área, em volta de todo o herói")
			_check(close.is_stunned() and behind.is_stunned(), "a pancada atordoa quem atinge")
			_check(away.health == away.max_health and not away.is_stunned(), "quem está longe não é atingido")
			_check(_count_nodes_of(CrackEffect) == 1, "o chão racha")
			close.free()
			behind.free()
			away.free()
		"gnome":
			var targets: Array = []
			for i in 3:
				targets.append(_spawn_enemy(Vector2(150 + i * 60, i * 30), 1000.0))
			_check(_game.try_cast(id), "Chuva de Bombas dispara no nível 20")
			var bombs: Array = []
			for node in _game.world.get_children():
				if node is ThrownItem and node.kind == "bomb" and not node.is_queued_for_deletion():
					bombs.append(node)
			_check(bombs.size() == Skills.BOMB_RAIN_COUNT, "5 bombas são lançadas")
			for bomb in bombs:
				bomb._process(1.0)
			var burning := 0
			for enemy in targets:
				if enemy._burn_ticks == 6:
					burning += 1
			_check(burning == 3, "as bombas queimam os inimigos próximos")
			for enemy in targets:
				enemy.free()
	_game.level = 1
	_game._update_hud()
	for node in _game.world.get_children():
		if node is Projectile or node is ThrownItem or node is LightningBolt or node is CrackEffect:
			node.free()


## Habilidades gastam energia, que volta com o tempo.
func _test_energy(hero_id: String) -> void:
	var player: Player = _game.player
	var id: String = Heroes.get_hero(hero_id)["skills"][0]
	var cost := Skills.cost_for(id)
	for cooldown_id in _game.cooldowns:
		_game.cooldowns[cooldown_id] = 0.0
	player.energy = cost - 1.0
	_check(not _game.try_cast(id) and is_equal_approx(player.energy, cost - 1.0) and _game.cooldowns[id] == 0.0, "sem energia a habilidade não dispara")
	player.energy = cost + 10.0
	_check(_game.try_cast(id) and is_equal_approx(player.energy, 10.0), "a habilidade gasta sua energia (%d)" % int(cost))
	player.energy = 0.0
	player._tick_buffs(2.0)
	_check(is_equal_approx(player.energy, Player.ENERGY_REGEN * 2.0), "a energia volta com o tempo")
	player._tick_buffs(1000.0)
	_check(is_equal_approx(player.energy, player.get_max_energy()), "a energia não passa do máximo")
	_check(is_equal_approx(player.get_max_energy(), Heroes.get_hero(hero_id)["energy"]), "energia máxima do herói")
	for cooldown_id in _game.cooldowns:
		_game.cooldowns[cooldown_id] = 0.0
	player.energy = player.get_max_energy()


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
		"gnome":
			Skills.cast("paralysis", _game)
			var flask: ThrownItem
			for node in _game.world.get_children():
				if node is ThrownItem:
					flask = node
			_check(flask != null and is_equal_approx(flask.reach, player.skill_range_mult()), "Alcance aumenta a área das poções do Gnomo")
			var victim := _spawn_enemy(Vector2(200, 0), 100.0)
			flask.destination = victim.global_position
			flask._process(1.0)
			_check(victim._stun_time > ThrownItem.PARALYSIS_TIME, "Poder aumenta o tempo da paralisia")
			victim.free()
	for stat in player.skill_attributes:
		player.skill_attributes[stat] = 0
	for node in _game.world.get_children():
		if node is ThrownItem or node is SkillZone:
			node.free()


func _test_inventory_and_stats() -> void:
	var player: Player = _game.player
	var inventory := player.inventory
	inventory.bag.clear()
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
	for i in inventory.bag_capacity:
		inventory.add_item(Item.roll(0, 1))
	var gold_before := inventory.gold
	_check(not inventory.add_item(Item.roll(0, 1)) and inventory.gold > gold_before, "mochila cheia vende o item")
	_check(inventory.bag.size() == inventory.bag_capacity, "a mochila comporta exatamente a capacidade do herói")
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

	# Limites: por atributo (100 pontos) e no total com equipamentos (100).
	for i in 120:
		player.add_attribute("defense")
	_check(player.attributes["defense"] == Player.MAX_ATTRIBUTE_POINTS, "atributo para no limite de pontos")
	_check(not player.add_attribute("defense"), "ponto além do limite é recusado")
	inventory.bag.clear()
	var ring := Item.new()
	ring.item_name = "Anel Absurdo"
	ring.slot = "ring"
	ring.stats = {"defense": 15}
	player.attributes["defense"] = 90
	inventory.add_item(ring)
	inventory.equip(ring)
	_check(player.stat_points("defense") == Player.MAX_TOTAL_POINTS, "atributo mais equipamento respeita o limite total")
	inventory.unequip("ring")
	player.attributes["defense"] = 0
	inventory.bag.clear()


## Janela da mochila (estilo Surve): equipamento em 9 casas, grade, busca, filtro, comparação,
## arrastar, lixeira, e os drops animados com feed e números de dano.
func _test_inventory_panel() -> void:
	var window: InventoryWindow = _game.inventory_window
	var inventory: Inventory = _game.player.inventory
	inventory.bag.clear()
	inventory.equipped.clear()
	_check(not window.is_open(), "a janela da mochila começa fechada")
	_check(_game.quick_bar != null and _game.quick_bar.get_child_count() == InventoryWindow.CONSUMABLES.size(), "a coluna rápida tem os 4 slots de consumíveis")
	_game.toggle_inventory()
	await _frames(3)
	_check(window.is_open() and _game.modal_open and paused, "abrir a mochila pausa o jogo")
	_check(window._equip_grid.get_child_count() == Item.EQUIP_KEYS.size() + 1, "janela mostra as casas de equipamento e a do pet")
	_check(window._bag_grid.get_child_count() == inventory.bag_capacity, "janela mostra um slot para cada espaço da mochila")
	_check(window._consumable_slots.size() == InventoryWindow.CONSUMABLES.size(), "janela tem poção e as 3 comidas")
	_check(window._gold_label.text == "Ouro: %d" % inventory.gold, "janela mostra o ouro")
	_check(window._close_button.custom_minimum_size.x >= 48.0, "botão de fechar com tamanho de toque")

	var weak := Item.new()
	weak.item_name = "Espada Fraca"
	weak.slot = "weapon"
	weak.stats = {"attack": 1}
	var strong := Item.new()
	strong.item_name = "Espada Forte"
	strong.slot = "weapon"
	strong.rarity = 2
	strong.stats = {"attack": 4, "luck": 2}
	var helmet := Item.new()
	helmet.item_name = "Elmo de Teste"
	helmet.slot = "helmet"
	helmet.stats = {"hp": 3}
	for item in [weak, strong, helmet]:
		inventory.add_item(item)
	await _frames(2)
	window._on_bag_slot_pressed(0)
	await _frames(1)
	_check(window._selected == weak and window._equip_button.visible, "tocar num item mostra os detalhes e o botão Equipar")
	window._on_bag_slot_pressed(0)
	await _frames(2)
	_check(inventory.equipped.get("weapon") == weak and inventory.bag.size() == 2, "toque duplo equipa")
	window._on_bag_slot_pressed(0)
	await _frames(1)
	_check(window._info.get_parsed_text().contains("Comparado com Espada Fraca"), "o detalhe diz com qual item vestido comparou")

	window._search.text = "elmo"
	window._refresh()
	_check(window._bag_grid.get_child_count() == 1, "a busca mostra só o Elmo")
	window._search.text = ""
	window._filter = "accessories"
	window._refresh()
	_check(window._bag_grid.get_child_count() == 1 and window._bag_grid.get_child(0) is Label, "filtro de acessórios sem resultados avisa")
	window._filter = "all"
	window._refresh()
	inventory.sort_bag()
	_check(inventory.bag[0] == strong, "ordenar põe a maior raridade primeiro")

	# Arrastar e soltar: item da mochila para a casa certa e para a errada.
	var wrong_target: ItemSlot = null
	var right_target: ItemSlot = null
	for slot in window._equip_grid.get_children():
		if slot.slot_key == "ring":
			wrong_target = slot
		if slot.slot_key == "helmet":
			right_target = slot
	var helmet_slot: ItemSlot = null
	for slot in window._bag_grid.get_children():
		if slot is ItemSlot and slot.item == helmet:
			helmet_slot = slot
	window._on_dropped(helmet_slot, wrong_target)
	_check(inventory.equipped.get("helmet") == null, "soltar na casa errada não equipa")
	window._on_dropped(helmet_slot, right_target)
	_check(inventory.equipped.get("helmet") == helmet, "soltar na casa certa equipa")
	await _frames(2)
	var worn_slot: ItemSlot = null
	for slot in window._equip_grid.get_children():
		if slot.slot_key == "helmet":
			worn_slot = slot
	var target_bag: ItemSlot = window._bag_grid.get_child(5)
	window._on_dropped(worn_slot, target_bag)
	_check(inventory.equipped.get("helmet") == null and inventory.bag.has(helmet), "soltar o equipado na mochila tira o item")
	_check(target_bag._can_drop_data(Vector2.ZERO, {"slot": worn_slot}), "casas da mochila aceitam item arrastado")
	var order_before := inventory.bag.duplicate()
	inventory.move_in_bag(0, 1)
	_check(inventory.bag[1] == order_before[0] and inventory.bag.size() == order_before.size(), "mover dentro da mochila reordena sem perder item")

	# Lixeira pede confirmação; vender paga.
	window._select(helmet, false)
	var gold_before := inventory.gold
	window._on_trash_pressed()
	_check(inventory.bag.has(helmet), "descartar pede confirmação antes")
	window._on_trash_pressed()
	_check(not inventory.bag.has(helmet) and inventory.gold == gold_before, "confirmar descarta sem pagar")
	window._select(strong, false)
	window._on_sell_pressed()
	_check(inventory.gold == gold_before + strong.sell_value() and not inventory.bag.has(strong), "vender paga o valor do item")

	_game.player.health = 20.0
	inventory.add_consumable("bread")
	var used := []
	window.consumable_used.connect(func(id: String) -> void: used.append(id))
	var bread_before := inventory.count("bread")
	window._use_consumable("bread")
	_check(used == ["bread"] and inventory.count("bread") == bread_before - 1 and _game.player.health > 20.0, "tocar na comida usa e cura")

	window.close()
	await _frames(2)
	_check(not window.is_open() and not _game.modal_open and not paused, "fechar a mochila despausa o jogo")
	_game.toggle_inventory()
	await _frames(1)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	window._on_dimmer_input(click)
	_check(window.is_open(), "o toque que abriu a janela não a fecha na hora")
	window._opened_at = -10000
	window._on_dimmer_input(click)
	_check(not window.is_open(), "tocar fora fecha a janela")
	await _frames(2)

	# Feed de drops e número de dano (os drops animados em si ficam em tools/check_drops.gd,
	# porque o Pickup usa o EventBus, que ainda não existe quando este script compila).
	var drop_item := Item.new()
	drop_item.rarity = 3
	drop_item.slot = "helmet"
	drop_item.stats = {"hp": 5}
	var feed_before: int = _game.loot_feed.get_child_count()
	root.get_node("EventBus").pickup_collected.emit("item", drop_item)
	root.get_node("EventBus").pickup_collected.emit("gold", 3)
	root.get_node("EventBus").pickup_collected.emit("gold", 4)
	_check(_game.loot_feed.get_child_count() == feed_before + 2, "o feed mostra o item e soma o ouro seguido")
	_check(inventory.bag.has(drop_item), "o item coletado vai para a mochila")
	var numbers_before := _count_nodes_of(DamageNumber)
	root.get_node("EventBus").damage_dealt.emit(12.0, _game.player.global_position, "hit")
	_check(_count_nodes_of(DamageNumber) == numbers_before + 1, "dano em inimigo mostra um número flutuante")

	inventory.bag.clear()
	inventory.equipped.clear()
	inventory.changed.emit()
	await _frames(2)


## Nível sem pausar: melhoria automática, escolha rápida a cada 4 níveis e pontos distribuídos sozinhos.
## (Os testes mais completos, com inimigos de verdade, ficam em tools/check_stages.gd.)
func _test_levels() -> void:
	_game.level = 1
	_game.xp = 0.0
	_game.xp_to_next = 1.0
	_game.pending_choices = 0
	_game.card_counts.clear()
	root.get_node("EventBus").pickup_collected.emit("xp", 5)
	_check(_game.level >= 2 and not paused and not _game.modal_open, "subir de nível não pausa a partida")
	var applied := 0
	for key in _game.card_counts:
		applied += _game.card_counts[key]
	_check(applied >= 1, "cada nível aplica uma melhoria sozinho")
	_check(_game.level >= 2 and _game.xp_to_next > 1.0, "a barra de XP segue para o próximo nível")
	if _game.weapon.kind == "melee":
		_check(not _game._upgrade_pool().any(func(option: Dictionary) -> bool: return option["name"] in ["Tiro múltiplo", "Mira longa"]), "guerreiro não recebe melhorias de projétil")

	# Escolha rápida a cada 4 níveis: não pausa e deixa o jogo em câmera lenta.
	_game.level = 3
	_game.xp = 0.0
	_game.xp_to_next = 1.0
	root.get_node("EventBus").pickup_collected.emit("xp", 5)
	_check(_game.level == 4 and _game.choice_strip.is_open(), "no nível 4 abre a escolha rápida")
	_check(not paused and is_equal_approx(Engine.time_scale, _game.CHOICE_TIME_SCALE), "a escolha rápida usa câmera lenta, não pausa")
	_check(_game.choice_strip.options().size() == 3, "a escolha tem três cartas")
	_game.choice_strip.pick(0)
	_check(not _game.choice_strip.is_open() and Engine.time_scale == 1.0, "escolher fecha a faixa e normaliza o tempo")

	# Nível 5: nada de pontos automáticos; abre o popup de atributos permanentes (e pausa).
	var attribute_points := 0
	for stat in _game.player.attributes:
		attribute_points += int(_game.player.attributes[stat])
	_game.level = 4
	_game.xp = 0.0
	_game.xp_to_next = 1.0
	root.get_node("EventBus").pickup_collected.emit("xp", 5)
	var attribute_after := 0
	for stat in _game.player.attributes:
		attribute_after += int(_game.player.attributes[stat])
	_check(attribute_after == attribute_points, "subir de nível não dá pontos de atributo sozinhos")
	_check(_game.level == 5 and _game.attribute_popup.is_open() and paused, "no nível 5 abre o popup de atributos permanentes")
	_check(_game.attribute_popup.add_point("hp") and _game.attribute_popup.add_point("dex") and _game.attribute_popup.add_point("aspd"), "os 3 pontos do popup")
	_game.attribute_popup.confirm()
	_check(not _game.attribute_popup.is_open() and not paused, "confirmar retoma o jogo")
	_game.choice_strip.hide()
	_game.pending_choices = 0
	Engine.time_scale = 1.0
	for stat in _game.player.attributes:
		_game.player.attributes[stat] = 0
	_game.card_counts.clear()
