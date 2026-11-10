extends Node

## Estado que atravessa as telas e as missões: herói escolhido, inventário,
## missões cumpridas e estoque do mercado. O inventário é salvo no disco.

const SAVE_VERSION := 2
const SAVE_INTERVAL := 2.0

var hero_id := "warrior"
var inventory := Inventory.new()
var missions_done := 0
## Fase escolhida no castelo e estrelas (0 a 3) de cada fase. A fase i só abre depois de vencer a i-1.
var stage_index := 0
var stage_stars: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
## O ataque automático só é liberado depois de derrotar o primeiro chefe.
var auto_attack := false
## Preferência do jogador: com o automático liberado, ele pode ligar e desligar (botão Auto na partida).
var auto_attack_on := true
## Jornada em andamento: nível, XP, atributos e melhorias que o herói acumulou desde o último chefe.
## Cada fase vencida soma à jornada; vencer um chefe zera tudo. Vale só para o herói `run_hero`.
var run_hero := ""
var run: Dictionary = {}
## Atributos permanentes (escolhidos no popup de nível) de cada herói: {herói: {atributo: pontos}}.
var perm_attributes: Dictionary = {}
## Pets conquistados dos chefes e o que está ativo.
var pets: Array = []
var active_pet := ""
## Nível de cada pet (sem limite), melhorado com ouro: só aumenta o dano dos tiros do pet.
var pet_levels := {}
## O pet conquistado agora por abates (o jogo avisa e limpa).
var unlocked_pet := ""
## Etapa de evolução de cada herói (0 a Evolution.TIERS), ver Evolution.
var evolutions := {}
## Nível (0 a 5) de cada habilidade ativa de cada herói: {herói: {id da habilidade: nível}}.
var skill_levels := {}
## Habilidades equipadas de cada herói: {herói: [id, id, ...]} (uma por casa da barra). Vazio = as iniciais.
var skill_loadout := {}
## Níveis da árvore de habilidades: {herói: {id do nó: nível}} (ver SkillTree).
var skill_tree := {}
## Filtro de drops (botão Drop): tipos de item ignorados e raridades que viram fragmento sozinhas.
var ignored_types: Array = []
var auto_fragment: Array = [false, false, false, false, false]
## Arena PvP: se a próxima partida é um duelo, contra qual herói, em qual dificuldade, e o placar.
var pvp := false
var pvp_rival := "mage"
var pvp_difficulty := "normal"
var pvp_wins := 0
var pvp_losses := 0
## Nível acumulativo de cada herói: {herói: {level, xp, points, earned}}. Nunca zera.
var hero_progress: Dictionary = {}
## Quantos monstros de cada espécie já foram derrotados (catálogo e conquistas).
var monster_kills: Dictionary = {}
var shop_seed := 0
var shop_stock := {}
## Os testes desligam o salvamento para não mexer no save de quem joga.
var save_enabled := true
var save_path := "user://ashveil_save.json"
var _dirty := false
var _since_change := 0.0


func _ready() -> void:
	shop_seed = randi()
	load_game()
	_bind_inventory()


func _process(delta: float) -> void:
	if _dirty:
		_since_change += delta
		if _since_change >= SAVE_INTERVAL:
			save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


func _bind_inventory() -> void:
	if not inventory.changed.is_connected(_mark_dirty):
		inventory.changed.connect(_mark_dirty)


func _mark_dirty() -> void:
	_dirty = true
	_since_change = 0.0


## Recomeça do zero: inventário inicial, nenhuma missão cumprida.
func reset_progress() -> void:
	inventory = Inventory.new()
	missions_done = 0
	stage_index = 0
	stage_stars = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	auto_attack = false
	auto_attack_on = true
	reset_run()
	perm_attributes = {}
	pets = []
	active_pet = ""
	pet_levels = {}
	evolutions = {}
	skill_tree = {}
	skill_levels = {}
	skill_loadout = {}
	ignored_types = []
	auto_fragment = [false, false, false, false, false]
	pvp_wins = 0
	pvp_losses = 0
	hero_progress = {}
	monster_kills = {}
	shop_seed = randi()
	shop_stock = {}
	_dirty = false
	_bind_inventory()


