extends Node2D

## Partida: hordas, XP e níveis, habilidades, drops, HUD e fim de jogo.

const SPAWN_DISTANCE := 560.0
## Os monstros nascem pelo menos esta distância (px) antes da borda do mapa.
const SPAWN_EDGE_MARGIN := 320.0
const MENU_SCENE := "res://scenes/Main.tscn"
const CASTLE_SCENE := "res://scenes/Castle.tscn"
## Arena PvP: raio do campo de duelo e tempo máximo da luta (no fim, vence quem tem mais vida).
const ARENA_RADIUS := 640.0
const ARENA_TIME := 150.0
## A cada ATTRIBUTE_POPUP_EVERY níveis abre o popup de atributos permanentes (pausa o jogo) com
## ATTRIBUTE_POINTS_PER_POPUP pontos para gastar.
const ATTRIBUTE_POPUP_EVERY := 5
const ATTRIBUTE_POINTS_PER_POPUP := 3
## Todo nível dá uma melhoria automática; a cada CHOICE_EVERY níveis o jogador ainda pode escolher
## entre três, numa faixa que não pausa o jogo (câmera lenta enquanto está aberta).
const CHOICE_EVERY := 4
const CHOICE_TIME_SCALE := 0.3
## Abates em sequência (menos de COMBO_WINDOW segundos entre eles) aumentam o XP ganho.
const COMBO_WINDOW := 3.0
## Na fase de chefe, o chefe entra depois de tantos segundos. O herói só ataca pelo botão (segurando)
## até vencer o primeiro chefe; depois o ataque é automático (e o botão ataca na hora).
const BOSS_ENTRANCE_SECONDS := 3.0
## Mini chefe de cada fase: vida, tamanho e dano em relação ao monstro comum.
const MINIBOSS_HP := 16.0
const MINIBOSS_SIZE := 1.7
const MINIBOSS_DAMAGE := 1.9
const CLUSTER_SIZE := 420.0
## Com mais drops que isto no chão, o XP e o ouro novos entram direto (evita travar no fim de fases longas).
const MAX_PICKUPS := 120
## Separação dos inimigos: tamanho das células da grade e distância mínima (soma dos raios x este fator).
const SEPARATION_CELL := 48.0
const SEPARATION_SPACING := 1.7
## Alcance do dano refletido (px).
const REFLECT_RANGE := 160.0
## Defesa dos inimigos: base + por fase (reduz o dano, ver Enemy.DEFENSE_K).
const ENEMY_BASE_DEFENSE := 6.0
const ENEMY_DEFENSE_PER_STAGE := 4.0
## Faíscas de impacto vivas ao mesmo tempo (com muita ação, as demais ficam só nos números).
const MAX_SPARKS := 40
const SKILL_ARC_RADIUS := 172.0
const CAMERA_ZOOM := 1.4
## Distância da base da tela até o fim da coluna de slots de poção (logo acima das habilidades).
const QUICK_BAR_BOTTOM := 340.0
const COMBO_XP_STEP := 0.01
const COMBO_XP_MAX := 0.6
## A fase (ver Stages) define nome, duração, inimigos, eventos, chefe e recompensa. Depois do
## tempo da fase o spawn para, o chefe chega e a missão termina quando o último inimigo morrer.
const MISSION_CLEAR_DELAY := 0.6
## Largura da barra da missão. Com o quadro de status de 316 px à esquerda e o
## inventário de 270 px à direita, ela cabe sem encostar em nada a partir de 1280 px.
const MISSION_BAR_WIDTH := 330.0
## Cada carta de melhoria pode ser escolhida no máximo esta quantidade de vezes (ou o "max" dela;
## o Tiro múltiplo, por exemplo, vai só até +2 projéteis e quase não aparece).
const CARD_MAX_STACK := 5
const GOLD_CHANCE := 0.10
## Potes de cura espalhados no mapa (no lugar das poções que caíam dos monstros).
## Segundos entre o fim da batalha e a tela de vitória, para o jogador ver o que ganhou.
const END_REVIEW_SECONDS := 3.5
const JAR_START := 1
const JAR_MAX := 2
const JAR_INTERVAL := 30.0
const JAR_MIN_DISTANCE := 260.0
const JAR_MAX_DISTANCE := 620.0
const JAR_FORGET_DISTANCE := 1600.0
const ITEM_CHANCE := 0.04
## Materiais do ferreiro: pedra comum, pedra da lua rara e pergaminho de despertar raríssimo.
const STONE_CHANCE := 0.05
const MOONSTONE_CHANCE := 0.008
const SCROLL_CHANCE := 0.003
## Runas: uma espécie sorteada.
const RUNE_CHANCE := 0.012

var world: Node2D
var ground: GroundLayer
var decor: WorldDecor
var player: Player
var weapon: Weapon
var joystick: TouchJoystick
var status_frame: StatusFrame
var hp_bar: MedievalBar
var energy_bar: MedievalBar
var xp_bar: MedievalBar
var info_label: Label
var toast_label: Label
var choice_strip: ChoiceStrip
var attack_button: AttackButton
var next_button: Button
var camera: Camera2D
var hurt_overlay: ColorRect
var _shake := 0.0
var _shake_total := 0.01
var _shake_time := 0.0
var _hitstop_active := false
var combo_label: Label
var gameover_panel: PanelContainer
var gameover_label: Label
var victory_panel: PanelContainer
var victory_label: Label
var mission_bar: MedievalBar
var mission_label: Label
var inventory_window: InventoryWindow
var quick_bar: QuickBar
var bag_button: Button
var pause_button: Button
var auto_button: Button
var _jar_timer := 6.0
var _rune_rng := RandomNumberGenerator.new()
var _bag_was_full := false
var drop_button: Button
var drop_panel: DropPanel
var pause_panel: PanelContainer
var _leave_armed := false
var settings_panel: SettingsPanel
var loot_feed: LootFeed
var skill_buttons := {}
## Mira da última habilidade (direção unitária e distância); zero = automática.
var aim_dir := Vector2.ZERO
var aim_dist := 0.0
var aim_guide: AimGuide
var cooldowns := {}
var cooldown_scale := 1.0

var elapsed := 0.0
var kills := 0
var xp := 0.0
var level := 1
var xp_to_next := 6.0
## Pontos de habilidade (1 por nível) para a futura árvore de habilidades.
var skill_points := 0
var skill_points_earned := 0
var spawn_cooldown := 0.0
var pending_choices := 0
var pending_attribute_popups := 0
var attribute_popup: AttributePopup
var stamina_bar: MedievalBar
var pet: PetFollower
var stage: Dictionary
var stage_index := 0
var mission_name := ""
var mission_duration := 240.0
var mission_reward := 50
var boss: Enemy
## O rival do duelo na arena PvP (vazio nas missões normais).
var rival_enemy: Enemy
var boss_spawned := false
var boss_dead := false
var combo := 0
var best_combo := 0
var stars := 0
var first_clear := false
var _combo_time := 0.0
var _events_done: Array = []
var modal_open := false
var game_over := false
var spawning := true
var mission_complete := false
var _clear_time := 0.0
var _mission_bar_recolored := false
var upgrades: Array = []
var card_counts := {}
var _toast_tween: Tween


func _ready() -> void:
	stage_index = Session.stage_index
	stage = Stages.arena_stage() if Session.pvp else Stages.get_stage(stage_index)
	mission_name = stage["name"]
	mission_duration = stage["duration"]
	mission_reward = stage["reward"]
	first_clear = Session.stars_of(stage_index) == 0
	world = Node2D.new()
	# Ordena por Y: o herói e os inimigos passam na frente ou atrás das árvores.
	world.y_sort_enabled = true
	world.modulate = stage["tint"]
	add_child(world)
	var border := MapBorder.new()
	if Session.pvp:
		border.radius = ARENA_RADIUS
	world.add_child(border)

	ground = GroundLayer.new()
	world.add_child(ground)

	player = Player.new()
	player.hero_id = Session.hero_id
	# O inventário é o mesmo do castelo: o que se ganha na missão fica com o herói.
	player.inventory = Session.inventory
	world.add_child(player)
	ground.follow = player

	decor = WorldDecor.new()
	decor.world = world
	decor.follow = player
	add_child(decor)

	weapon = Weapon.new()
	player.add_child(weapon)
	aim_guide = AimGuide.new()
	world.add_child(aim_guide)
	weapon.configure(player, world)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	# Mais perto: o herói e os monstros ficam maiores na tela.
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	player.add_child(camera)

	_build_vignette()
	_build_hud()
	player.joystick = joystick
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.pickup_collected.connect(_on_pickup_collected)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.gold_stolen.connect(_on_gold_stolen)
	EventBus.thief_escaped.connect(_on_thief_escaped)
	EventBus.gold_recovered.connect(_on_gold_recovered)
	EventBus.treasure_dropped.connect(_on_treasure_dropped)
	EventBus.boss_died.connect(_on_boss_died)
	EventBus.monster_defeated.connect(_on_monster_defeated)
	EventBus.impact.connect(_on_impact)
	player.hit_taken.connect(_on_player_hit)
	player.dodged.connect(func() -> void: _on_damage_dealt(0.0, player.global_position + Vector2(0, -20), "dodge"))
	_toast("%s" % mission_name, Brand.GOLD)

	_on_player_health_changed(player.health, player.max_health)
	upgrades = _build_upgrades()
	_load_progress()
	_apply_permanent()

	_apply_auto_attack()
	if Session.pvp:
		_start_duel()
	else:
		_spawn_start_jars()
	_rune_rng.randomize()
	xp_bar.max_value = xp_to_next
	_update_hud()


