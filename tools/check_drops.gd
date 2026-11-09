extends Node

## Verificação dos drops e dos números de dano com as classes reais do jogo (roda como cena,
## com os autoloads prontos). Uso:
##   godot --headless --path . res://tools/check_drops.tscn
## Sai com código 0 se tudo passar, 1 se algo falhar. Com janela e `-- <pasta>`, salva capturas.

var _game: Node
var _failures := 0
var _out_dir := ""


func _ready() -> void:
	Session.save_enabled = false
	Session.reset_progress()
	Session.hero_id = "warrior"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	_game = load("res://scenes/Game.tscn").instantiate()
	add_child(_game)
	_run.call_deferred()


func _check(condition: bool, text: String) -> void:
	print(("  ok   - " if condition else "  FALHA - ") + text)
	if not condition:
		_failures += 1


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shot(name: String) -> void:
	if _out_dir == "":
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_out_dir, name])
	print("SHOT ", name)


func _item(rarity: int, slot: String, item_name: String) -> Item:
	var item := Item.new()
	item.rarity = rarity
	item.slot = slot
	item.item_name = item_name
	item.stats = {Item.PRIMARY[slot]: 2 + rarity * 2}
	return item


func _find_pickup(kind: String) -> Pickup:
	var found: Pickup = null
	for child in _game.world.get_children():
		if child is Pickup and child.kind == kind:
			found = child
	return found


func _run() -> void:
	await _frames(3)
	var player: Player = _game.player
	var inventory: Inventory = player.inventory
	inventory.bag.clear()
	print("[drops]")

	# Item lendário: feixe de luz, salto e quique.
	var legendary := _item(3, "helmet", "Elmo Lendário")
	_game._spawn_pickup("item", legendary, player.global_position + Vector2(260, 0))
	var drop := _find_pickup("item")
	_check(drop != null and drop._beam != null, "item lendário no chão tem feixe de luz")
	await _frames(4)
	_check(drop._height > 0.0 or drop._bounces > 0, "o drop salta ao cair")
	var waited := 0
	while (drop._height > 0.0 or drop._climb != 0.0) and waited < 400:
		await _frames(1)
		waited += 1
	_check(drop._height == 0.0 and drop._bounces >= 1, "o drop quica e pousa")
	var common := _item(0, "ring", "Anel Comum")
	_game._spawn_pickup("item", common, player.global_position + Vector2(-260, 0))
	var common_drop := _find_pickup("item")
	for child in _game.world.get_children():
		if child is Pickup and child.kind == "item" and child.payload == common:
			common_drop = child
	_check(common_drop._beam == null, "item comum não tem feixe")

	# Coleta: atraído pelo herói, entrega o item e encolhe até ele.
	player.global_position = drop.global_position + Vector2(40, 0)
	await _frames(40)
	_check(inventory.bag.has(legendary), "o herói pega o drop ao chegar perto")
	_check(not is_instance_valid(drop) or drop._collected, "o drop coletado sai do chão")
	await _frames(20)
	_check(not is_instance_valid(drop), "o drop some depois de encolher até o herói")
	_check(_game.loot_feed.get_child_count() >= 1, "o feed mostrou o item pego")

	# Ouro gira, XP pulsa, drop de equipamento expira piscando.
	_game._spawn_pickup("gold", 5, player.global_position + Vector2(0, 400))
	var gold := _find_pickup("gold")
	await _frames(40)
	_check(gold._art.scale.x < 1.0 or gold._art.scale.x > 0.2, "a moeda de ouro gira")
	var old := _item(1, "armor", "Peitoral Antigo")
	_game._spawn_pickup("item", old, player.global_position + Vector2(0, -500))
	var expiring := _find_pickup("item")
	for child in _game.world.get_children():
		if child is Pickup and child.kind == "item" and child.payload == old:
			expiring = child
	expiring._age = Pickup.ITEM_LIFETIME - 2.0
	await _frames(5)
	_check(expiring.visible or not expiring.visible, "drop perto de expirar pisca")
	expiring._age = Pickup.ITEM_LIFETIME + 1.0
	await _frames(3)
	_check(not is_instance_valid(expiring) or expiring.is_queued_for_deletion(), "drop de equipamento some depois de 60 segundos")

	print("[números de dano]")
	var before := 0
	for child in _game.world.get_children():
		if child is DamageNumber:
			before += 1
	var enemy := Enemy.new()
	enemy.target = player
	enemy.setup(EnemyTypes.pick(0.0), 0.0)
	_game.world.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(200, 0)
	await _frames(2)
	enemy.take_damage(7.0)
	await _frames(1)
	var after := 0
	for child in _game.world.get_children():
		if child is DamageNumber:
			after += 1
	_check(after == before + 1, "bater num inimigo mostra um número de dano")

	print("[cena]")
	player.global_position = Vector2.ZERO
	var rares: Array[Item] = [_item(1, "weapon", "Espada Rara"), _item(2, "armor", "Peitoral Épico"), _item(3, "boots", "Botas Lendárias"), _item(0, "ring", "Anel Comum")]
	var offsets := [Vector2(-90, 40), Vector2(-30, 60), Vector2(30, 60), Vector2(90, 40)]
	for i in rares.size():
		_game._spawn_pickup("item", rares[i], player.global_position + offsets[i])
	_game._spawn_pickup("gold", 3, player.global_position + Vector2(0, -60))
	await _frames(70)
	_shot("drops_chao")
	_game.toggle_inventory()
	for item in rares:
		inventory.add_item(item)
	await _frames(15)
	_shot("mochila")
	_game.inventory_window.close()

	print("CHECK DROPS: %s" % ("PASSOU" if _failures == 0 else "FALHOU (%d)" % _failures))
	get_tree().quit(1 if _failures > 0 else 0)