## Estoque de equipamentos do mercado. Muda a cada missão cumprida.
func ensure_stock() -> Dictionary:
	if shop_stock.is_empty():
		shop_stock = Shop.generate_stock(shop_seed, missions_done)
	return shop_stock


func stars_of(index: int) -> int:
	return int(stage_stars[index]) if index >= 0 and index < stage_stars.size() else 0


func is_stage_unlocked(index: int) -> bool:
	return index == 0 or (index > 0 and stars_of(index - 1) > 0)


## A fase mais avançada liberada (as fases são infinitas: a próxima só abre ao vencer a anterior).
func highest_unlocked() -> int:
	var index := 0
	while stars_of(index) > 0:
		index += 1
	return index


## Registra uma fase vencida: guarda a melhor nota e libera a próxima.
func finish_mission(stage: int = 0, stars: int = 1) -> void:
	stage = maxi(stage, 0)
	while stage_stars.size() <= stage:
		stage_stars.append(0)
	stage_stars[stage] = maxi(int(stage_stars[stage]), clampi(stars, 0, 3))
	missions_done += 1
	shop_seed = randi()
	shop_stock = {}
	save_game()


func save_game() -> bool:
	_dirty = false
	_since_change = 0.0
	if not save_enabled:
		return false
	var data := {
		"version": SAVE_VERSION,
		"hero_id": hero_id,
		"missions_done": missions_done,
		"stage_stars": stage_stars,
		"auto_attack": auto_attack,
		"auto_attack_on": auto_attack_on,
		"run_hero": run_hero,
		"perm_attributes": perm_attributes,
		"pets": pets,
		"active_pet": active_pet,
		"pet_levels": pet_levels,
		"evolutions": evolutions,
		"skill_tree": skill_tree,
		"skill_levels": skill_levels,
		"skill_loadout": skill_loadout,
		"ignored_types": ignored_types,
		"auto_fragment": auto_fragment,
		"pvp_wins": pvp_wins,
		"pvp_losses": pvp_losses,
		"hero_progress": hero_progress,
		"monster_kills": monster_kills,
		"run": run,
		"stage_index": stage_index,
		"inventory": inventory.to_dict(),
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true


func load_game() -> bool:
	if not save_enabled or not FileAccess.file_exists(save_path):
		return false
	# JSON.new().parse não imprime erro no console quando o arquivo está corrompido.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return false
	var parsed = json.data
	if not (parsed is Dictionary):
		return false
	var saved_hero := str(parsed.get("hero_id", hero_id))
	if Heroes.DATA.has(saved_hero):
		hero_id = saved_hero
	missions_done = maxi(0, int(parsed.get("missions_done", 0)))
	var saved_stars = parsed.get("stage_stars", [])
	stage_stars = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	auto_attack = false
	auto_attack_on = true
	reset_run()
	if saved_stars is Array:
		for i in saved_stars.size():
			while stage_stars.size() <= i:
				stage_stars.append(0)
			stage_stars[i] = clampi(int(saved_stars[i]), 0, 3)
	if saved_stars is Array and saved_stars.is_empty() and missions_done > 0:
		stage_stars[0] = 1
	auto_attack = bool(parsed.get("auto_attack", false))
	auto_attack_on = bool(parsed.get("auto_attack_on", true))
	reset_run()
	var saved_run = parsed.get("run", {})
	if saved_run is Dictionary and not saved_run.is_empty():
		run_hero = str(parsed.get("run_hero", ""))
		run = _clean_run(saved_run)
	perm_attributes = {}
	var saved_perm = parsed.get("perm_attributes", {})
	if saved_perm is Dictionary:
		for hero_key in saved_perm:
			if Heroes.DATA.has(str(hero_key)) and saved_perm[hero_key] is Dictionary:
				var points := {}
				for stat in saved_perm[hero_key]:
					points[str(stat)] = clampi(int(saved_perm[hero_key][stat]), 0, Player.MAX_ATTRIBUTE_POINTS)
				perm_attributes[str(hero_key)] = points
	hero_progress = {}
	var saved_progress = parsed.get("hero_progress", {})
	if saved_progress is Dictionary:
		for hero_key in saved_progress:
			if Heroes.DATA.has(str(hero_key)) and saved_progress[hero_key] is Dictionary:
				var entry: Dictionary = saved_progress[hero_key]
				hero_progress[str(hero_key)] = {
					"level": clampi(int(entry.get("level", 1)), 1, 100000),
					"xp": maxf(float(entry.get("xp", 0.0)), 0.0),
					"points": maxi(int(entry.get("points", 0)), 0),
					"earned": maxi(int(entry.get("earned", 0)), 0),
				}
	monster_kills = {}
	var saved_kills = parsed.get("monster_kills", {})
	if saved_kills is Dictionary:
		for kind_key in saved_kills:
			if EnemyTypes.DATA.has(str(kind_key)):
				monster_kills[str(kind_key)] = maxi(int(saved_kills[kind_key]), 0)
	pets = []
	var saved_pets = parsed.get("pets", [])
	if saved_pets is Array:
		for id in saved_pets:
			if Pets.is_valid(str(id)) and not pets.has(str(id)):
				pets.append(str(id))
	active_pet = str(parsed.get("active_pet", ""))
	pet_levels = {}
	evolutions = {}
	skill_tree = {}
	skill_levels = {}
	skill_loadout = {}
	ignored_types = []
	auto_fragment = [false, false, false, false, false]
	var saved_ignored = parsed.get("ignored_types", [])
	if saved_ignored is Array:
		for type_name in saved_ignored:
			if Item.SLOTS.has(str(type_name)) and not ignored_types.has(str(type_name)):
				ignored_types.append(str(type_name))
	var saved_auto = parsed.get("auto_fragment", [])
	if saved_auto is Array:
		for i in mini(saved_auto.size(), 5):
			auto_fragment[i] = bool(saved_auto[i])
	var saved_loadout = parsed.get("skill_loadout", {})
	if saved_loadout is Dictionary:
		for hero_key in saved_loadout:
			if Heroes.DATA.has(str(hero_key)) and saved_loadout[hero_key] is Array:
				skill_loadout[str(hero_key)] = saved_loadout[hero_key].map(func(entry) -> String: return str(entry))
	pvp_wins = maxi(int(parsed.get("pvp_wins", 0)), 0)
	pvp_losses = maxi(int(parsed.get("pvp_losses", 0)), 0)
	var saved_skill_levels = parsed.get("skill_levels", {})
	if saved_skill_levels is Dictionary:
		for hero_key in saved_skill_levels:
			if Heroes.DATA.has(str(hero_key)) and saved_skill_levels[hero_key] is Dictionary:
				var skill_map := {}
				for skill_id in saved_skill_levels[hero_key]:
					if Skills.exists(str(skill_id)):
						skill_map[str(skill_id)] = clampi(int(saved_skill_levels[hero_key][skill_id]), 0, Skills.MAX_LEVEL)
				skill_levels[str(hero_key)] = skill_map
	var saved_tree = parsed.get("skill_tree", {})
	if saved_tree is Dictionary:
		for hero_key in saved_tree:
			if SkillTree.TREES.has(str(hero_key)) and saved_tree[hero_key] is Dictionary:
				var levels := {}
				for node_id in saved_tree[hero_key]:
					if not SkillTree.node(str(hero_key), str(node_id)).is_empty():
						levels[str(node_id)] = clampi(int(saved_tree[hero_key][node_id]), 0, SkillTree.MAX_LEVEL)
				skill_tree[str(hero_key)] = levels
	var saved_evolutions = parsed.get("evolutions", {})
	if saved_evolutions is Dictionary:
		for hero_key in saved_evolutions:
			if Evolution.PATHS.has(str(hero_key)):
				evolutions[str(hero_key)] = clampi(int(saved_evolutions[hero_key]), 0, Evolution.TIERS)
	var saved_levels = parsed.get("pet_levels", {})
	if saved_levels is Dictionary:
		for id in pets:
			pet_levels[id] = maxi(int(saved_levels.get(id, 1)), 1)
	if not pets.has(active_pet):
		active_pet = ""
	grant_kill_pets()
	stage_index = maxi(int(parsed.get("stage_index", 0)), 0)
	if not is_stage_unlocked(stage_index):
		stage_index = 0
	var saved_inventory = parsed.get("inventory", {})
	if saved_inventory is Dictionary:
		inventory = Inventory.from_dict(saved_inventory)
		_bind_inventory()
	return true


func has_run_for(hero: String) -> bool:
	return not run.is_empty() and run_hero == hero


## Guarda a jornada depois de uma fase comum vencida.
func commit_run(hero: String, snapshot: Dictionary) -> void:
	run_hero = hero
	run = snapshot


## Vencer um chefe zera o que foi acumulado nas fases.
func reset_run() -> void:
	run_hero = ""
	run = {}


## Reconstrói a jornada salva com números inteiros (o JSON devolve tudo como float) e valores seguros.
func _clean_run(data: Dictionary) -> Dictionary:
	var cleaned := {
		"level": clampi(int(data.get("level", 1)), 1, 999),
		"xp": maxf(float(data.get("xp", 0.0)), 0.0),
		"xp_to_next": maxf(float(data.get("xp_to_next", 6.0)), 1.0),
		"attributes": {},
		"skill_attributes": {},
		"cards": {},
	}
	for group in ["attributes", "skill_attributes", "cards"]:
		var source = data.get(group, {})
		if source is Dictionary:
			for key in source:
				cleaned[group][str(key)] = clampi(int(source[key]), 0, 99)
	return cleaned


## Pontos permanentes do herói (cópia).
func perm_for(hero: String) -> Dictionary:
	return (perm_attributes.get(hero, {}) as Dictionary).duplicate()


func add_perm_point(hero: String, stat: String) -> void:
	var points: Dictionary = perm_attributes.get(hero, {})
	points[stat] = int(points.get(stat, 0)) + 1
	perm_attributes[hero] = points
	_mark_dirty()


## Dá o pet do chefe. Devolve true se era novo; o primeiro pet já fica ativo.
func grant_pet(id: String) -> bool:
	if not Pets.is_valid(id) or pets.has(id):
		return false
	pets.append(id)
	if active_pet == "":
		active_pet = id
	_mark_dirty()
	return true


## O jogador quer pegar este tipo de item dos drops? (botão Drop)
func wants_item(item: Item) -> bool:
	return not ignored_types.has(item.slot)


func set_type_ignored(type_name: String, ignored: bool) -> void:
	if ignored and not ignored_types.has(type_name):
		ignored_types.append(type_name)
	elif not ignored:
		ignored_types.erase(type_name)
	_mark_dirty()


func set_auto_fragment(rarity: int, on: bool) -> void:
	auto_fragment[clampi(rarity, 0, 4)] = on
	_mark_dirty()


func tree_levels(hero: String) -> Dictionary:
	return skill_tree.get(hero, {})


## Custo e validade de uma compra planejada na árvore (`pending`: id do nó -> níveis a somar).
## Devolve {"ok": bool, "cost": pontos, "levels": níveis resultantes}.
func plan_tree(hero: String, pending: Dictionary) -> Dictionary:
	var levels: Dictionary = tree_levels(hero).duplicate()
	var total := 0
	var ok := true
	for entry in SkillTree.nodes(hero):
		var add := int(pending.get(entry["id"], 0))
		for i in add:
			var level := int(levels.get(entry["id"], 0))
			if level >= SkillTree.MAX_LEVEL or not SkillTree.unlocked(hero, entry["id"], levels):
				ok = false
				break
			total += SkillTree.cost(entry, level)
			levels[entry["id"]] = level + 1
	return {"ok": ok, "cost": total, "levels": levels}


## Confirma as compras da árvore: gasta os pontos de habilidade do herói. Devolve false se não der.
func commit_tree(hero: String, pending: Dictionary) -> bool:
	var plan := plan_tree(hero, pending)
	var progress := progress_for(hero)
	if not plan["ok"] or int(plan["cost"]) > int(progress["points"]) or int(plan["cost"]) <= 0:
		return false
	skill_tree[hero] = plan["levels"]
	set_progress(hero, int(progress["level"]), float(progress["xp"]), int(progress["points"]) - int(plan["cost"]), int(progress["earned"]))
	return true


func evolution_tier(hero: String) -> int:
	return clampi(int(evolutions.get(hero, 0)), 0, Evolution.TIERS)


## Por que o herói ainda não pode evoluir ("" se já pode): nível, ouro ou pedras da lua.
func evolution_block(hero: String) -> String:
	var next := evolution_tier(hero) + 1
	if next > Evolution.TIERS:
		return "Evolução máxima"
	var need: Dictionary = Evolution.REQUIREMENTS[next - 1]
	if int(progress_for(hero)["level"]) < int(need["level"]):
		return "Precisa do nível %d" % need["level"]
	if inventory.gold < int(need["gold"]):
		return "Faltam %d de ouro" % (int(need["gold"]) - inventory.gold)
	if inventory.moonstone < int(need["moonstone"]):
		return "Faltam %d pedras da lua" % (int(need["moonstone"]) - inventory.moonstone)
	return ""


## Evolui o herói uma etapa, pagando ouro e pedras da lua. Devolve true se evoluiu.
func evolve_hero(hero: String) -> bool:
	if evolution_block(hero) != "":
		return false
	var need: Dictionary = Evolution.REQUIREMENTS[evolution_tier(hero)]
	inventory.gold -= int(need["gold"])
	inventory.moonstone -= int(need["moonstone"])
	evolutions[hero] = evolution_tier(hero) + 1
	inventory.changed.emit()
	_mark_dirty()
	return true


func pet_level(id: String) -> int:
	return maxi(int(pet_levels.get(id, 1)), 1)


## Atributos do pet ativo no nível dele (vazio sem pet ativo).
func active_pet_stats() -> Dictionary:
	return Pets.stats(active_pet, pet_level(active_pet)) if active_pet != "" else {}


## Escolhe o pet ativo ("" = nenhum). Só vale para pets que o jogador tem.
func set_active_pet(id: String) -> void:
	if id != "" and not pets.has(id):
		return
	active_pet = id
	_mark_dirty()


## Melhora o pet em um nível, pagando em ouro. Devolve false sem o pet, no nível máximo ou sem ouro.
func upgrade_pet(id: String) -> bool:
	if not pets.has(id):
		return false
	var level := pet_level(id)
	var cost := Pets.upgrade_cost(level)
	if inventory.gold < cost:
		return false
	inventory.gold -= cost
	inventory.changed.emit()
	pet_levels[id] = level + 1
	_mark_dirty()
	return true


## Passa para o próximo pet da coleção (e, depois do último, para nenhum).
func cycle_pet() -> void:
	if pets.is_empty():
		return
	var index := pets.find(active_pet)
	if index == pets.size() - 1:
		active_pet = ""
	else:
		active_pet = pets[index + 1]
	_mark_dirty()


## Nível, XP e pontos de habilidade do herói (valores padrão para quem ainda não jogou).
func progress_for(hero: String) -> Dictionary:
	var saved: Dictionary = hero_progress.get(hero, {})
	return {
		"level": int(saved.get("level", 1)),
		"xp": float(saved.get("xp", 0.0)),
		"points": int(saved.get("points", 0)),
		"earned": int(saved.get("earned", 0)),
	}


func set_progress(hero: String, level: int, xp: float, points: int, earned: int) -> void:
	hero_progress[hero] = {"level": maxi(level, 1), "xp": maxf(xp, 0.0), "points": maxi(points, 0), "earned": maxi(earned, 0)}
	_mark_dirty()


## Soma um abate ao catálogo. Devolve o índice do título conquistado agora (ou -1 se nenhum).
func record_kill(kind: String) -> int:
	var before := int(monster_kills.get(kind, 0))
	monster_kills[kind] = before + 1
	_mark_dirty()
	var tier_before := Achievements.tier_for(before)
	var tier_after := Achievements.tier_for(before + 1)
	var pet_id := Pets.for_kind(kind)
	if pet_id != "" and before + 1 >= Pets.KILLS_TO_UNLOCK and grant_pet(pet_id):
		unlocked_pet = pet_id
	return tier_after - 1 if tier_after > tier_before else -1


func kills_of(kind: String) -> int:
	return int(monster_kills.get(kind, 0))


## Entrega os pets dos monstros que já passaram de 1000 abates (saves antigos e testes).
func grant_kill_pets() -> void:
	for kind in monster_kills:
		var pet_id := Pets.for_kind(str(kind))
		if pet_id != "" and int(monster_kills[kind]) >= Pets.KILLS_TO_UNLOCK:
			grant_pet(pet_id)


## Abates que faltam para o pet de um monstro (0 se já foi conquistado).
func kills_left_for(pet_id: String) -> int:
	var kind := str(Pets.get_pet(pet_id).get("kind", ""))
	if kind == "":
		return 0
	return maxi(Pets.KILLS_TO_UNLOCK - kills_of(kind), 0)


## Nível (0 a 5) de uma habilidade ativa do herói.
func skill_level(hero: String, id: String) -> int:
	return clampi(int(skill_levels.get(hero, {}).get(id, 0)), 0, Skills.MAX_LEVEL)


## Sobe a habilidade um nível, gastando pontos de habilidade (1, 2, 3, 4 e 5 para os níveis 1 a 5).
func upgrade_skill(hero: String, id: String) -> bool:
	var level := skill_level(hero, id)
	if level >= Skills.MAX_LEVEL or not Skills.exists(id):
		return false
	var progress := progress_for(hero)
	var cost := Skills.upgrade_cost(level)
	if int(progress["points"]) < cost:
		return false
	set_progress(hero, int(progress["level"]), float(progress["xp"]), int(progress["points"]) - cost, int(progress["earned"]))
	if not skill_levels.has(hero):
		skill_levels[hero] = {}
	skill_levels[hero][id] = level + 1
	_mark_dirty()
	return true


## Habilidades equipadas do herói, uma por casa da barra. Valores inválidos (habilidade que não é do herói,
## repetida ou fora do lugar) voltam às iniciais daquela casa.
func loadout_for(hero: String) -> Array:
	var defaults := Heroes.default_entries(Heroes.get_hero(hero))
	var pool := Heroes.skill_pool(Heroes.get_hero(hero))
	var saved: Array = skill_loadout.get(hero, [])
	var result: Array = []
	for i in defaults.size():
		var id: String = saved[i] if i < saved.size() else defaults[i]["id"]
		if not pool.has(id) or result.has(id):
			id = defaults[i]["id"]
			if result.has(id):
				for candidate in pool:
					if not result.has(candidate) and not saved.has(candidate):
						id = candidate
						break
		result.append(id)
	return result


## Equipa `id` na casa `slot` (0 a n-1). Se ela já estava em outra casa, as duas trocam de lugar.
func equip_skill(hero: String, slot: int, id: String) -> bool:
	var pool := Heroes.skill_pool(Heroes.get_hero(hero))
	var current := loadout_for(hero)
	if slot < 0 or slot >= current.size() or not pool.has(id):
		return false
	var other := current.find(id)
	if other >= 0 and other != slot:
		current[other] = current[slot]
	current[slot] = id
	skill_loadout[hero] = current
	_mark_dirty()
	return true