func _process(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	_tick_combo(delta)
	if Session.pvp:
		_tick_duel(delta)
	else:
		_tick_jars(delta)
	_update_bag_warning()
	_update_shake(delta)
	weapon.manual_held = attack_button.held or Input.is_key_pressed(KEY_SPACE)
	attack_button.cooldown = weapon.cooldown_ratio()
	if Stages.is_boss_stage(stage) and spawning and not boss_spawned and elapsed >= BOSS_ENTRANCE_SECONDS:
		_start_boss_phase()
	if spawning and elapsed >= mission_duration:
		spawning = false
		if not boss_spawned:
			_start_final_phase()
	if spawning:
		_tick_events()
		spawn_cooldown -= delta
		if spawn_cooldown <= 0.0:
			spawn_cooldown = Stages.spawn_interval(stage, elapsed)
			_spawn_group()
	else:
		_check_mission_end(delta)
	for id in cooldowns:
		cooldowns[id] = max(0.0, cooldowns[id] - delta)
		var button: SkillButton = skill_buttons[id]
		button.set_cooldown(cooldowns[id], Skills.cooldown_for(id, self))
		button.set_energy_ok(player.energy >= Skills.cost_for(id))
	_update_hud()


## Progresso da missão, de 0 a 1, pelo tempo de spawn.
func mission_progress() -> float:
	return clampf(elapsed / mission_duration, 0.0, 1.0)


func enemies_left() -> int:
	return get_tree().get_node_count_in_group("enemies")


## Depois que o spawn para, a missão acaba quando não restar nenhum inimigo.
## A espera curta evita contar o instante em que uma gosma acabou de se dividir.
func _check_mission_end(delta: float) -> void:
	if mission_complete:
		return
	if not boss_spawned or enemies_left() > 0:
		_clear_time = 0.0
		return
	_clear_time += delta
	if _clear_time >= MISSION_CLEAR_DELAY:
		_on_mission_complete(false)


# --- Eventos da fase: hordas, elites e o chefe -------------------------------

## Dispara os eventos da fase quando chega a hora de cada um.
func _tick_events() -> void:
	var events: Array = stage["events"]
	for i in events.size():
		if _events_done.has(i):
			continue
		if elapsed >= float(events[i][0]) * mission_duration:
			_events_done.append(i)
			_run_event(String(events[i][1]))


func _run_event(event: String) -> void:
	var kinds := Stages.unlocked_kinds(stage, elapsed)
	match event:
		"horde":
			var count := 8 + stage_index * 2
			var base := randf() * TAU
			_toast("Horda se aproximando!", Color("ff7a4a"))
			for i in count:
				var angle := base + (float(i) / float(count) - 0.5) * 1.1
				_spawn_one(EnemyTypes.pick(0.0, kinds), player.global_position + Vector2.from_angle(angle) * (SPAWN_DISTANCE - 30.0 + randf() * 50.0))
		"elite":
			var kind := EnemyTypes.pick(0.0, kinds)
			var elite := _spawn_one(kind, player.global_position + Vector2.from_angle(randf() * TAU) * SPAWN_DISTANCE)
			elite.promote("elite")
			_toast("Elite: %s!" % EnemyTypes.get_type(kind)["name"], Color("ffd24a"))
		"miniboss":
			# O mini chefe é o monstro mais encorpado da fase, gigante, com muito mais vida e dano.
			var heavy: Array = kinds.duplicate()
			heavy.sort_custom(func(a: String, b: String) -> bool:
				return EnemyTypes.DATA[a]["health"] * EnemyTypes.DATA[a]["radius"] > EnemyTypes.DATA[b]["health"] * EnemyTypes.DATA[b]["radius"])
			var pool := heavy.slice(0, mini(3, heavy.size()))
			var kind: String = pool[randi() % pool.size()]
			var mini_boss := _spawn_one(kind, player.global_position + Vector2.from_angle(randf() * TAU) * SPAWN_DISTANCE)
			var title := "%s Gigante" % EnemyTypes.get_type(kind)["name"]
			mini_boss.promote("miniboss", MINIBOSS_HP, MINIBOSS_SIZE, MINIBOSS_DAMAGE, title)
			_toast("Mini chefe: %s!" % title, Color("ff8a3a"))


## Fase de chefe: o chefe entra logo no começo (os mímicos acordam) e a fase acaba quando ele morre.
func _start_boss_phase() -> void:
	var data: Dictionary = stage["boss"]
	boss = _spawn_one(data["kind"], player.global_position + Vector2.from_angle(randf() * TAU) * (SPAWN_DISTANCE - 60.0))
	if boss != null:
		boss.promote("boss", data["hp"], data["scale"], data["damage"], data["name"])
	boss_spawned = true
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).wake_up()
	_toast("CHEFE: %s!" % data["name"], Color("ff5a3c"))


## Fim de uma fase comum: uma última horda, os mímicos acordam e só falta eliminar todo mundo.
func _start_final_phase() -> void:
	boss_spawned = true
	_run_event("horde")
	for node in get_tree().get_nodes_in_group("enemies"):
		(node as Enemy).wake_up()
	_toast("Última horda! Elimine todos os monstros", Brand.GOLD)


func _on_boss_died(boss_name: String) -> void:
	boss_dead = true
	_toast("%s derrotado!" % boss_name, Brand.GOLD)
	var pet_id := Pets.for_stage(String(stage["id"]))
	if pet_id != "" and Session.grant_pet(pet_id):
		var pet_data := Pets.get_pet(pet_id)
		_toast("Pet conquistado: %s! %s" % [pet_data["name"], Pets.stats_text(pet_id, 1)], pet_data["color"])
		loot_feed.add_line("Novo pet: %s" % pet_data["name"], pet_data["color"])
		player.pet_stats = Session.active_pet_stats()
		player.refresh_stats()
		_spawn_pet()
	if not Session.auto_attack:
		Session.auto_attack = true
		Session.auto_attack_on = true
		_apply_auto_attack()
		loot_feed.add_line("Ataque automático liberado!", Color("7ee08a"))
	if Stages.is_boss_stage(stage):
		# Com o chefe caído, os servos dele caem junto.
		spawning = false
		for node in get_tree().get_nodes_in_group("enemies"):
			(node as Enemy).take_damage(1e9, "dot")


## Missão cumprida. Com `immediate` (os testes), mostra a tela de vitória na hora; no jogo, o herói tem
## alguns segundos para ver tudo o que foi para ele (os espólios do chão, o XP, o nível e as escolhas de
## atributo) antes da tela de vitória.
func _on_mission_complete(immediate := true) -> void:
	if Session.pvp:
		_on_duel_won()
		return
	mission_complete = true
	Engine.time_scale = 1.0
	if immediate:
		game_over = true
	var ground := _ground_summary()
	_collect_ground_drops()
	player.inventory.add_gold(mission_reward)
	var ratio := player.health / maxf(player.max_health, 1.0)
	stars = Stages.stars(stage, true, kills, ratio)
	var unlocked_next: bool = Session.stars_of(stage_index) == 0
	if first_clear:
		var bonus := Item.roll(player.get_luck(), level + stage_index * 6, 3 if Stages.is_boss_stage(stage) else 2)
		player.inventory.add_item(bonus)
	# As melhorias de escolha (cartas) valem só nesta partida: ao sair, morrer ou ir para outra fase elas
	# se perdem. O nível, os atributos, o pet e o resto continuam.
	var journey := "\nAs melhorias de escolha desta partida acabam aqui (o nível continua)"
	Session.finish_mission(stage_index, stars)
	victory_label.text = "%s superada!\n%s\nTempo: %s · Abates: %d (meta %d)\nMaior combo: x%d · Nível: %d\nOuro: %d (bônus de %d)%s%s%s" % [
		mission_name, "Estrelas: %d/3" % stars, _format_time(), kills, stage["kill_goal"], best_combo, level,
		player.inventory.gold, mission_reward,
		"\nItem raro de primeira vitória!" if first_clear else "",
		"\nNova fase liberada!" if unlocked_next else "", journey]
	next_button.visible = unlocked_or_next()
	if immediate:
		_show_victory()
		return
	_toast("Missão cumprida! %s" % ground, Brand.GOLD)
	loot_feed.add_line("Espólios do chão recolhidos", Color("7ee08a"))
	_review_then_show_victory()


## O que está no chão e vai para o herói, em uma frase curta ("+12 ouro, 3 itens").
func _ground_summary() -> String:
	var gold := 0
	var items := 0
	var others := 0
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup := node as Pickup
		if pickup == null or pickup.is_collected():
			continue
		match pickup.kind:
			"gold":
				gold += int(pickup.payload)
			"item":
				items += 1
			"xp":
				pass
			_:
				others += 1
	var parts := PackedStringArray()
	if gold > 0:
		parts.append("+%d ouro" % gold)
	if items > 0:
		parts.append("%d itens" % items)
	if others > 0:
		parts.append("%d materiais" % others)
	return ", ".join(parts) if not parts.is_empty() else "tudo recolhido"


## Espera alguns segundos (e as telas de escolha de nível terminarem) e só então mostra a vitória.
func _review_then_show_victory() -> void:
	await get_tree().create_timer(END_REVIEW_SECONDS, true).timeout
	var waited := 0.0
	while not game_over and (modal_open or pending_attribute_popups > 0 or choice_strip.is_open()):
		await get_tree().create_timer(0.25, true).timeout
		waited += 0.25
		if waited > 20.0 and not modal_open:
			break
	if not game_over:
		_show_victory()


func _show_victory() -> void:
	game_over = true
	choice_strip.hide()
	victory_panel.show()
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			_try_cast_index(0)
		KEY_2:
			_try_cast_index(1)
		KEY_3:
			_try_cast_index(2)
		KEY_4:
			_try_cast_index(3)
		KEY_Q:
			_use_consumable("potion")
		KEY_5:
			choice_strip.pick(0)
		KEY_6:
			choice_strip.pick(1)
		KEY_7:
			choice_strip.pick(2)
		KEY_I, KEY_B:
			toggle_inventory()
		KEY_ESCAPE:
			if is_pause_open():
				close_pause_menu()
			elif inventory_window.is_open():
				inventory_window.close()
			else:
				open_pause_menu()


func _try_cast_index(index: int) -> void:
	var entries := Heroes.skill_entries(player.hero)
	if index < entries.size():
		try_cast(entries[index]["id"])


## Nível a partir do qual a habilidade fica disponível (0 = desde o início).
## Fase em que a habilidade é liberada: a 1ª fase fica sem nenhuma; a 2ª libera a primeira, a 3ª a
## segunda e assim por diante. A habilidade do nível 20 só depende do nível.
func unlock_stage_of(id: String) -> int:
	var position := 0
	for entry in Heroes.skill_entries(player.hero):
		if entry["unlock_level"] > 0:
			continue
		position += 1
		if entry["id"] == id:
			return position
	return 0


func unlock_level_of(id: String) -> int:
	for entry in Heroes.skill_entries(player.hero):
		if entry["id"] == id:
			return entry["unlock_level"]
	return 0


func is_unlocked(id: String) -> bool:
	return level >= unlock_level_of(id) and stage_index + 1 > unlock_stage_of(id)


## Dispara uma habilidade se estiver liberada, fora de recarga e com energia.
func try_cast(id: String, aim := Vector2.ZERO, aim_distance := 0.0) -> bool:
	if game_over or modal_open or not is_unlocked(id) or cooldowns.get(id, 0.0) > 0.0:
		return false
	if not player.spend_energy(Skills.cost_for(id)):
		return false
	cooldowns[id] = Skills.cooldown_for(id, self)
	# A mira vale também para a repetição (x2) da habilidade; o próximo disparo a troca.
	aim_dir = aim
	aim_dist = aim_distance
	Skills.activate(id, self)
	return true


## Alcance máximo de uma habilidade mirada, em pixels do mundo.
func aim_range_of(id: String) -> float:
	return (520.0 if id == "fire" or id == "fire_arrows" else 620.0) * player.skill_range_mult()


## O jogador arrasta o botão de uma habilidade com mira: mostra a linha no mundo.
func _on_skill_aim_changed(id: String, offset: Vector2, active: bool) -> void:
	if not active or offset.length() < 1.0:
		aim_guide.clear()
		return
	var distance := lerpf(0.3, 1.0, clampf(offset.length() / SkillButton.AIM_DRAG_MAX, 0.0, 1.0)) * aim_range_of(id)
	aim_guide.aim(player.global_position, offset.normalized(), distance, Skills.def(id)["color"])


## O jogador soltou o botão depois de mirar: dispara na direção e distância escolhidas.
func _on_skill_aim_cast(id: String, offset: Vector2) -> void:
	aim_guide.clear()
	var distance := lerpf(0.3, 1.0, clampf(offset.length() / SkillButton.AIM_DRAG_MAX, 0.0, 1.0)) * aim_range_of(id)
	try_cast(id, offset.normalized(), distance)


func _use_consumable(id: String) -> void:
	if not game_over and not modal_open and player.inventory.use_consumable(id, player):
		_on_consumable_used(id)


func _on_consumable_used(id: String) -> void:
	var data := Consumables.def(id)
	_toast(data["name"], data["color"])


# --- Inimigos e drops -------------------------------------------------------

## Um grupo de inimigos de um tipo liberado na fase, respeitando o limite de inimigos vivos do momento.
func _spawn_group() -> void:
	var cap := Stages.max_enemies(stage, elapsed)
	var alive := enemies_left()
	if alive >= cap:
		return
	var kind := EnemyTypes.pick(0.0, Stages.unlocked_kinds(stage, elapsed))
	var count := mini(EnemyTypes.pack_size(kind), cap - alive)
	var base := _emptiest_angle()
	for i in count:
		# O bando se abre em leque, cada um numa distância um pouco diferente.
		var angle := base + (float(i) - (count - 1) * 0.5) * 0.5
		var distance := SPAWN_DISTANCE + randf_range(-30.0, 40.0)
		_spawn_one(kind, player.global_position + Vector2.from_angle(angle) * distance)


## O lado da tela com menos inimigos por perto: os novos nascem onde há mais espaço, em vez de
## se amontoar onde os outros já estão.
func _emptiest_angle() -> float:
	var inside := Player.MAP_RADIUS - SPAWN_EDGE_MARGIN
	var to_center := (-player.global_position).angle() if player.global_position.length() > 1.0 else randf() * TAU
	var best_angle := to_center
	var best_count := 1 << 30
	var enemies := get_tree().get_nodes_in_group("enemies")
	for i in 8:
		var angle := randf() * TAU
		var spot := player.global_position + Vector2.from_angle(angle) * SPAWN_DISTANCE
		# Nada de nascer perto da borda do mapa: só valem lados que ficam dentro da área segura.
		if spot.length() > inside:
			continue
		var crowd := 0
		for node in enemies:
			if (node as Node2D).global_position.distance_squared_to(spot) < 280.0 * 280.0:
				crowd += 1
		if crowd < best_count:
			best_count = crowd
			best_angle = angle
	return best_angle


## Mantido para quem chama um inimigo avulso (testes e ferramentas).
func _spawn_enemy() -> void:
	_spawn_group()


## Os inimigos não se empilham: os que ficam colados se afastam, deixando um espaço entre as caixas de
## acerto. Chefes e mini chefes empurram os outros mais do que são empurrados.
func _physics_process(_delta: float) -> void:
	if game_over:
		return
	_separate_enemies()
	# A segunda passada (mais firme) roda em quadros alternados: o resultado é o mesmo, com metade do custo.
	if Engine.get_physics_frames() % 2 == 0:
		_separate_enemies()


func _separate_enemies() -> void:
	var enemies: Array = []
	var grid := {}
	for node in Enemy.alive(get_tree()):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.kind == "totem":
			continue
		enemies.append(enemy)
		var cell := Vector2i((enemy.position / SEPARATION_CELL).floor())
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(enemy)
	if enemies.size() < 2:
		return
	for enemy in enemies:
		var cell := Vector2i((enemy.position / SEPARATION_CELL).floor())
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var neighbors: Array = grid.get(cell + Vector2i(dx, dy), [])
				for other in neighbors:
					if other.get_instance_id() <= enemy.get_instance_id():
						continue
					var offset: Vector2 = other.position - enemy.position
					var wanted: float = (enemy.radius + other.radius) * SEPARATION_SPACING
					var squared := offset.length_squared()
					if squared >= wanted * wanted:
						continue
					var distance := sqrt(squared)
					var direction := offset / distance if distance > 0.01 else Vector2.from_angle(randf() * TAU)
					var push := (wanted - distance) * 0.5
					var weight_a := 4.0 if (enemy.is_boss or enemy.is_mini) else 1.0
					var weight_b := 4.0 if (other.is_boss or other.is_mini) else 1.0
					var share_a := weight_b / (weight_a + weight_b)
					enemy.position -= direction * push * 2.0 * share_a
					other.position += direction * push * 2.0 * (1.0 - share_a)


func _spawn_one(kind: String, at: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.target = player
	enemy.setup(kind, elapsed, Stages.hp_scale(stage, elapsed), Stages.damage_scale(stage, elapsed))
	enemy.defense = (ENEMY_BASE_DEFENSE + stage_index * ENEMY_DEFENSE_PER_STAGE) * Stages.easiness(stage_index)
	enemy.dodge_chance = Stages.enemy_dodge(enemy.dodge_chance, stage_index)
	world.add_child(enemy)
	enemy.global_position = at.limit_length(Player.MAP_RADIUS - SPAWN_EDGE_MARGIN)
	return enemy


func _on_enemy_killed(at_position: Vector2, xp_value: int, loot: bool) -> void:
	kills += 1
	Sound.play("pop")
	_register_kill()
	if xp_value > 0:
		_spawn_pickup("xp", maxi(1, int(round(xp_value * Tuning.glob("xp")))), at_position)
	if not loot:
		return
	var luck := player.get_luck()
	var drop_mult := player.get_drop_mult()
	var rolls := 1 + (1 if randf() < 0.05 * luck else 0)
	for i in rolls:
		if randf() < Tuning.drop("gold", GOLD_CHANCE) * drop_mult:
			var amount := maxi(1, int(round(randi_range(1, 2) * (1.0 + 0.05 * minf(luck, 20.0)) * Tuning.glob("gold"))))
			_spawn_pickup("gold", amount, at_position)
		if randf() < Tuning.drop("stone", STONE_CHANCE) * drop_mult:
			_spawn_pickup("stone", 1, at_position)
		if randf() < Tuning.drop("moonstone", MOONSTONE_CHANCE) * drop_mult:
			_spawn_pickup("moonstone", 1, at_position)
		if randf() < Tuning.drop("rune", RUNE_CHANCE) * drop_mult:
			_spawn_pickup("rune", Runes.roll(_rune_rng), at_position)
		if randf() < Tuning.drop("scroll", SCROLL_CHANCE) * drop_mult:
			_spawn_pickup("scroll", 1, at_position)
		if randf() < Tuning.drop("item", ITEM_CHANCE) * drop_mult:
			_spawn_pickup("item", Item.roll(luck, level), at_position)


func _spawn_pickup(kind: String, payload: Variant, at_position: Vector2) -> void:
	if (kind == "xp" or kind == "gold") and get_tree().get_node_count_in_group("pickups") >= MAX_PICKUPS:
		EventBus.pickup_collected.emit(kind, payload)
		return
	var pickup := Pickup.new()
	pickup.kind = kind
	pickup.payload = payload
	pickup.target = player
	world.add_child(pickup)
	pickup.global_position = at_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	pickup.pop()


## Quando a partida acaba, tudo o que está no chão vai direto para o herói, inclusive o XP solto. Na vitória o XP
## entra com as telas de nível (escolhas); ao morrer ou sair entra em silêncio.
func _collect_ground_drops() -> void:
	var quiet_xp := 0.0
	var loud := not game_over
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup := node as Pickup
		if pickup == null or pickup.is_collected():
			continue
		var unwanted: bool = pickup.kind == "item" and pickup.payload is Item and not Session.wants_item(pickup.payload)
		if pickup.kind == "xp":
			quiet_xp += float(pickup.payload) * player.get_xp_mult() * combo_multiplier() * (1.0 + stage_index * 0.3)
			pickup.queue_free()
			continue
		if not unwanted:
			pickup.collect_now()
		else:
			pickup.queue_free()
	if quiet_xp > 0.0:
		if loud:
			_gain_xp(quiet_xp)
		else:
			_gain_xp_quiet(quiet_xp)


func _on_pickup_collected(kind: String, payload: Variant) -> void:
	match kind:
		"xp":
			_gain_xp(float(payload) * player.get_xp_mult() * combo_multiplier() * (1.0 + stage_index * 0.3))
		"gold":
			player.inventory.add_gold(int(payload))
			loot_feed.add_gold(int(payload))
			Sound.play("coin")
		"stone", "moonstone", "scroll", "key":
			player.inventory.add_material(kind, int(payload))
			var names := {"stone": "Pedra", "moonstone": "Pedra da lua", "scroll": "Pergaminho de despertar", "key": "Chave de espaço"}
			var colors := {"stone": Color("c9cfd6"), "moonstone": Color("9fd0ff"), "scroll": Color("d9a8ff"), "key": Color("ffd24a")}
			loot_feed.add_line("+ %s" % names[kind], colors[kind])
			if kind != "stone":
				Sound.play("coin")
		"rune":
			var rune_id: String = str(payload)
			player.inventory.add_rune(rune_id)
			loot_feed.add_line("+ %s" % Runes.DATA[rune_id]["name"], Runes.DATA[rune_id]["color"])
			Sound.play("coin")
		"potion":
			player.inventory.add_potion()
			loot_feed.add_line("+ Poção de vida", Color("e0452d"))
		"item":
			var item: Item = payload
			if not Session.wants_item(item):
				return
			if Session.auto_fragment[item.rarity]:
				var amount := item.fragment_value()
				player.inventory.add_fragments(item.rarity, amount)
				loot_feed.add_line("+ %d fragmentos %s" % [amount, item.rarity_name().to_lower()], item.color())
			elif player.inventory.add_item(item):
				loot_feed.add_item(item)
				if item.rarity >= 2:
					_toast("%s (%s)" % [item.item_name, item.rarity_name()], item.color())
			else:
				_toast("Mochila cheia: %s vendido" % item.item_name, Brand.GOLD)


# --- Combo, tesouros e ladrões ----------------------------------------------

func combo_multiplier() -> float:
	return 1.0 + minf(combo * COMBO_XP_STEP, COMBO_XP_MAX)


func _register_kill() -> void:
	combo += 1
	best_combo = maxi(best_combo, combo)
	_combo_time = COMBO_WINDOW
	if combo % 25 == 0:
		loot_feed.add_line("Combo x%d!" % combo, Color("ffb02e"))


func _tick_combo(delta: float) -> void:
	if combo > 0:
		_combo_time -= delta
		if _combo_time <= 0.0:
			combo = 0


func _on_gold_stolen(amount: int) -> void:
	if amount > 0:
		_toast("O ladrão roubou %d de ouro! Mate-o!" % amount, Color("ff7a6a"))
	else:
		_toast("Um ladrão tentou roubar você, mas não havia ouro.", Brand.PARCHMENT)


func _on_thief_escaped(amount: int) -> void:
	if amount > 0:
		_toast("O ladrão fugiu com %d de ouro..." % amount, Color("ff7a6a"))


## O ladrão morreu com o ouro: ele volta em moedas pelo chão, com juros.
func _on_gold_recovered(at_position: Vector2, amount: int) -> void:
	var pieces := clampi(amount / 5, 1, 8)
	for i in pieces:
		_spawn_pickup("gold", maxi(amount / pieces, 1), at_position)
	_toast("Ouro recuperado: %d!" % amount, Brand.GOLD)


## Elites, chefes e mímicos soltam equipamento (com raridade mínima), ouro e materiais do ferreiro:
## mini chefes e chefes soltam pedras da lua e pergaminhos de despertar.
func _on_treasure_dropped(at_position: Vector2, count: int, min_rarity: int) -> void:
	for i in count:
		_spawn_pickup("item", Item.roll(player.get_luck(), level + stage_index * 6, min_rarity), at_position)
	for i in mini(1 + count, 4):
		_spawn_pickup("gold", randi_range(1, 2) + stage_index / 3, at_position)
	for i in count:
		_spawn_pickup("stone", 1, at_position)
	for i in (1 if min_rarity < 2 else (3 if count >= 4 else 2)):
		_spawn_pickup("rune", Runes.roll(_rune_rng, 0 if min_rarity < 2 else (2 if count >= 4 else 1)), at_position)
	if min_rarity >= 2:
		var boss_drop: bool = count >= 4
		for i in (4 if boss_drop else 2):
			_spawn_pickup("moonstone", 1, at_position)
		if randf() < (0.6 if boss_drop else 0.1):
			_spawn_pickup("key", 1, at_position)
		if boss_drop or randf() < 0.35:
			_spawn_pickup("scroll", 1, at_position)


# --- Níveis, melhorias automáticas e escolha rápida -------------------------

func _gain_xp(amount: float) -> void:
	var previous_level := level
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		skill_points += Progression.SKILL_POINTS_PER_LEVEL
		skill_points_earned += Progression.SKILL_POINTS_PER_LEVEL
		xp_to_next = Progression.xp_needed(level)
		_on_level_up()
	xp_bar.max_value = xp_to_next
	_announce_unlocks(previous_level)
	_save_progress()
	_update_hud()


## Cada nível dá uma melhoria sozinha (o jogo não para). Pontos de atributo e de habilidade vêm
## distribuídos pelo foco do herói, e a cada CHOICE_EVERY níveis abre a escolha rápida.
func _on_level_up() -> void:
	Sound.play("level")
	var option := _auto_upgrade()
	var gained := "Nível %d!" % level
	if not option.is_empty():
		gained += "  %s: %s" % [option["name"], option["desc"]]
	loot_feed.add_line(gained + "  (+%d ponto de habilidade)" % Progression.SKILL_POINTS_PER_LEVEL, Color("7ee08a"))
	var ring := RingEffect.new()
	ring.radius = 70.0
	ring.color = Color("7ee08a")
	ring.duration = 0.45
	world.add_child(ring)
	ring.global_position = player.global_position
	if level % ATTRIBUTE_POPUP_EVERY == 0:
		pending_attribute_popups += 1
	if level % CHOICE_EVERY == 0:
		pending_choices += 1
		_open_choice()
	_try_open_attribute_popup()


## Abre o popup de atributos permanentes quando há um pendente e nada mais está aberto (a escolha
## rápida e as janelas vão primeiro; ele vem logo depois).
func _try_open_attribute_popup() -> void:
	if pending_attribute_popups > 0 and not _attribute_can_grow():
		pending_attribute_popups = 0
	if pending_attribute_popups <= 0 or modal_open or game_over or choice_strip.is_open():
		return
	pending_attribute_popups -= 1
	modal_open = true
	attack_button.release()
	attribute_popup.open(player, ATTRIBUTE_POINTS_PER_POPUP, level)
	get_tree().paused = true


func _on_attribute_point(stat: String) -> void:
	Session.add_perm_point(player.hero_id, stat)
	loot_feed.add_line("Atributo permanente: %s" % Pets.STAT_NAMES.get(stat, stat), Color("b8c9a0"))


func _on_attribute_popup_closed() -> void:
	_close_modal()


## Avisa quando o herói chega ao nível que libera uma habilidade.
func _announce_unlocks(previous_level: int) -> void:
	for entry in Heroes.skill_entries(player.hero):
		var required: int = entry["unlock_level"]
		if required > 0 and previous_level < required and level >= required:
			_toast("Habilidade liberada: %s!" % Skills.def(entry["id"])["name"], Skills.def(entry["id"])["color"])


## Melhorias que o herói pode receber agora (a arma serve e a carta ainda não está no limite).
func _upgrade_pool() -> Array:
	return upgrades.filter(func(option: Dictionary) -> bool:
		var allowed: bool = option["kinds"].is_empty() or option["kinds"].has(weapon.kind)
		return allowed and card_counts.get(option["name"], 0) < int(option.get("max", CARD_MAX_STACK)))


func _apply_upgrade(option: Dictionary) -> void:
	option["apply"].call()
	card_counts[option["name"]] = card_counts.get(option["name"], 0) + 1


## Sorteia e aplica uma melhoria, dando mais chance às de dano e de velocidade de ataque.
func _auto_upgrade() -> Dictionary:
	var pool := _upgrade_pool()
	if pool.is_empty():
		return {}
	var total := 0.0
	for option in pool:
		total += float(option.get("weight", 1.0))
	var roll := randf() * total
	var picked: Dictionary = pool[0]
	for option in pool:
		roll -= float(option.get("weight", 1.0))
		if roll <= 0.0:
			picked = option
			break
	_apply_upgrade(picked)
	return picked


## Abre a escolha rápida (três melhorias) sem pausar: o jogo fica em câmera lenta enquanto ela está aberta.
func _open_choice() -> void:
	if choice_strip.is_open() or pending_choices <= 0 or game_over:
		return
	var pool := _upgrade_pool()
	if pool.is_empty():
		pending_choices = 0
		return
	pending_choices -= 1
	pool.shuffle()
	var options := pool.slice(0, 3)
	# A sugestão é a primeira melhoria de dano ou de ritmo; senão, a primeira.
	var recommended := 0
	for i in options.size():
		if float(options[i].get("weight", 1.0)) > 1.0:
			recommended = i
			break
	choice_strip.open(options, recommended)
	Engine.time_scale = CHOICE_TIME_SCALE


func _on_choice_made(option: Dictionary) -> void:
	_apply_upgrade(option)
	loot_feed.add_line("Escolha: %s" % option["name"], Color("ffe9a8"))
	Engine.time_scale = 1.0
	if pending_choices > 0:
		_open_choice()
	_try_open_attribute_popup()


## Abre ou fecha a mochila. Abre pausando o jogo, como as outras janelas.
func toggle_inventory() -> void:
	if inventory_window.is_open():
		inventory_window.close()
		return
	if game_over or modal_open:
		return
	modal_open = true
	attack_button.release()
	inventory_window.open()
	get_tree().paused = true


func _on_inventory_closed() -> void:
	_close_modal()


func _on_damage_dealt(amount: float, at_position: Vector2, kind: String) -> void:
	if world == null or (amount < 0.5 and kind != "dodge" and kind != "miss"):
		return
	if Settings.damage_numbers:
		var number := DamageNumber.new()
		world.add_child(number)
		number.setup(int(round(amount)), at_position, kind)
	Sound.play(kind)
	var steal := player.get_lifesteal()
	if steal > 0.0 and amount > 0.0 and (kind == "hit" or kind == "crit" or kind == "skill" or kind == "block"):
		player.heal(minf(amount * steal, player.max_health * Player.LIFESTEAL_HIT_CAP))
	if kind != "dodge" and kind != "miss" and get_tree().get_node_count_in_group("sparks") < MAX_SPARKS:
		var spark := HitSpark.new()
		world.add_child(spark)
		spark.setup(at_position + Vector2(0, -6), kind)
	if kind == "crit":
		_on_impact(3.5, 0.035)


## Abre a janela de filtro dos drops (pausa o jogo, como as outras janelas).
func open_drop_panel() -> void:
	if game_over or modal_open:
		return
	modal_open = true
	attack_button.release()
	drop_panel = DropPanel.new()
	drop_panel.closed.connect(func() -> void:
		drop_panel.queue_free()
		_close_modal())
	pause_button.get_parent().add_child(drop_panel)
	get_tree().paused = true


# --- Ataque automático: ligar e desligar --------------------------------------

## O automático só existe depois do primeiro chefe; com ele liberado, o jogador liga e desliga como quiser.
func _apply_auto_attack() -> void:
	var on: bool = Session.auto_attack and Session.auto_attack_on
	weapon.auto_enabled = on
	attack_button.set_auto_state(Session.auto_attack, on)
	if auto_button != null:
		if not Session.auto_attack:
			auto_button.text = "Auto: 1º chefe"
			auto_button.disabled = true
		else:
			auto_button.text = "AUTO: LIGADO" if on else "AUTO: DESLIGADO"
			auto_button.disabled = false
			auto_button.modulate = Color("9fe8a8") if on else Color("ffb0a0")


func toggle_auto_attack() -> void:
	if not Session.auto_attack:
		_toast("O ataque automático é liberado ao derrotar o primeiro chefe", Brand.GOLD)
		return
	Session.auto_attack_on = not Session.auto_attack_on
	_apply_auto_attack()
	_toast("Ataque automático %s" % ("ligado" if Session.auto_attack_on else "desligado"), Color("7ee08a") if Session.auto_attack_on else Color("ffb0a0"))
	Session.save_game()


# --- Potes de cura e aviso de mochila cheia --------------------------------------

## Espalha os primeiros potes ao redor do herói.
func _spawn_start_jars() -> void:
	for i in JAR_START:
		_spawn_jar(randf_range(JAR_MIN_DISTANCE * 0.7, JAR_MAX_DISTANCE * 0.8))


func _spawn_jar(distance: float) -> void:
	var jar := HealJar.new()
	jar.target = player
	jar.collected.connect(_on_jar_collected)
	world.add_child(jar)
	jar.global_position = (player.global_position + Vector2.from_angle(randf() * TAU) * distance).limit_length(Player.MAP_RADIUS - 80.0)


func _on_jar_collected() -> void:
	Sound.play("coin")
	_toast("Pote de cura: +%d%% de vida" % int(HealJar.HEAL_FRACTION * 100.0), Color("7ee08a"))
	loot_feed.add_line("+ %d%% de vida" % int(HealJar.HEAL_FRACTION * 100.0), Color("7ee08a"))


## Novos potes aparecem de tempos em tempos longe do herói, e os que ficaram para trás somem.
func _tick_jars(delta: float) -> void:
	_jar_timer -= delta
	if _jar_timer > 0.0:
		return
	_jar_timer = JAR_INTERVAL * randf_range(0.8, 1.25)
	var jars := get_tree().get_nodes_in_group("jars")
	for node in jars:
		if (node as Node2D).global_position.distance_to(player.global_position) > JAR_FORGET_DISTANCE:
			node.queue_free()
			jars.erase(node)
	if jars.size() < JAR_MAX:
		_spawn_jar(randf_range(JAR_MIN_DISTANCE, JAR_MAX_DISTANCE))


## Avisa quando a mochila enche (e fica avisando no botão): o que cair depois é vendido na hora.
func _update_bag_warning() -> void:
	var inventory := player.inventory
	var full := inventory.bag.size() >= inventory.bag_capacity
	if full and not _bag_was_full:
		_toast("MOCHILA CHEIA! Os próximos itens serão vendidos", Color("ff7a6a"))
		loot_feed.add_line("Mochila cheia!", Color("ff7a6a"))
		Sound.play("hurt")
	_bag_was_full = full
	if bag_button != null:
		bag_button.text = "Mochila CHEIA!" if full else "Mochila"
		bag_button.modulate = Color(1.0, 0.55 + 0.25 * sin(elapsed * 6.0), 0.5) if full else Color.WHITE


## XP do chão ao fim da fase: entra direto, sem abrir as telas de escolha.
func _gain_xp_quiet(amount: float) -> void:
	if amount <= 0.0:
		return
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		skill_points += Progression.SKILL_POINTS_PER_LEVEL
		skill_points_earned += Progression.SKILL_POINTS_PER_LEVEL
		xp_to_next = Progression.xp_needed(level)
	_save_progress()


# --- Pausa: continuar, configurações e sair da partida -----------------------

func _build_pause_menu(parent: CanvasLayer) -> void:
	pause_panel = Brand.make_wood_panel(16, Color(Brand.WOOD, 0.98))
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.hide()
	parent.add_child(pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(360, 0)
	pause_panel.add_child(box)
	box.add_child(Ribbon.new("PAUSA", 40))
	var resume := Brand.make_wood_button("Continuar", Vector2(0, 54), 20)
	resume.pressed.connect(close_pause_menu)
	box.add_child(resume)
	var settings := Brand.make_wood_button("Configurações", Vector2(0, 54), 20)
	settings.pressed.connect(_open_settings_from_pause)
	box.add_child(settings)
	var leave := Brand.make_wood_button("Sair da partida", Vector2(0, 54), 20)
	leave.name = "LeaveButton"
	leave.pressed.connect(_on_leave_pressed.bind(leave))
	box.add_child(leave)


func is_pause_open() -> bool:
	return pause_panel != null and pause_panel.visible


## Pausa o jogo e mostra o menu de pausa (não abre sobre outras janelas).
func open_pause_menu() -> void:
	if game_over or modal_open or is_pause_open():
		return
	modal_open = true
	_leave_armed = false
	pause_panel.find_child("LeaveButton", true, false).text = "Sair da partida"
	attack_button.release()
	pause_panel.show()
	get_tree().paused = true


func close_pause_menu() -> void:
	if not is_pause_open():
		return
	pause_panel.hide()
	_close_modal()


func _open_settings_from_pause() -> void:
	pause_panel.hide()
	settings_panel = SettingsPanel.new()
	settings_panel.closed.connect(func() -> void:
		settings_panel.queue_free()
		pause_panel.show())
	pause_button.get_parent().add_child(settings_panel)


## Sair pede um segundo toque. Sai para o castelo sem vencer a fase: o nível e os itens já pegos ficam,
## e o que está no chão vai para o herói.
func _on_leave_pressed(button: Button) -> void:
	if not _leave_armed:
		_leave_armed = true
		button.text = "Toque de novo para sair"
		return
	_collect_ground_drops()
	_save_progress()
	_leave_to(CASTLE_SCENE)


# --- Efeitos de impacto: tremor de tela, pausa curta e flash de dano --------

## Tremor (em pixels) e hit-stop (segundos reais). Vale sempre o maior tremor em andamento.
func _on_impact(shake_strength: float, hitstop_seconds: float) -> void:
	shake(shake_strength, 0.22 + shake_strength * 0.012)
	if shake_strength >= 10.0:
		Sound.play("boom")
	_hitstop(hitstop_seconds)


func shake(strength: float, seconds: float) -> void:
	if not Settings.screen_shake:
		return
	if strength >= _shake * (_shake_time / _shake_total if _shake_total > 0.0 else 0.0):
		_shake = strength
		_shake_total = maxf(seconds, 0.05)
		_shake_time = _shake_total


func _update_shake(delta: float) -> void:
	if camera == null:
		return
	if _shake_time <= 0.0:
		camera.offset = Vector2.ZERO
		return
	_shake_time -= delta
	var strength := _shake * clampf(_shake_time / _shake_total, 0.0, 1.0)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength


## Congela o jogo por um instante, o bastante para o golpe "pesar". Não mexe com a escolha rápida
## (que já usa câmera lenta) nem com as janelas pausadas.
func _hitstop(seconds: float) -> void:
	if seconds <= 0.0 or _hitstop_active or choice_strip.is_open() or get_tree().paused:
		return
	_hitstop_active = true
	Engine.time_scale = 0.06
	await get_tree().create_timer(seconds, true, false, true).timeout
	_hitstop_active = false
	if is_inside_tree() and not choice_strip.is_open():
		Engine.time_scale = 1.0


func _on_player_hit(damage: float) -> void:
	_reflect_damage(damage)
	Sound.play("hurt")
	hurt_overlay.color.a = clampf(0.16 + damage / maxf(player.max_health, 1.0) * 1.2, 0.16, 0.5)
	create_tween().tween_property(hurt_overlay, "color:a", 0.0, 0.32)
	_on_impact(clampf(2.0 + damage * 0.18, 2.0, 9.0), 0.0)

func _close_modal() -> void:
	modal_open = false
	get_tree().paused = false
	_try_open_attribute_popup()



func _build_upgrades() -> Array:
	return [
		{"name": "Lâmina afiada", "desc": "+40% de dano", "weight": 2.5, "kinds": [], "apply": func(): weapon.damage *= 1.4},
		{"name": "Gatilho rápido", "desc": "22% menos tempo entre ataques", "weight": 2.0, "kinds": [], "apply": func(): weapon.fire_interval *= 0.78},
		{"name": "Mira longa", "desc": "+30% de alcance", "kinds": ["magic", "arrow", "blunderbuss"], "apply": func(): weapon.base_range *= 1.3},
		{"name": "Golpe amplo", "desc": "+30% de área do golpe", "kinds": ["melee"], "apply": func(): weapon.base_range *= 1.3},
		{"name": "Tiro múltiplo", "desc": "+1 projétil por disparo", "weight": 0.3, "max": 2, "kinds": ["magic", "arrow", "blunderbuss"], "apply": func(): weapon.projectile_count += 1},
		{"name": "Vitalidade", "desc": "+45 de vida máxima e cura", "kinds": [], "apply": func(): player.raise_max_health(45.0)},
		{"name": "Botas leves", "desc": "+18% de velocidade", "kinds": [], "apply": func(): player.card_speed_mult *= 1.18},
		{"name": "Foco", "desc": "Habilidades recarregam 18% mais rápido", "kinds": [], "apply": func(): cooldown_scale *= 0.82},
		{"name": "Mira firme", "desc": "+9% de acerto nos golpes", "weight": 1.2, "kinds": [], "apply": func(): player.accuracy_bonus += 0.09},
		{"name": "Olho de águia", "desc": "+12% de chance de crítico", "weight": 1.3, "kinds": [], "apply": func(): player.card_crit += 0.12},
		{"name": "Golpe letal", "desc": "+40% de dano nos críticos", "kinds": [], "apply": func(): player.card_crit_mult += 0.4},
		{"name": "Ímã de loot", "desc": "+45% de alcance para pegar drops", "kinds": [], "apply": func(): player.pickup_radius *= 1.45},
	]


# --- Fim de jogo ------------------------------------------------------------

func _on_player_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_bar.label_text = "%d / %d" % [int(ceil(current)), int(maximum)]


func _on_player_died() -> void:
	if Session.pvp:
		_on_duel_lost()
		return
	game_over = true
	_collect_ground_drops()
	Session.save_game()
	choice_strip.hide()
	Engine.time_scale = 1.0
	gameover_label.text = "%s caiu em %s\nTempo: %s\nAbates: %d\nNível: %d\nOuro: %d" % [
		player.hero["name"], mission_name, _format_time(), kills, level, player.inventory.gold]
	gameover_panel.show()
	get_tree().paused = true


# --- Arena PvP -------------------------------------------------------------------------------

## Começa o duelo: o rival (um herói controlado pela IA) nasce do lado oposto da arena.
func _start_duel() -> void:
	spawning = false
	boss_spawned = true
	var rival := Enemy.new()
	rival.setup_rival(Session.pvp_rival, player, Session.pvp_difficulty, ARENA_RADIUS)
	world.add_child(rival)
	rival.global_position = player.global_position + Vector2(ARENA_RADIUS * 0.55, 0.0)
	# A barra da missão vira a vida do rival (a mesma que o chefe usa).
	boss = rival
	rival_enemy = rival
	player.global_position = Vector2(-ARENA_RADIUS * 0.55, 0.0)
	rival.global_position = Vector2(ARENA_RADIUS * 0.55, 0.0)
	var setting: Dictionary = RivalBrain.DIFFICULTY.get(Session.pvp_difficulty, RivalBrain.DIFFICULTY["normal"])
	_toast("DUELO: %s (%s)" % [Heroes.get_hero(Session.pvp_rival)["name"], setting["name"]], Color("ff5a3c"))


## Prende os dois lutadores dentro da arena e decide o duelo se o tempo acabar (vence quem tem mais vida).
func _tick_duel(_delta: float) -> void:
	player.global_position = player.global_position.limit_length(ARENA_RADIUS)
	if is_instance_valid(rival_enemy) and not rival_enemy.is_queued_for_deletion():
		rival_enemy.global_position = rival_enemy.global_position.limit_length(ARENA_RADIUS)
	if elapsed >= ARENA_TIME and not game_over and not mission_complete and is_instance_valid(rival_enemy):
		var player_ratio := player.health / maxf(player.max_health, 1.0)
		var rival_ratio := rival_enemy.health / maxf(rival_enemy.max_health, 1.0)
		if player_ratio > rival_ratio:
			rival_enemy.take_damage(1e9, "dot")
		else:
			player.take_damage(player.max_health * 10.0, "dot")


## Vitória no duelo: ouro pela dificuldade e pelo nível, e o placar sobe.
func _on_duel_won() -> void:
	mission_complete = true
	game_over = true
	Engine.time_scale = 1.0
	var setting: Dictionary = RivalBrain.DIFFICULTY.get(Session.pvp_difficulty, RivalBrain.DIFFICULTY["normal"])
	var reward := int(round((100.0 + level * 8.0) * float(setting["reward"])))
	player.inventory.add_gold(reward)
	Session.pvp_wins += 1
	Session.save_game()
	var ratio := int(round(player.health / maxf(player.max_health, 1.0) * 100.0))
	victory_label.text = "Vitória na arena!\nContra: %s (%s)\nTempo: %s · Vida restante: %d%%\nOuro: +%d\nPlacar: %d vitórias · %d derrotas" % [
		Heroes.get_hero(Session.pvp_rival)["name"], setting["name"], _format_time(), ratio, reward, Session.pvp_wins, Session.pvp_losses]
	next_button.visible = false
	_show_victory()


func _on_duel_lost() -> void:
	game_over = true
	Engine.time_scale = 1.0
	Session.pvp_losses += 1
	Session.save_game()
	choice_strip.hide()
	var setting: Dictionary = RivalBrain.DIFFICULTY.get(Session.pvp_difficulty, RivalBrain.DIFFICULTY["normal"])
	var rival_ratio := 0
	if is_instance_valid(rival_enemy):
		rival_ratio = int(round(rival_enemy.health / maxf(rival_enemy.max_health, 1.0) * 100.0))
	gameover_label.text = "Derrota na arena\nContra: %s (%s)\nTempo: %s · o rival ficou com %d%% da vida\nPlacar: %d vitórias · %d derrotas\n(Use \"Jogar novamente\" para a revanche)" % [
		Heroes.get_hero(Session.pvp_rival)["name"], setting["name"], _format_time(), rival_ratio, Session.pvp_wins, Session.pvp_losses]
	gameover_panel.show()
	get_tree().paused = true


# --- HUD --------------------------------------------------------------------

## Escurece de leve as bordas da tela, dando profundidade e foco no herói.
func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.0, 0.05, 0.02, 0.0), Color(0.0, 0.05, 0.02, 0.5)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	var overlay := TextureRect.new()
	overlay.texture = texture
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	hurt_overlay = ColorRect.new()
	hurt_overlay.color = Color(0.85, 0.05, 0.05, 0.0)
	hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hurt_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(hurt_overlay)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	joystick = TouchJoystick.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(joystick)

	var top := VBoxContainer.new()
	top.position = Vector2(12, 12)
	top.add_theme_constant_override("separation", 6)
	hud.add_child(top)
	status_frame = StatusFrame.new()
	status_frame.setup_hero(player.hero)
	status_frame.set_title(player.hero["name"], level)
	hp_bar = status_frame.hp_bar
	energy_bar = status_frame.energy_bar
	xp_bar = status_frame.xp_bar
	stamina_bar = status_frame.stamina_bar
	top.add_child(status_frame)
	info_label = Brand.make_label("", 17, Color("ffe9a8"))
	info_label.add_theme_color_override("font_outline_color", Color("120a05"))
	info_label.add_theme_constant_override("outline_size", 5)
	top.add_child(info_label)

	# Barra da missão, no centro da área livre (à esquerda do inventário).
	var mission := VBoxContainer.new()
	mission.set_anchors_preset(Control.PRESET_CENTER_TOP)
	mission.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mission.offset_left = -MISSION_BAR_WIDTH * 0.5
	mission.offset_right = MISSION_BAR_WIDTH * 0.5
	mission.offset_top = 12.0
	mission.add_theme_constant_override("separation", 3)
	hud.add_child(mission)
	mission_label = Brand.make_label("Missão: %s" % mission_name, 18, Color("ffe9a8"))
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_color_override("font_outline_color", Color("120a05"))
	mission_label.add_theme_constant_override("outline_size", 5)
	mission.add_child(mission_label)
	mission_bar = MedievalBar.new(24.0, MISSION_BAR_WIDTH)
	mission_bar.max_value = 1.0
	mission_bar.fill_top = Color("7fc65a")
	mission_bar.fill_bottom = Color("3f8a34")
	mission.add_child(mission_bar)

	toast_label = Brand.make_label("", 24, Brand.GOLD)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -300.0
	toast_label.offset_right = 300.0
	toast_label.offset_top = 84.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_outline_color", Brand.NIGHT)
	toast_label.add_theme_constant_override("outline_size", 6)
	toast_label.modulate.a = 0.0
	hud.add_child(toast_label)

	# Canto direito, no estilo dos jogos de ação: botão de ataque grande e as habilidades em arco.
	var cluster := Control.new()
	cluster.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cluster.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cluster.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cluster.custom_minimum_size = Vector2(CLUSTER_SIZE, CLUSTER_SIZE)
	cluster.offset_left = -CLUSTER_SIZE - 8.0
	cluster.offset_top = -CLUSTER_SIZE - 8.0
	cluster.offset_right = -8.0
	cluster.offset_bottom = -8.0
	cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(cluster)
	var attack_center := Vector2(CLUSTER_SIZE - 98.0, CLUSTER_SIZE - 98.0)
	attack_button = AttackButton.new()
	attack_button.position = attack_center - attack_button.size * 0.5
	cluster.add_child(attack_button)
	var entries := Heroes.skill_entries(player.hero)
	for i in entries.size():
		var id: String = entries[i]["id"]
		var button := SkillButton.new()
		button.setup(id, str(i + 1), entries[i]["unlock_level"], unlock_stage_of(id))
		button.cast_requested.connect(func(skill_id: String) -> void: try_cast(skill_id))
		button.aim_changed.connect(_on_skill_aim_changed)
		button.aim_cast_requested.connect(_on_skill_aim_cast)
		# Em arco, da esquerda do botão de ataque até logo acima dele.
		var t := float(i) / float(maxi(entries.size() - 1, 1))
		var angle := PI + 0.06 + t * (PI * 0.5 - 0.12)
		button.position = attack_center + Vector2.from_angle(angle) * SKILL_ARC_RADIUS - Vector2(SkillButton.SIZE, SkillButton.SIZE) * 0.5
		cluster.add_child(button)
		skill_buttons[id] = button
		cooldowns[id] = 0.0

	# Slots de poção e comida: coluna na direita, logo acima das habilidades.
	quick_bar = QuickBar.new()
	quick_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	quick_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	quick_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	quick_bar.offset_right = -14.0
	quick_bar.offset_bottom = -QUICK_BAR_BOTTOM
	hud.add_child(quick_bar)
	quick_bar.bind(player.inventory)
	quick_bar.consumable_requested.connect(_use_consumable)
	bag_button = Brand.make_wood_button("Mochila", Vector2(124, 52), 17)
	bag_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bag_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bag_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bag_button.offset_bottom = -14.0
	bag_button.pressed.connect(toggle_inventory)
	hud.add_child(bag_button)
	drop_button = Brand.make_wood_button("Drop", Vector2(100, 52), 17)
	drop_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	drop_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	drop_button.offset_left = -(62.0 + 10.0 + 100.0)
	drop_button.offset_right = -(62.0 + 10.0)
	drop_button.offset_bottom = -14.0
	drop_button.pressed.connect(open_drop_panel)
	hud.add_child(drop_button)

	pause_button = Brand.make_wood_button("II", Vector2(52, 44), 18)
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pause_button.offset_top = 12.0
	pause_button.offset_right = -12.0
	pause_button.pressed.connect(open_pause_menu)
	hud.add_child(pause_button)
	auto_button = Brand.make_wood_button("Auto: 1º chefe", Vector2(150, 38), 14)
	auto_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	auto_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	auto_button.offset_top = 64.0
	auto_button.offset_right = -12.0
	auto_button.pressed.connect(toggle_auto_attack)
	hud.add_child(auto_button)
	_build_pause_menu(hud)

	loot_feed = LootFeed.new()
	loot_feed.position = Vector2(14, 190)
	hud.add_child(loot_feed)

	inventory_window = InventoryWindow.new()
	hud.add_child(inventory_window)
	inventory_window.bind(player)
	inventory_window.consumable_used.connect(_on_consumable_used)
	inventory_window.closed.connect(_on_inventory_closed)

	attribute_popup = AttributePopup.new()
	hud.add_child(attribute_popup)
	attribute_popup.point_added.connect(_on_attribute_point)
	attribute_popup.closed.connect(_on_attribute_popup_closed)

	choice_strip = ChoiceStrip.new()
	choice_strip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	choice_strip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	choice_strip.offset_top = 128.0
	hud.add_child(choice_strip)
	choice_strip.chosen.connect(_on_choice_made)

	gameover_panel = _make_centered_panel(hud)
	gameover_label = _fill_end_panel(gameover_panel)
	victory_panel = _make_centered_panel(hud)
	victory_label = _fill_end_panel(victory_panel)
	next_button = Brand.make_button("Próxima fase")
	next_button.pressed.connect(go_to_next_stage)
	victory_panel.get_child(0).add_child(next_button)
	victory_panel.get_child(0).move_child(next_button, 1)


## Texto de resultado e botões: voltar ao castelo (onde fica o mercado),
## jogar de novo e voltar ao menu.
func _fill_end_panel(panel: PanelContainer) -> Label:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var label := Brand.make_label("", 22)
	box.add_child(label)
	var castle := Brand.make_button("Voltar ao castelo")
	castle.pressed.connect(func() -> void: _leave_to(CASTLE_SCENE))
	box.add_child(castle)
	var again := Brand.make_button("Jogar novamente")
	again.pressed.connect(func() -> void:
		Session.save_game()
		get_tree().paused = false
		get_tree().reload_current_scene())
	box.add_child(again)
	var menu := Brand.make_button("Voltar ao menu")
	menu.pressed.connect(func() -> void: _leave_to(MENU_SCENE))
	box.add_child(menu)
	return label


## Botão da tela de vitória: segue direto para a fase seguinte, que a vitória acabou de liberar.
func go_to_next_stage() -> void:
	if stage_index + 1 >= Stages.count() or not Session.is_stage_unlocked(stage_index + 1):
		return
	Session.stage_index = stage_index + 1
	Session.save_game()
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func _leave_to(scene: String) -> void:
	Engine.time_scale = 1.0
	Session.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)


func _make_centered_panel(parent: CanvasLayer) -> PanelContainer:
	var panel := Brand.make_panel()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	parent.add_child(panel)
	return panel


func _toast(text: String, color: Color) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_label, "modulate:a", 1.0, 0.1)
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)


func _update_hud() -> void:
	xp_bar.value = xp
	xp_bar.label_text = "XP %d / %d  (faltam %d)" % [int(xp), int(ceil(xp_to_next)), int(ceil(xp_to_next - xp))]
	energy_bar.max_value = player.get_max_energy()
	energy_bar.value = player.energy
	energy_bar.label_text = "%d / %d" % [int(player.energy), int(player.get_max_energy())]
	status_frame.set_title(player.hero["name"], level)
	stamina_bar.max_value = player.get_max_stamina()
	stamina_bar.value = player.stamina
	stamina_bar.label_text = "Vitalidade" if player.fatigue_factor() >= 1.0 else "Cansado: %d%% de velocidade" % int(round(player.fatigue_factor() * 100.0))
	info_label.text = "Abates %d (meta %d)" % [kills, stage["kill_goal"]]
	if Session.pvp:
		info_label.text = "Duelo na arena · tempo %s · vitórias %d / derrotas %d" % [_format_clock(ARENA_TIME - elapsed), Session.pvp_wins, Session.pvp_losses]
	if combo >= 3:
		info_label.text += "  ·  COMBO x%d  (+%d%% XP)" % [combo, int(round((combo_multiplier() - 1.0) * 100.0))]
	for id in skill_buttons:
		skill_buttons[id].set_locked(not is_unlocked(id))
	if boss_spawned and is_instance_valid(boss) and not boss.is_queued_for_deletion():
		# Durante o chefe, a barra da missão vira a vida dele.
		if not _mission_bar_recolored:
			_mission_bar_recolored = true
			mission_bar.fill_top = Color("e0452d")
			mission_bar.fill_bottom = Color("8a1f16")
		mission_bar.max_value = boss.max_health
		mission_bar.value = boss.health
		mission_bar.label_text = "%s · %d / %d" % [boss.display_name, int(ceil(boss.health)), int(boss.max_health)]
		return
	mission_bar.max_value = 1.0
	mission_bar.value = mission_progress()
	if spawning:
		mission_bar.label_text = "O chefe está chegando..." if Stages.is_boss_stage(stage) else "Sobreviva · faltam %s" % _format_clock(mission_duration - elapsed)
	else:
		mission_bar.label_text = "Elimine os %d inimigos restantes" % enemies_left()


func _format_time() -> String:
	return _clock_text(int(elapsed))


## Tempo que falta, arredondado para cima para não mostrar 00:00 antes da hora.
func _format_clock(total_seconds: float) -> String:
	return _clock_text(int(ceil(maxf(total_seconds, 0.0))))


func _clock_text(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


## A escolha rápida deixa o relógio do jogo em câmera lenta; nunca o leva para a próxima tela.
func _exit_tree() -> void:
	Engine.time_scale = 1.0


## Há uma fase seguinte e ela já está liberada (a vitória acabou de liberar).
func unlocked_or_next() -> bool:
	return stage_index + 1 < Stages.count() and Session.is_stage_unlocked(stage_index + 1)


# --- Jornada acumulada entre as fases ---------------------------------------

## O que o herói acumulou: nível, XP, atributos e as melhorias (contagem por carta).
func snapshot_run() -> Dictionary:
	return {
		"cards": card_counts.duplicate(),
	}


## Atributos permanentes do herói e atributos do pet ativo: valem em toda fase, sempre.
func _apply_permanent() -> void:
	var perm := Session.perm_for(player.hero_id)
	for stat in perm:
		if player.attributes.has(stat):
			player.attributes[stat] = int(perm[stat])
	player.pet_stats = Session.active_pet_stats()
	player.evolution_bonus = Evolution.bonus(player.hero_id, Session.evolution_tier(player.hero_id))
	player.tree_bonus = SkillTree.bonus(player.hero_id, Session.tree_levels(player.hero_id))
	player.skill_levels = Session.skill_levels.get(player.hero_id, {}).duplicate()
	player.refresh_stats()
	player.health = player.max_health
	player.stamina = player.get_max_stamina()
	_spawn_pet()


func _spawn_pet() -> void:
	if is_instance_valid(pet):
		pet.queue_free()
		pet = null
	if Pets.is_valid(Session.active_pet):
		pet = PetFollower.new()
		world.add_child(pet)
		pet.setup(Session.active_pet, player)


## Começa a fase com o que a jornada já tinha: o nível e as melhorias continuam (as melhorias são
## aplicadas de novo: arma, vida, velocidade, crítico...). Sem jornada deste herói, começa do zero.
func _restore_run() -> void:
	if not Session.has_run_for(player.hero_id):
		return
	var saved: Dictionary = Session.run
	for option in upgrades:
		var times := int(saved["cards"].get(option["name"], 0))
		for i in times:
			option["apply"].call()
		if times > 0:
			card_counts[option["name"]] = times
	player.refresh_stats()
	player.health = player.max_health
	player.energy = player.get_max_energy()
	player.health_changed.emit(player.health, player.max_health)
	status_frame.set_title(player.hero["name"], level)
	loot_feed.add_line("Melhorias da jornada mantidas", Color("b8c9a0"))


# --- Nível acumulativo ------------------------------------------------------

## O nível, o XP e os pontos de habilidade do herói vêm do Session e nunca zeram.
func _load_progress() -> void:
	var saved := Session.progress_for(player.hero_id)
	level = int(saved["level"])
	xp = float(saved["xp"])
	skill_points = int(saved["points"])
	skill_points_earned = int(saved["earned"])
	xp_to_next = Progression.xp_needed(level)
	xp_bar.max_value = xp_to_next
	status_frame.set_title(player.hero["name"], level)


func _save_progress() -> void:
	Session.set_progress(player.hero_id, level, xp, skill_points, skill_points_earned)


func _attribute_can_grow() -> bool:
	for entry in AttributePopup.STATS:
		if player.can_add_point("hero", entry["id"]):
			return true
	return false


func _on_monster_defeated(kind: String) -> void:
	var tier := Session.record_kill(kind)
	if Session.unlocked_pet != "":
		var new_pet := Pets.get_pet(Session.unlocked_pet)
		_toast("Pet conquistado: %s! %s" % [new_pet["name"], Pets.stats_text(Session.unlocked_pet)], new_pet["color"])
		loot_feed.add_line("Novo pet: %s" % new_pet["name"], new_pet["color"])
		Sound.play("level")
		Session.unlocked_pet = ""
		if not is_instance_valid(pet) and Session.active_pet != "":
			player.pet_stats = Session.active_pet_stats()
			player.refresh_stats()
			_spawn_pet()
	if tier >= 0:
		_toast("Conquista: %s! (%d abates)" % [Achievements.title_for(kind, tier), Achievements.TIERS[tier]["kills"]], Color("ffd24a"))
		loot_feed.add_line("Conquista: %s" % Achievements.title_for(kind, tier), Color("ffd24a"))
		Sound.play("level")


## Refletir: parte do dano que o herói levou volta ao inimigo mais próximo (num raio curto).
func _reflect_damage(damage: float) -> void:
	var reflect := player.get_reflect()
	if reflect <= 0.0:
		return
	var nearest: Enemy = null
	var best := REFLECT_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var distance := enemy.global_position.distance_to(player.global_position)
		if distance < best:
			best = distance
			nearest = enemy
	if nearest != null:
		nearest.take_damage(damage * reflect, "dot")
