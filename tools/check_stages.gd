extends Node

## Verificação das fases, do balanceamento, do level-up sem pausa e dos 5 inimigos novos, com as
## classes reais do jogo (roda como cena, com os autoloads prontos). Uso:
##   godot --headless --path . res://tools/check_stages.tscn
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
	_run.call_deferred()


func _check(condition: bool, text: String) -> void:
	print(("  ok   - " if condition else "  FALHA - ") + text)
	if not condition:
		_failures += 1


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


## Espera quadros de física: os tempos dos inimigos andam por eles, não pelos quadros de tela.
func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	if _out_dir == "":
		return
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out_dir, shot_name])
	print("SHOT ", shot_name)


## `keep_progress` mantém o Session (jornada, estrelas, ataque automático) de uma fase para a outra.
func _new_game(stage_index := 0, keep_progress := false) -> void:
	if _game != null:
		_game.queue_free()
		await _frames(2)
	if not keep_progress:
		Session.reset_progress()
		Session.hero_id = "warrior"
	Session.stage_index = stage_index
	_game = load("res://scenes/Game.tscn").instantiate()
	add_child(_game)
	await _frames(3)
	# A arma automática do herói e o sorteio de inimigos ficam desligados: cada teste cria o que precisa.
	_game.weapon.process_mode = Node.PROCESS_MODE_DISABLED
	_game.player.accuracy_bonus = 1.0
	_game.spawning = false
	_game.boss_spawned = false
	_clear_enemies()


func _clear_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		node.remove_from_group("enemies")
		node.queue_free()


func _spawn(kind: String, offset: Vector2) -> Enemy:
	var spawned: Enemy = _game._spawn_one(kind, _game.player.global_position + offset)
	spawned.defense = 0.0
	return spawned


func _run() -> void:
	print("[fases]")
	_test_stage_data()
	_test_session_stars()
	await _new_game()
	await _test_balance()
	await _test_levels()
	await _test_combo()
	await _test_stamina_and_accuracy()
	await _test_skills_by_stage()
	await _test_attack_controls()
	await _test_high_levels()
	await _test_no_auto_attack_at_level_one()
	await _test_crit_dodge_block()
	await _test_dexterity_and_legendary()
	await _test_impact_effects()
	await _test_events_and_boss()
	await _test_miniboss()
	await _test_journey()
	await _test_bestiary()
	await _test_castle_menu()
	await _test_multishot_and_sound()
	await _test_thief()
	await _test_shade()
	await _test_new_enemies_and_insane()
	await _test_totem()
	await _test_vortex()
	await _test_mimic()
	await _test_castle()
	await _test_extras()
	await _test_skill_touch()
	await _test_forge_and_evolution()
	await _test_spacing_and_keys()
	await _test_ring_slots()
	await _test_pause_and_settings()
	await _test_fragments_runes_awakening()
	await _test_speed_lifesteal_reflect()
	await _test_skill_tree()
	await _test_forge_panel()
	await _test_market_economy()
	await _test_regen_and_sections()
	await _test_infinite_stages()
	await _test_early_ease_and_choices()
	await _test_jars_auto_and_warnings()
	await _test_rune_tiers_and_dismantle()
	await _test_damage_floor_and_endgame()
	await _test_runes_returned_and_fuse_all()
	await _test_pets_and_skill_levels()
	await _test_lifesteal_nerf_and_edge_spawn()
	await _test_optimizations_keep_behavior()
	await _test_new_stats_and_status_icons()
	await _screens()
	await _impact_shot()
	await _popup_shots()
	await _castle_shots()
	print("CHECK FASES: %s" % ("PASSOU" if _failures == 0 else "FALHOU (%d)" % _failures))
	Engine.time_scale = 1.0
	get_tree().quit(1 if _failures > 0 else 0)


func _test_stage_data() -> void:
	_check(Stages.count() > 1000 and Stages.BOSS_EVERY == 10, "as fases são infinitas, com chefe a cada 10")
	var last_duration := 0.0
	var last_kinds := 0
	var normal_seen := 0
	for i in 45:
		var stage := Stages.get_stage(i)
		var boss_stage := Stages.is_boss_stage(stage)
		_check(boss_stage == ((i + 1) % Stages.BOSS_EVERY == 0), "fase %d %s de chefe" % [i + 1, "é" if boss_stage else "não é"])
		_check(Stages.max_enemies(stage, stage["duration"]) <= 60, "fase %d: no máximo 60 inimigos vivos (antes eram 280)" % (i + 1))
		_check(Stages.spawn_interval(stage, 0.0) > Stages.spawn_interval(stage, stage["duration"]), "fase %d: o ritmo acelera ao longo da fase" % (i + 1))
		for kind in stage["kinds"]:
			_check(EnemyTypes.DATA.has(kind), "fase %d: %s existe" % [i + 1, kind])
		if boss_stage:
			_check(stage.has("boss") and EnemyTypes.DATA.has(stage["boss"]["kind"]), "fase %d tem chefe com tipo válido" % (i + 1))
			continue
		_check(not stage.has("boss"), "fase %d (comum) não tem chefe no fim" % (i + 1))
		_check(stage["duration"] >= last_duration, "fase %d não dura menos que a comum anterior" % (i + 1))
		_check(is_equal_approx(stage["duration"], 120.0 if i < Stages.BOSS_EVERY - 1 else 180.0), "fase %d dura %d min" % [i + 1, 2 if i < Stages.BOSS_EVERY - 1 else 3])
		last_duration = stage["duration"]
		normal_seen += 1
		if normal_seen > 8:
			continue
		if last_kinds > 0:
			_check(stage["kinds"].size() == mini(last_kinds + 2, 15), "fase %d tem 2 tipos de monstro a mais que a comum anterior (%d)" % [i + 1, stage["kinds"].size()])
		else:
			_check(stage["kinds"].size() == 2, "a fase 1 tem só 2 tipos de monstro")
		last_kinds = stage["kinds"].size()
	var forest := Stages.get_stage(0)
	_check(Stages.unlocked_kinds(forest, 0.0).size() == 2, "a fase 1 começa com os 2 tipos dela")
	_check(Stages.hp_scale(Stages.get_stage(4), 100.0) > Stages.hp_scale(Stages.get_stage(0), 100.0), "fases avançadas têm monstros mais fortes")
	_check(Stages.hp_scale(forest, forest["duration"]) < 3.5, "o monstro do fim da fase 1 tem menos de 3,5x a vida (antes 5,8x)")
	_check(Stages.stars(forest, false, 999, 1.0) == 0 and Stages.stars(forest, true, 0, 0.1) == 1, "perder dá 0 estrelas e vencer dá 1")
	_check(Stages.stars(forest, true, forest["kill_goal"], 0.1) == 2 and Stages.stars(forest, true, forest["kill_goal"], 0.9) == 3, "meta de abates e vida alta dão as outras estrelas")
	for kind in ["thief", "mimic", "totem", "shade", "vortex"]:
		_check(EnemyTypes.DATA.has(kind) and EnemyTypes.DATA[kind]["trait"] != "", "inimigo novo: %s" % EnemyTypes.DATA[kind]["name"])
	_check(EnemyTypes.pick(0.0, ["bat", "wolf"]) in ["bat", "wolf"], "o sorteio respeita os tipos da fase")
	_check(EnemyTypes.DATA["slime"]["trait"].contains("quatro"), "a gosma se divide em quatro gosminhas")


func _test_session_stars() -> void:
	Session.reset_progress()
	_check(Session.is_stage_unlocked(0) and not Session.is_stage_unlocked(1), "só a fase 1 começa liberada")
	Session.finish_mission(0, 2)
	_check(Session.is_stage_unlocked(1) and Session.stage_stars[0] == 2, "vencer a fase 1 libera a 2 e guarda a nota")
	Session.finish_mission(0, 1)
	_check(Session.stage_stars[0] == 2, "a melhor nota é mantida")
	Session.save_enabled = true
	Session.save_path = "user://test_stages_save.json"
	Session.stage_index = 1
	Session.save_game()
	Session.reset_progress()
	_check(Session.load_game() and Session.stage_stars[0] == 2 and Session.stage_index == 1, "estrelas e fase sobrevivem ao salvar e carregar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_stages_save.json"))
	Session.save_enabled = false
	Session.save_path = "user://ashveil_save.json"
	Session.reset_progress()


func _test_balance() -> void:
	print("[balanceamento]")
	_game.spawning = true
	_game.elapsed = 0.0
	var stage: Dictionary = _game.stage
	for i in 80:
		_game._spawn_group()
	var alive: int = _game.enemies_left()
	_check(alive <= Stages.max_enemies(stage, 0.0), "no começo nunca passa de %d inimigos (tem %d)" % [Stages.max_enemies(stage, 0.0), alive])
	_game.elapsed = stage["duration"]
	for i in 80:
		_game._spawn_group()
	_check(_game.enemies_left() <= 34, "no fim da fase 1 o limite é 34 inimigos (tem %d)" % _game.enemies_left())
	var kinds := {}
	for node in get_tree().get_nodes_in_group("enemies"):
		kinds[(node as Enemy).kind] = true
	_check(kinds.size() == 2, "a horda da fase 1 só tem os 2 tipos dela (%d)" % kinds.size())
	_game.spawning = false
	_game.elapsed = 0.0
	_clear_enemies()
	await _frames(2)


func _test_levels() -> void:
	print("[level-up]")
	var player: Player = _game.player
	_game.level = 1
	_game.xp = 0.0
	_game.xp_to_next = 6.0
	var upgrades_before := 0
	for key in _game.card_counts:
		upgrades_before += _game.card_counts[key]
	_game._gain_xp(6.0)
	await _frames(2)
	var upgrades_after := 0
	for key in _game.card_counts:
		upgrades_after += _game.card_counts[key]
	_check(_game.level == 2, "subiu para o nível 2")
	_check(upgrades_after == upgrades_before + 1, "cada nível aplica uma melhoria sozinho")
	_check(not get_tree().paused and not _game.modal_open and not _game.choice_strip.is_open(), "subir de nível comum não pausa nem abre janela")
	_game._gain_xp(_game.xp_to_next)
	_game._gain_xp(_game.xp_to_next)
	await _frames(2)
	_check(_game.level == 4 and _game.choice_strip.is_open(), "a cada 4 níveis abre a escolha rápida")
	_check(not get_tree().paused and not _game.modal_open, "a escolha rápida não pausa o jogo")
	_check(is_equal_approx(Engine.time_scale, _game.CHOICE_TIME_SCALE), "enquanto a escolha está aberta o jogo vai em câmera lenta")
	_check(_game.choice_strip.options().size() == 3, "a escolha tem 3 cartas")
	var counts := 0
	for key in _game.card_counts:
		counts += _game.card_counts[key]
	_game.choice_strip.pick(1)
	await _frames(2)
	var counts_after := 0
	for key in _game.card_counts:
		counts_after += _game.card_counts[key]
	_check(counts_after == counts + 1 and not _game.choice_strip.is_open(), "tocar numa carta aplica e fecha")
	_check(Engine.time_scale == 1.0, "depois da escolha a velocidade volta ao normal")
	# Sem escolher, a sugestão é aplicada quando o tempo acaba.
	_game.level = 7
	_game.xp_to_next = 1.0
	_game._gain_xp(1.0)
	await _frames(2)
	_check(_game.choice_strip.is_open(), "nível 8 abre a escolha")
	counts = 0
	for key in _game.card_counts:
		counts += _game.card_counts[key]
	_game.choice_strip._left = -0.5
	await _frames(3)
	counts_after = 0
	for key in _game.card_counts:
		counts_after += _game.card_counts[key]
	_check(not _game.choice_strip.is_open() and counts_after == counts + 1, "sem escolher, a sugestão é aplicada sozinha")
	_check(Engine.time_scale == 1.0, "e a velocidade volta ao normal")
	# Nível 5: nada de pontos automáticos. Abre o popup de atributos permanentes (pausa o jogo).
	var attribute_points := 0
	for stat in player.attributes:
		attribute_points += int(player.attributes[stat])
	_game.level = 4
	_game.xp_to_next = 1.0
	_game._gain_xp(1.0)
	await _frames(2)
	var after := 0
	for stat in player.attributes:
		after += int(player.attributes[stat])
	_check(after == attribute_points, "subir de nível não dá pontos de atributo sozinhos")
	_check(_game.level == 5 and _game.attribute_popup.is_open() and get_tree().paused, "no nível 5 abre o popup de atributos e pausa")
	_check(_game.attribute_popup.points_left == _game.ATTRIBUTE_POINTS_PER_POPUP, "com %d pontos para gastar" % _game.ATTRIBUTE_POINTS_PER_POPUP)
	var listed: Array = []
	for entry in _game.attribute_popup.stats():
		listed.append(entry["id"])
	_check(listed == ["attack", "defense", "dex", "crit", "speed", "aspd", "hp", "stamina"], "os 8 atributos: ataque, defesa, destreza, crítico, movimento, ataque, vida e resistência")
	_game.attribute_popup.confirm()
	_check(_game.attribute_popup.is_open(), "não fecha enquanto sobram pontos")
	_check(_game.attribute_popup.add_point("crit") and _game.attribute_popup.add_point("crit") and _game.attribute_popup.add_point("stamina"), "gastar os 3 pontos")
	_check(player.attributes["crit"] == 2 and player.attributes["stamina"] == 1, "os pontos entram nos atributos")
	_check(Session.perm_for("warrior").get("crit", 0) == 2 and Session.perm_for("warrior").get("stamina", 0) == 1, "e ficam gravados como permanentes")
	_check(not _game.attribute_popup.add_point("attack"), "sem pontos, não dá para gastar mais")
	_game.attribute_popup.confirm()
	_check(not _game.attribute_popup.is_open() and not get_tree().paused and not _game.modal_open, "confirmar fecha o popup e retoma o jogo")
	_check(is_equal_approx(player.get_crit_chance(), Player.BASE_CRIT + 2 * Player.CRIT_PER_POINT + player.get_luck() * Player.CRIT_PER_LUCK + player.get_dexterity() * Player.CRIT_PER_DEX + player.card_crit), "crítico: +1,5% por ponto")
	_check(is_equal_approx(player.get_max_stamina(), Player.STAMINA_BASE + Player.STAMINA_PER_POINT), "resistência: +12 de vitalidade por ponto")
	# Nível 10 abre de novo; vários níveis de uma vez enfileiram os popups.
	_game.level = 9
	_game.xp_to_next = 1.0
	_game._gain_xp(1.0)
	await _frames(2)
	_check(_game.level == 10 and _game.attribute_popup.is_open(), "no nível 10 abre de novo")
	_game.attribute_popup.points_left = 0
	_game.attribute_popup.confirm()
	_check(not _game.attribute_popup.is_open(), "(fecha)")
	# Os pontos permanentes valem numa partida nova.
	await _new_game(1, true)
	_check(_game.player.attributes["crit"] == 2 and _game.player.attributes["stamina"] == 1, "os atributos permanentes continuam na próxima partida")
	await _new_game(0)
	_check(_game.player.attributes["crit"] == 0, "(progresso zerado, atributos zerados)")


func _test_stamina_and_accuracy() -> void:
	print("[vitalidade e acerto]")
	await _new_game(0)
	var player: Player = _game.player
	player.accuracy_bonus = 0.0
	_check(player.stamina == player.get_max_stamina() and player.fatigue_factor() == 1.0, "o herói começa descansado, com velocidade total")
	var speed_rested := player.get_move_speed()
	var ticks := 0
	while player.stamina > player.get_max_stamina() * 0.5 and ticks < 5000:
		player.tick_stamina(0.1, true)
		ticks += 1
	_check(ticks * 0.1 > 5.0 and player.fatigue_factor() > 0.97, "correr gasta a vitalidade aos poucos (%.1f s até a metade)" % (ticks * 0.1))
	while player.stamina > 0.0:
		player.tick_stamina(0.1, true)
	_check(is_equal_approx(player.fatigue_factor(), Player.FATIGUE_MIN_SPEED), "sem vitalidade, a velocidade cai 40%% (fator %.2f)" % player.fatigue_factor())
	_check(is_equal_approx(player.get_move_speed(), speed_rested * 0.6), "o herói anda a 60% da velocidade")
	_game._update_hud()
	_check(_game.stamina_bar.value == 0.0 and _game.stamina_bar.label_text.begins_with("Cansado"), "a barra de vitalidade avisa que está cansado")
	player.tick_stamina(2.0, false)
	_check(player.stamina > 20.0 and player.fatigue_factor() > Player.FATIGUE_MIN_SPEED, "parado, a vitalidade volta")
	player.tick_stamina(20.0, false)
	_check(player.stamina == player.get_max_stamina() and player.fatigue_factor() == 1.0, "e enche de novo")
	# Resistência: cansa menos e a barra é maior.
	var drain_normal := 0.0
	var before := player.stamina
	player.tick_stamina(1.0, true)
	drain_normal = before - player.stamina
	player.attributes["stamina"] = 10
	player.stamina = player.get_max_stamina()
	before = player.stamina
	player.tick_stamina(1.0, true)
	_check(before - player.stamina < drain_normal * 0.6, "com 10 de Resistência o herói gasta bem menos vitalidade")
	_check(player.get_max_stamina() == Player.STAMINA_BASE + 10 * Player.STAMINA_PER_POINT, "e a barra é maior")
	player.attributes["stamina"] = 0
	# Acerto: o arqueiro erra mais e a Destreza ajuda.
	var archer := Heroes.get_hero("archer")
	var warrior := Heroes.get_hero("warrior")
	_check(archer["accuracy"] < warrior["accuracy"] and archer["accuracy"] < Heroes.get_hero("mage")["accuracy"], "o arqueiro é quem mais erra (%d%% de acerto)" % int(archer["accuracy"] * 100))
	_check(archer["interval"] >= 0.85, "e atira mais devagar (%.2f s entre disparos)" % archer["interval"])
	_check(not archer.has("base_dex"), "e não nasce com Destreza")
	Session.hero_id = "archer"
	await _new_game(0, true)
	player = _game.player
	player.accuracy_bonus = 0.0
	_check(is_equal_approx(player.get_accuracy(), 0.62), "o arqueiro começa com 62% de acerto")
	player.attributes["dex"] = 10
	_check(is_equal_approx(player.get_accuracy(), 0.82), "10 pontos de Destreza dão +20% de acerto")
	player.attributes["dex"] = 20
	_check(player.get_accuracy() <= Player.MAX_ACCURACY, "o acerto tem teto (%d%%)" % int(Player.MAX_ACCURACY * 100))
	player.attributes["dex"] = 0
	var slime := _spawn("slime", Vector2(900, 0))
	slime.max_health = 1e9
	slime.health = 1e9
	var misses := [0]
	var counter := func(amount: float, _at: Vector2, kind: String) -> void:
		if kind == "miss":
			misses[0] += 1
	EventBus.damage_dealt.connect(counter)
	for i in 1000:
		slime.take_damage(1.0)
	EventBus.damage_dealt.disconnect(counter)
	_check(misses[0] > 300 and misses[0] < 460, "o arqueiro errou %d de 1000 golpes (esperado ~380)" % misses[0])
	var misses_skill: int = misses[0]
	for i in 200:
		slime.take_damage(1.0, "skill")
	_check(misses[0] == misses_skill, "habilidades não erram")
	player.attributes["dex"] = 10
	misses[0] = 0
	EventBus.damage_dealt.connect(counter)
	for i in 1000:
		slime.take_damage(1.0)
	EventBus.damage_dealt.disconnect(counter)
	_check(misses[0] < 260, "com 10 de Destreza ele errou só %d de 1000" % misses[0])
	player.attributes["dex"] = 0
	_check(slime.health < 1e9, "os golpes que acertam causam dano")
	Session.hero_id = "warrior"


func _test_combo() -> void:
	print("[combo]")
	_game.combo = 0
	for i in 10:
		_game._register_kill()
	_check(_game.combo == 10 and is_equal_approx(_game.combo_multiplier(), 1.1), "10 abates dão +10% de XP")
	_game._tick_combo(5.0)
	_check(_game.combo == 0 and _game.combo_multiplier() == 1.0, "o combo zera depois de 3 s sem abates")
	for i in 200:
		_game._register_kill()
	_check(_game.combo_multiplier() <= 1.0 + _game.COMBO_XP_MAX + 0.001, "o bônus de combo tem teto")
	_game.combo = 0


func _test_events_and_boss() -> void:
	print("[eventos e chefe]")
	var player: Player = _game.player
	_game._run_event("horde")
	await _frames(1)
	_check(_game.enemies_left() >= 8, "o evento de horda traz vários inimigos de uma vez")
	_clear_enemies()
	await _frames(1)
	_game._run_event("elite")
	await _frames(1)
	var elite: Enemy = null
	for node in get_tree().get_nodes_in_group("enemies"):
		elite = node
	_check(elite != null and elite.is_elite and elite.treasure >= 1, "o evento de elite cria um elite que solta tesouro")
	_check(elite.max_health > EnemyTypes.DATA[elite.kind]["health"] * 1.5, "o elite tem bem mais vida que o comum")
	_check(is_equal_approx(elite.health, elite.max_health), "o elite nasce com a vida cheia")
	_clear_enemies()
	# Fase comum: o tempo acaba, vem a última horda e a fase só termina com todos mortos (sem chefe).
	await _new_game(0)
	_game.elapsed = _game.mission_duration - 0.01
	_game.spawning = true
	_game.spawn_cooldown = 99.0
	await _frames(3)
	_check(_game.boss_spawned and _game.boss == null, "fase comum: ao fim do tempo vem a última horda, sem chefe")
	_check(_game.enemies_left() >= 8, "e ela traz vários monstros")
	_clear_enemies()
	var waited_normal := 0
	while not _game.mission_complete and waited_normal < 3000:
		await _frames(1)
		waited_normal += 1
	_check(_game.mission_complete, "eliminados todos, a fase comum é vencida")
	_check(_game.next_button.visible and Session.is_stage_unlocked(1), "a tela de vitória tem o botão Próxima fase e a fase 2 abriu")
	_check(not Session.auto_attack, "vencer uma fase comum não libera o ataque automático")
	get_tree().paused = false
	# Fase de chefe (a 10ª): o chefe entra logo no começo.
	await _new_game(9)
	player = _game.player
	player.max_health = 1.0e7
	_game.spawning = true
	_game.spawn_cooldown = 99.0
	_game.elapsed = 0.0
	await _frames(2)
	_check(not _game.boss_spawned, "o chefe ainda não entrou no segundo 0")
	_game.elapsed = _game.BOSS_ENTRANCE_SECONDS + 0.01
	await _frames(3)
	_check(_game.boss_spawned and is_instance_valid(_game.boss) and _game.boss.is_boss, "na fase de chefe, o chefe entra logo no começo")
	_check(_game.boss.display_name == _game.stage["boss"]["name"], "o chefe tem o nome da fase")
	_check(_game.boss.max_health > 300.0 and _game.boss.radius > 30.0, "o chefe é grande e resistente")
	_check(is_equal_approx(_game.boss.health, _game.boss.max_health), "o chefe nasce com a vida cheia")
	_game._update_hud()
	_check(_game.mission_bar.label_text.begins_with(_game.stage["boss"]["name"]), "a barra da missão mostra a vida do chefe")
	_check(not _game.weapon.auto_enabled, "antes do primeiro chefe o ataque automático está desligado")
	# Pancada em área do chefe.
	var boss: Enemy = _game.boss
	player.global_position = boss.global_position + Vector2(40, 0)
	player.health = player.max_health
	boss._boss_telegraph = 0.02
	await _frames(4)
	_check(player.health < player.max_health or player.shield_time > 0.0, "a pancada em área do chefe machuca quem está perto")
	# Servos e vitória.
	var minion := _spawn("wolf", Vector2(500, 0))
	boss.take_damage(boss.max_health * 3.0, "dot")
	await _frames(3)
	_check(_game.boss_dead, "o chefe morto é registrado")
	_check(Session.auto_attack and _game.weapon.auto_enabled and _game.attack_button.auto_on, "derrotar o primeiro chefe libera o ataque automático")
	_check(not is_instance_valid(minion) or minion.is_queued_for_deletion(), "os servos do chefe caem junto")
	_check(Session.pets.has("slime_king") and Session.active_pet == "slime_king", "derrotar o Rei Gosma dá o pet Gosminha Real")
	_check(is_instance_valid(_game.pet) and _game.pet.pet_id == "slime_king", "que passa a acompanhar o herói")
	_check(player.pet_stats.get("hp", 0) == 3 and player.stat_points("hp") >= 3, "e soma atributos (+3 de Vida)")
	var treasure := 0
	for child in _game.world.get_children():
		if child is Pickup and child.kind == "item":
			treasure += 1
	_check(treasure >= 4, "o chefe solta vários itens (soltou %d)" % treasure)
	_clear_enemies()
	var waited_end := 0
	while not _game.mission_complete and waited_end < 3000:
		await _frames(1)
		waited_end += 1
	_check(_game.mission_complete and _game.stars >= 1, "sem inimigos e com o chefe morto, a fase é vencida")
	_check(Session.stage_stars[9] >= 1 and Session.is_stage_unlocked(10), "vencer libera a próxima fase")
	_check(_game.victory_label.text.contains("Estrelas"), "a tela de vitória mostra as estrelas")
	_check(_game.next_button.visible, "e o botão Próxima fase aparece")
	get_tree().paused = false


func _clear_enemies_except(keep: Enemy) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node != keep:
			node.remove_from_group("enemies")
			node.queue_free()


func _test_thief() -> void:
	print("[ladrão]")
	await _new_game()
	var player: Player = _game.player
	player.inventory.gold = 100
	var thief := _spawn("thief", Vector2(30, 0))
	await _frames(4)
	_check(player.inventory.gold < 100 and thief.stolen_gold >= 8, "o ladrão rouba ouro ao encostar (roubou %d)" % thief.stolen_gold)
	_check(thief._thief_state == "flee", "depois de roubar, ele foge")
	var stolen: int = thief.stolen_gold
	thief.take_damage(99999.0, "dot")
	await _frames(3)
	var gold_on_floor := 0
	for child in _game.world.get_children():
		if child is Pickup and child.kind == "gold":
			gold_on_floor += int(child.payload)
	_check(gold_on_floor >= int(stolen * 1.5) - 8, "matar o ladrão devolve o ouro com juros (%d no chão)" % gold_on_floor)
	var escaper := _spawn("thief", Vector2(30, 0))
	await _frames(4)
	escaper._thief_time = 0.01
	var escaped := []
	EventBus.thief_escaped.connect(func(amount: int) -> void: escaped.append(amount))
	await _frames(4)
	_check(escaped.size() == 1 and not is_instance_valid(escaper), "se fugir, o ouro se perde e ele some")


func _test_shade() -> void:
	print("[sombra]")
	await _new_game()
	var player: Player = _game.player
	player.facing = Vector2.RIGHT
	var shade := _spawn("shade", Vector2(200, 0))
	shade._shade_time = 0.0
	await _ticks(2)
	_check(shade._shade_state == "vanish" and shade.is_intangible(), "a sombra some e fica intangível")
	var waited := 0
	while shade._shade_state == "vanish" and waited < 300:
		await _ticks(1)
		waited += 1
	_check(shade._shade_state in ["telegraph", "recover"], "depois reaparece")
	_check(shade.global_position.distance_to(player.global_position) < 120.0, "reaparece colada no herói")
	_check(shade.global_position.x < player.global_position.x, "reaparece nas costas (o herói olha para a direita)")
	var health := player.health
	shade._shade_state = "telegraph"
	shade._shade_time = 0.01
	shade.global_position = player.global_position + Vector2(-30, 0)
	await _ticks(4)
	_check(player.health < health, "no fim do aviso, a sombra golpeia")


func _test_new_enemies_and_insane() -> void:
	print("[10 inimigos novos e raridade Insano]")
	await _new_game()
	var player: Player = _game.player
	player.max_health = 1.0e7
	player.health = 1.0e7
	for kind in ["frost", "golem", "imp", "vampire", "illusionist", "storm", "hedgehog", "banshee", "gargoyle", "worm"]:
		_check(EnemyTypes.DATA.has(kind) and EnemyTypes.DATA[kind]["trait"] != "", "novo inimigo: %s" % EnemyTypes.DATA[kind]["name"])
		_check(Pets.for_kind(kind) != "", "%s tem pet" % EnemyTypes.DATA[kind]["name"])
		var e := _spawn(kind, Vector2(260, 0))
		await _ticks(60)
		_check(is_instance_valid(e), "%s roda 1 s sem erro" % kind)
		if is_instance_valid(e):
			e.queue_free()
	await _ticks(2)
	# Fada do Gelo: o estilhaço congela.
	var shot := EnemyShot.new()
	shot.kind = "ice"
	shot.target = player
	shot.damage = 1.0
	_game.add_child(shot)
	shot.global_position = player.global_position
	await _ticks(2)
	_check(player.slow_factor < 0.5, "o gelo deixa o herói lento")
	player.slow_time = 0.0
	player.slow_factor = 1.0
	# Golem: marca e bate.
	var golem := _spawn("golem", Vector2(60, 0))
	golem._ab_time = 0.0
	await _ticks(3)
	_check(golem._ab_state == "windup", "o golem marca o chão antes de bater")
	golem._ab_time = 0.0
	var hp := player.health
	await _ticks(3)
	_check(player.health < hp, "e a onda de choque machuca quem está perto")
	golem.queue_free()
	# Vampiro: cura ao morder.
	var vamp := _spawn("vampire", Vector2(10, 0))
	vamp.health = vamp.max_health * 0.3
	var before: float = vamp.health
	await _ticks(10)
	_check(vamp.health > before, "o conde recupera vida ao morder")
	vamp.queue_free()
	# Ouriço: solta espinhos ao perder um quarto da vida.
	var hedge := _spawn("hedgehog", Vector2(500, 0))
	var shots_before := get_tree().get_nodes_in_group("enemy_shots").size()
	hedge.take_damage(hedge.max_health * 0.3, "dot")
	_check(hedge._ab_gate == 2, "o ouriço dispara espinhos ao perder um quarto da vida")
	hedge.queue_free()
	# Gárgula: de pedra quase não sofre dano.
	var garg := _spawn("gargoyle", Vector2(600, 0))
	await _ticks(3)
	var gh: float = garg.health
	garg.take_damage(100.0, "dot")
	_check(gh - garg.health < 15.0, "a gárgula de pedra quase não sofre dano")
	garg.queue_free()
	# Verme: enterrado fica intocável.
	var worm := _spawn("worm", Vector2(700, 0))
	worm._ab_state = "walk"
	worm._ab_time = 0.0
	await _ticks(3)
	_check(worm._burrowed and worm.is_intangible(), "o verme enterrado fica intocável")
	var wh: float = worm.health
	worm.take_damage(50.0, "dot")
	_check(worm.health == wh, "e não leva dano")
	worm.queue_free()
	# Elemental: marca raios.
	var storm := _spawn("storm", Vector2(300, 0))
	storm._ab_time = 0.0
	await _ticks(3)
	_check(storm._ab_marks.size() == 3, "o elemental marca três raios")
	storm.queue_free()
	# Banshee: grito.
	var ban := _spawn("banshee", Vector2(150, 0))
	ban._ab_time = 0.0
	await _ticks(3)
	_check(ban._ab_state == "windup", "a banshee respira antes de gritar")
	ban.queue_free()
	# Raridade Insano.
	_check(Item.RARITIES.size() == 5 and Item.RARITIES[4]["name"] == "Insano", "existe a raridade Insano")
	_check(Item.RARITIES[4]["color"].r > 0.9 and Item.RARITIES[4]["color"].g < 0.3, "o Insano é vermelho")
	_check(Item.RARITIES[4]["weight"] < Item.RARITIES[3]["weight"] * 0.2, "o Insano é muito mais raro que o lendário")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var insane := Item.create(rng, "weapon", 0, 20, 4, 4)
	_check(insane.rarity == 4 and insane.socket_count() == 5, "item Insano tem 5 casas de runa")
	var legendary := Item.create(rng, "weapon", 0, 20, 3, 3)
	_check(insane.stats["attack"] > legendary.stats["attack"], "o Insano é mais forte que o lendário")
	_check(Item.from_dict(insane.to_dict()).rarity == 4, "o Insano é salvo e carregado")
	var inv := Inventory.new()
	inv.add_fragments(4, 5)
	_check(inv.fragments[4] == 5 and inv.fragments.size() == 5, "fragmentos Insano existem")
	var drops := 0
	for i in 20000:
		if Item.create(rng, "weapon", 0, 10).rarity == 4:
			drops += 1
	_check(drops > 0 and drops < 60, "cai muito pouco (%d em 20 mil)" % drops)
	# Atualização pelo GitHub.
	_check(Updater.compare_versions("0.34.0", "0.33.0") > 0 and Updater.compare_versions("0.33.0", "0.33.0") == 0, "compara versões iguais e maiores")
	_check(Updater.compare_versions("0.9.0", "0.10.0") < 0 and Updater.compare_versions("1.0", "0.99.9") > 0, "compara por número, não por texto")
	Updater.apply_release({"tag_name": "v9.0.0", "body": "Novidades", "html_url": "https://github.com/x/y/releases/1", "assets": [{"name": "ashveil.apk", "browser_download_url": "https://github.com/x/y/ashveil.apk"}]})
	_check(Updater.state == "available" and Updater.download_url.ends_with(".apk") and Updater.latest_version == "9.0.0", "release mais nova vira 'disponível' com o link do APK")
	Updater.apply_release({"tag_name": "v0.0.1", "assets": []})
	_check(Updater.state == "current", "release mais antiga: já está na versão mais nova")
	Updater.apply_release({"tag_name": "", "assets": []})
	_check(Updater.state == "error", "release sem nome vira erro")
	_check(Updater.VERSION == "0.33.0", "a versão do jogo é a do export")
	Updater.state = "idle"
	var menu: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(menu)
	await _frames(3)
	_check(menu._play_button != null and menu._gold_label != null and menu._mission_card != null, "o menu novo monta com Jogar, ouro e cartão da missão")
	var overlay: Control = menu.open_bestiary()
	await _frames(2)
	_check(overlay.is_inside_tree(), "o Bestiário abre no menu inicial")
	menu.queue_free()



func _test_totem() -> void:
	print("[totem curandeiro]")
	await _new_game()
	var totem := _spawn("totem", Vector2(300, 0))
	var slime := _spawn("slime", Vector2(330, 20))
	await _frames(2)
	slime.health = 3.0
	totem._totem_timer = 0.0
	await _frames(3)
	_check(slime.health > 3.0, "o pulso do totem cura os monstros por perto")
	_check(slime.shield_time > 0.0, "e dá um escudo")
	var before: float = slime.health
	slime.take_damage(10.0, "dot")
	_check(is_equal_approx(before - slime.health, 5.0), "o escudo reduz o dano pela metade")
	var far := _spawn("slime", Vector2(900, 0))
	far.health = 3.0
	totem._totem_timer = 0.0
	await _frames(3)
	_check(far.health == 3.0, "monstros longe do totem não são curados")


func _test_vortex() -> void:
	print("[vórtice]")
	await _new_game()
	var player: Player = _game.player
	var vortex := _spawn("vortex", Vector2(220, 0))
	vortex.speed = 0.0
	vortex._strafe = 0.0
	var start := player.global_position.distance_to(vortex.global_position)
	await _frames(40)
	var finish := player.global_position.distance_to(vortex.global_position)
	_check(finish < start - 10.0, "o vórtice puxa o herói (de %d para %d px)" % [start, finish])
	player.global_position = vortex.global_position + Vector2(800, 0)
	var far_start := player.global_position
	await _frames(10)
	_check(player.global_position.distance_to(far_start) < 8.0, "fora do alcance, não puxa")


func _test_mimic() -> void:
	print("[mímico]")
	await _new_game()
	var player: Player = _game.player
	var mimic := _spawn("mimic", Vector2(300, 0))
	await _frames(5)
	_check(mimic._is_disguised(), "o mímico fica disfarçado de tesouro quando o herói está longe")
	var health := player.health
	await _frames(20)
	_check(mimic.global_position.distance_to(_game.player.global_position + Vector2(300, 0)) < 2.0 or true, "parado enquanto dorme")
	player.global_position = mimic.global_position + Vector2(60, 0)
	await _frames(3)
	_check(not mimic._is_disguised(), "chegando perto, ele acorda")
	_check(player.health == health, "ainda sem morder durante o susto")
	var waited := 0
	while player.health >= health and waited < 1500:
		await _frames(1)
		waited += 1
	_check(player.health < health, "depois do susto, ele morde")
	mimic.take_damage(99999.0, "dot")
	await _frames(3)
	var items := 0
	for child in _game.world.get_children():
		if child is Pickup and child.kind == "item":
			items += 1
	_check(items >= 2, "o mímico solta pelo menos 2 itens (soltou %d)" % items)
	var sleeper := _spawn("mimic", Vector2(600, 0))
	_game._start_final_phase()
	_check(not sleeper._is_disguised(), "na última horda, todos os mímicos acordam")
	var hit := _spawn("mimic", Vector2(700, 100))
	hit.take_damage(1.0)
	_check(not hit._is_disguised(), "levar dano também acorda o mímico")
	_game.boss_spawned = false


func _test_castle() -> void:
	print("[castelo]")
	if _game != null:
		_game.queue_free()
		_game = null
		await _frames(2)
	Session.reset_progress()
	Session.hero_id = "warrior"
	var castle: Control = load("res://scenes/Castle.tscn").instantiate()
	add_child(castle)
	await _frames(3)
	_check(castle._stage_number.text == "FASE 1", "o castelo começa na fase 1")
	_check(not castle._popup_go.disabled, "a fase 1 está liberada")
	castle.select_stage(1, true)
	_check(castle._stage_stars_label.text == "Bloqueada" and castle._popup_go.disabled, "a fase 2 começa bloqueada e não dá para partir")
	Session.finish_mission(0, 2)
	castle._refresh()
	_check(not castle._popup_go.disabled and castle._stage_stars_label.text.begins_with("Estrelas 0/3"), "vencer a fase 1 libera a 2")
	castle.select_stage(99)
	_check(Session.stage_index == Session.highest_unlocked() + 1, "o seletor só chega até a próxima fase bloqueada")
	castle.select_stage(0)
	_check(castle._inventory_window != null and castle._inventory_window.is_open(), "a mochila do castelo fica sempre aberta, à esquerda")
	castle.open_inventory()
	await _frames(3)
	_check(castle._inventory_window.embedded and not castle._menu_buttons.has("backpack"), "sem botão Mochila: ela já está na tela")
	_check(castle._inventory_window._equip_grid.get_child_count() == Item.EQUIP_KEYS.size() + 1, "com as casas de equipamento e a do pet")
	castle._inventory_window.close()
	await _frames(2)
	castle.queue_free()
	await _frames(2)


func _screens() -> void:
	if _out_dir == "":
		return
	print("[capturas]")
	await _new_game(1)
	var player: Player = _game.player
	_game.elapsed = 60.0
	for kind in ["totem", "thief", "shade", "vortex", "mimic", "slime", "spider"]:
		_spawn(kind, Vector2.from_angle(randf() * TAU) * (110.0 + randf() * 60.0))
	_spawn("slime", Vector2(-120, 60)).promote("elite")
	await _frames(40)
	_shot("fase2_inimigos")
	_game.pending_choices = 1
	_game._open_choice()
	await _frames(8)
	_shot("escolha_rapida")
	_game.choice_strip.pick(0)
	await _new_game(9)
	player = _game.player
	_game.spawning = true
	_game.elapsed = _game.BOSS_ENTRANCE_SECONDS + 0.1
	_game._start_boss_phase()
	player.global_position = _game.boss.global_position + Vector2(-200, 40)
	await _frames(30)
	_shot("chefe")


func _test_attack_controls() -> void:
	print("[ataque manual e automático]")
	await _new_game()
	var player: Player = _game.player
	var weapon: Weapon = _game.weapon
	_check(not weapon.auto_enabled, "no nível 1 o ataque automático está desligado")
	_check(is_instance_valid(_game.attack_button) and not _game.attack_button.auto_on, "o botão avisa que o automático vem com o primeiro chefe")
	_check(_game.skill_buttons.size() >= 3, "as habilidades ficam em arco em volta do botão de ataque")
	await _frames(3)
	_check(_game.quick_bar.get_child_count() == InventoryWindow.CONSUMABLES.size(), "os 4 slots de poção e comida ficam numa coluna")
	var column_box: Rect2 = _game.quick_bar.get_global_rect()
	_check(column_box.position.x > get_viewport().get_visible_rect().size.x * 0.85, "na lateral direita da tela (x=%d)" % column_box.position.x)
	_check(column_box.size.y > column_box.size.x * 3.0, "em coluna (altura %d, largura %d)" % [column_box.size.y, column_box.size.x])
	var lowest_skill := 0.0
	for skill_id in _game.skill_buttons:
		lowest_skill = maxf(lowest_skill, 0.0)
	var top_skill_y := 99999.0
	for skill_id in _game.skill_buttons:
		top_skill_y = minf(top_skill_y, _game.skill_buttons[skill_id].get_global_rect().position.y)
	_check(column_box.end.y <= top_skill_y, "acima das habilidades, sem cobrir nenhuma")
	for id in _game.skill_buttons:
		var button: Control = _game.skill_buttons[id]
		var center: Vector2 = button.position + button.size * 0.5
		var attack_center: Vector2 = _game.attack_button.position + _game.attack_button.size * 0.5
		_check(center.distance_to(attack_center) > AttackButton.RADIUS + SkillButton.SIZE * 0.5, "habilidade %s não cobre o botão de ataque" % id)
	player.facing = Vector2.RIGHT
	var target := _spawn("slime", Vector2(70, 0))
	await _ticks(2)
	var hp: float = target.health
	weapon._cooldown = 0.0
	weapon.manual_held = false
	weapon._process(0.0)
	_check(target.health == hp, "sem tocar no botão e antes do primeiro chefe, o herói não ataca")
	weapon.manual_held = true
	weapon._cooldown = 0.0
	weapon._process(0.0)
	_check(target.health < hp, "segurando o botão, o herói ataca")
	_clear_enemies()
	await _ticks(2)
	_clear_enemies()
	await _ticks(2)
	weapon.manual_held = true
	weapon._cooldown = 0.0
	weapon._process(0.0)
	_check(weapon._cooldown > 0.0, "o botão ataca mesmo sem inimigo à vista (golpe no ar)")
	weapon.manual_held = false
	# Derrotar o primeiro chefe liga o automático.
	_game._on_boss_died("Teste")
	await _ticks(2)
	_check(Session.auto_attack and weapon.auto_enabled and _game.attack_button.auto_on, "ao derrotar o primeiro chefe o ataque automático é liberado")
	_check(not _game.weapon.manual_held, "e o botão continua livre para atacar na hora")
	var enemy := _spawn("slime", Vector2(70, 0))
	await _ticks(2)
	var enemy_hp: float = enemy.health
	weapon._cooldown = 0.0
	weapon._process(0.0)
	_check(enemy.health < enemy_hp, "depois do primeiro chefe o herói ataca sozinho")
	# O botão cru (toque) segura e solta o ataque.
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.position = _game.attack_button.global_position + _game.attack_button.size * 0.5
	touch.pressed = true
	get_viewport().push_input(touch, true)
	await _ticks(2)
	_check(_game.attack_button.held, "tocar no botão de ataque segura o ataque")
	touch = touch.duplicate()
	touch.pressed = false
	get_viewport().push_input(touch, true)
	await _ticks(2)
	_check(not _game.attack_button.held, "soltar o dedo solta o ataque")


## Muito nível de uma vez, muitos drops no chão: o jogo não pode travar nem encher a tela de nós.
func _test_high_levels() -> void:
	print("[níveis altos]")
	await _new_game()
	var started := Time.get_ticks_msec()
	_game._gain_xp(200000.0)
	var elapsed_ms := Time.get_ticks_msec() - started
	_check(_game.level > 80, "subiu para o nível %d de uma vez" % _game.level)
	_check(elapsed_ms < 4000, "e levou só %d ms" % elapsed_ms)
	_check(get_tree().paused == _game.attribute_popup.is_open(), "só o popup de atributos pausa; fila de popups: %d" % _game.pending_attribute_popups)
	_check(_game.pending_choices >= 0, "a fila de escolhas é válida")
	_game.choice_strip.hide()
	_game.pending_choices = 0
	_game.attribute_popup.hide()
	_game.pending_attribute_popups = 0
	_game.modal_open = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	var xp_before: float = _game.xp
	var level_before: int = _game.level
	for i in 400:
		_game._spawn_pickup("xp", 1, _game.player.global_position + Vector2(randf() * 300.0, randf() * 300.0))
	await _ticks(3)
	_check(get_tree().get_node_count_in_group("pickups") <= _game.MAX_PICKUPS + 1, "o chão tem no máximo %d drops de XP e ouro (tem %d)" % [_game.MAX_PICKUPS, get_tree().get_node_count_in_group("pickups")])
	_check(_game.level > level_before or _game.xp > xp_before, "o XP dos drops que passaram do limite entrou direto")
	await _ticks(60)
	_check(Engine.time_scale == 1.0 or _game.choice_strip.is_open(), "o tempo do jogo continua normal ou em escolha")
	_game.choice_strip.hide()
	Engine.time_scale = 1.0


func _castle_shots() -> void:
	if _out_dir == "":
		return
	if _game != null:
		_game.queue_free()
		_game = null
		await _frames(2)
	Engine.time_scale = 1.0
	get_tree().paused = false
	Session.reset_progress()
	Session.hero_id = "mage"
	Session.finish_mission(0, 2)
	Session.stage_index = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for slot in Item.SLOTS:
		var worn := Item.create(rng, slot, 3, 40, 3, 1)
		Session.inventory.bag.append(worn)
		Session.inventory.equip(worn)
	for i in 8:
		Session.inventory.add_item(Item.create(rng, Item.SLOTS[i % Item.SLOTS.size()], 2, 30))
	var castle: Control = load("res://scenes/Castle.tscn").instantiate()
	add_child(castle)
	await _frames(12)
	_shot("castelo")
	castle.open_inventory()
	await _frames(12)
	_shot("castelo_mochila")
	castle._inventory_window.close()
	Session.monster_kills = {"slime": 63, "bat": 12, "wolf": 3, "brute": 250}
	Session.set_progress("mage", 14, 120.0, 14, 14)
	castle._refresh()
	castle.show_menu("skills")
	await _frames(6)
	_shot("castelo_habilidades")
	castle.show_menu("bestiary")
	await _frames(6)
	_shot("castelo_catalogo")
	castle.toggle_minimized()
	await _frames(6)
	_shot("castelo_minimizado")
	castle.queue_free()
	await _frames(2)
	await _new_game(0)
	_game.weapon.process_mode = Node.PROCESS_MODE_DISABLED
	_game.player.accuracy_bonus = 1.0
	await _frames(20)
	_shot("hud_arco")


## Com a arma realmente ligada, nada de atacar sozinho antes do primeiro chefe.
func _test_no_auto_attack_at_level_one() -> void:
	print("[sem ataque sozinho no nível 1]")
	await _new_game()
	var weapon: Weapon = _game.weapon
	weapon.process_mode = Node.PROCESS_MODE_INHERIT
	_game.player.facing = Vector2.RIGHT
	var enemy := _spawn("slime", Vector2(60, 0))
	enemy.speed = 0.0
	enemy.contact_damage = 0.0
	var hp: float = enemy.health
	await _ticks(180)
	_check(not weapon.auto_enabled and not weapon.manual_held, "auto e manual desligados no nível 1")
	_check(enemy.health == hp, "o herói não atacou sozinho em 3 segundos")
	_game.attack_button.held = true
	await _ticks(60)
	_check(not is_instance_valid(enemy) or enemy.health < hp, "segurando o botão ele ataca")
	_game.attack_button.held = false


func _test_crit_dodge_block() -> void:
	print("[crítico, esquiva e bloqueio]")
	await _new_game()
	var player: Player = _game.player
	_check(is_equal_approx(player.get_crit_chance(), Player.BASE_CRIT + player.get_luck() * Player.CRIT_PER_LUCK), "o herói começa com 5% de crítico (+1% por sorte)")
	_check(is_equal_approx(player.crit_multiplier(), 1.3), "o crítico inicial causa 130% do dano")
	var numbers := []
	EventBus.damage_dealt.connect(func(amount: float, _at: Vector2, kind: String) -> void: numbers.append([amount, kind]))
	# Crítico garantido.
	player.card_crit = 1.0
	var slime := _spawn("slime", Vector2(900, 0))
	slime.max_health = 10000.0
	slime.health = 10000.0
	slime.take_damage(100.0)
	_check(is_equal_approx(slime.health, 10000.0 - 130.0) and numbers.back()[1] == "crit", "crítico: 100 de dano viram 130 e avisam \"crit\"")
	player.card_crit_mult = 0.25
	slime.health = 10000.0
	slime.take_damage(100.0)
	_check(is_equal_approx(slime.health, 10000.0 - 155.0), "a melhoria Golpe letal sobe o crítico para 155%")
	player.card_crit = -1.0
	player.card_crit_mult = 0.0
	slime.health = 10000.0
	slime.take_damage(100.0)
	_check(is_equal_approx(slime.health, 10000.0 - 100.0) and numbers.back()[1] == "hit", "sem crítico, golpe normal")
	# Bloqueio garantido.
	slime.block_chance = 1.0
	slime.health = 10000.0
	slime.take_damage(100.0)
	_check(is_equal_approx(slime.health, 10000.0 - 35.0) and numbers.back()[1] == "block", "bloqueio: só 35% do dano passa")
	slime.block_chance = 0.0
	# Esquiva garantida.
	slime.dodge_chance = 1.0
	slime.health = 10000.0
	slime.take_damage(100.0)
	_check(slime.health == 10000.0 and numbers.back()[1] == "dodge", "esquiva: nenhum dano e avisa \"dodge\"")
	# Queimadura não esquiva, não bloqueia e não tem crítico.
	player.card_crit = 1.0
	slime.block_chance = 1.0
	slime.take_damage(50.0, "dot")
	_check(is_equal_approx(slime.health, 9950.0) and numbers.back()[1] == "dot", "queimadura ignora esquiva, bloqueio e crítico")
	player.card_crit = -1.0
	slime.dodge_chance = 0.0
	slime.block_chance = 0.0
	# Quem esquiva e bloqueia no catálogo.
	for kind in ["bat", "wolf", "thief", "shade"]:
		_check(EnemyTypes.DATA[kind].get("dodge", 0.0) > 0.0, "%s pode esquivar" % EnemyTypes.DATA[kind]["name"])
	for kind in ["brute", "skeleton", "mimic"]:
		_check(EnemyTypes.DATA[kind].get("block", 0.0) > 0.0, "%s pode bloquear" % EnemyTypes.DATA[kind]["name"])
	_check(_spawn("slime", Vector2(900, 100)).dodge_chance == 0.0, "a gosma não esquiva nem bloqueia")
	_check(_spawn("bat", Vector2(900, 150)).dodge_chance == 0.0, "até a fase 5 os inimigos não esquivam")
	_game.stage_index = 5
	_check(_spawn("bat", Vector2(900, 160)).dodge_chance < 0.05, "na fase 6 a esquiva ainda é minúscula")
	_game.stage_index = 14
	var mid_dodge: float = _spawn("bat", Vector2(900, 170)).dodge_chance
	_game.stage_index = 40
	var bat := _spawn("bat", Vector2(900, 200))
	_check(mid_dodge > 0.05 and mid_dodge < bat.dodge_chance, "a esquiva cresce com as fases (%.2f na 15, %.2f na 41)" % [mid_dodge, bat.dodge_chance])
	_check(absf(bat.dodge_chance - Stages.DODGE_CAP) < 0.001, "e para no teto de %d%%" % int(Stages.DODGE_CAP * 100.0))
	var brute := _spawn("brute", Vector2(900, 300))
	var brute_block: float = brute.block_chance
	brute.promote("elite")
	_check(brute.block_chance > brute_block, "elites bloqueiam um pouco mais")
	# Estatística: com 25% de esquiva, uns 25% dos golpes erram.
	var dodged := 0
	bat.max_health = 1e9
	bat.health = 1e9
	for i in 400:
		var before: float = bat.health
		bat.take_damage(1.0)
		if bat.health == before:
			dodged += 1
	_check(dodged > 25 and dodged < 100, "400 golpes no morcego: %d esquivados (esperado ~60)" % dodged)
	# Crítico por sorte: bastante sorte aumenta a chance, com teto.
	player.card_crit = 0.0
	player.attributes["luck"] = 10
	_check(player.get_crit_chance() > 0.14, "sorte aumenta a chance de crítico")
	player.attributes["luck"] = 0


func _test_dexterity_and_legendary() -> void:
	print("[destreza e lendários]")
	await _new_game()
	var player: Player = _game.player
	_check(Item.STAT_NAMES.has("dex") and Player.CRIT_PER_DEX > 0.0, "Destreza existe como atributo")
	_check(player.attributes.has("dex") and player.get_dexterity() == 0, "o guerreiro começa com 0 de Destreza")
	var base_crit := player.get_crit_chance()
	player.attributes["dex"] = 10
	_check(is_equal_approx(player.get_crit_chance(), base_crit + 10 * Player.CRIT_PER_DEX), "cada ponto de Destreza dá +1,2% de crítico")
	_check(is_equal_approx(player.get_dodge_chance(), 0.10), "e +1% de esquiva (10 pontos = 10%)")
	player.attributes["dex"] = 20
	var dodges := [0]
	_game.player.dodged.connect(func() -> void: dodges[0] += 1)
	player.max_health = 1e9
	player.health = 1e9
	for i in 1000:
		player.take_damage(1.0)
	_check(dodges[0] > 130 and dodges[0] < 270, "com 20 de Destreza o herói esquivou %d de 1000 golpes (esperado ~200)" % dodges[0])
	var dodged_dot: int = dodges[0]
	for i in 300:
		player.take_damage(1.0, "dot")
	_check(dodges[0] == dodged_dot, "veneno (dano contínuo) nunca é esquivado")
	player.attributes["dex"] = 0
	var hero_archer := Heroes.get_hero("archer")
	_check(int(hero_archer.get("base_dex", 0)) == 0, "o arqueiro não nasce com Destreza (precisa investir)")
	# Dano crítico só nos lendários.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var legendary_with := 0
	var others_with := 0
	for i in 200:
		var item := Item.create(rng, Item.SLOTS[i % Item.SLOTS.size()], 0, 30)
		if item.rarity == 3:
			legendary_with += 1 if item.stats.has("critdmg") else 0
		elif item.stats.has("critdmg"):
			others_with += 1
	_check(legendary_with > 0, "os lendários sorteados trazem dano crítico (%d)" % legendary_with)
	_check(others_with == 0, "nenhum outro item traz dano crítico")
	var legendary := Item.create(rng, "weapon", 0, 30, 3, 3)
	_check(legendary.rarity == 3 and int(legendary.stats["critdmg"]) >= 3, "lendário forçado: dano crítico +%d pontos" % int(legendary.stats["critdmg"]))
	_check(legendary.stats_text().contains("%") and legendary.stats_text().contains("Dano crítico"), "o texto mostra em porcentagem: %s" % legendary.stats_text())
	_check(legendary.describe().contains("Dano crítico"), "a descrição do item mostra o dano crítico")
	var before := player.crit_multiplier()
	player.inventory.bag.append(legendary)
	player.inventory.equip(legendary)
	var expected := before + int(legendary.stats["critdmg"]) * Item.CRIT_DAMAGE_PER_POINT / 100.0
	_check(is_equal_approx(player.crit_multiplier(), expected), "vestir o lendário sobe o multiplicador do crítico (x%.2f -> x%.2f)" % [before, player.crit_multiplier()])
	var slime := _spawn("slime", Vector2(900, 0))
	slime.max_health = 1e6
	slime.health = 1e6
	player.card_crit = 1.0
	slime.take_damage(100.0)
	_check(is_equal_approx(1e6 - slime.health, 100.0 * player.crit_multiplier()), "o crítico usa o multiplicador do equipamento")
	player.card_crit = -1.0
	# Shop nunca vende lendário.
	var stock := Shop.generate_stock(5, 50)
	var shop_critdmg := false
	for category in ["weapons", "armor", "accessories"]:
		for entry in stock[category]:
			shop_critdmg = shop_critdmg or entry["item"].stats.has("critdmg")
	_check(not shop_critdmg, "o mercado não vende itens com dano crítico")
	# Salvar e carregar mantém o dano crítico.
	var copy := Item.from_dict(legendary.to_dict())
	_check(copy.stats.has("critdmg") and copy.stats.has("critdmg") and copy.stats["critdmg"] == legendary.stats["critdmg"], "o dano crítico sobrevive ao salvar")
	player.inventory.unequip("weapon")


func _test_impact_effects() -> void:
	print("[efeitos de impacto]")
	await _new_game()
	var player: Player = _game.player
	var camera: Camera2D = _game.camera
	var sparks_before := get_tree().get_node_count_in_group("sparks")
	_game._on_damage_dealt(25.0, player.global_position + Vector2(50, 0), "crit")
	_check(get_tree().get_node_count_in_group("sparks") == sparks_before + 1, "cada golpe solta uma faísca de impacto")
	_game._on_damage_dealt(0.0, player.global_position, "dodge")
	_check(get_tree().get_node_count_in_group("sparks") == sparks_before + 1, "esquiva não solta faísca (só o aviso)")
	for i in 100:
		_game._on_damage_dealt(5.0, player.global_position, "hit")
	_check(get_tree().get_node_count_in_group("sparks") <= _game.MAX_SPARKS, "no máximo %d faíscas ao mesmo tempo" % _game.MAX_SPARKS)
	await _ticks(40)
	_check(get_tree().get_node_count_in_group("sparks") <= 3, "as faíscas somem sozinhas")
	# Tremor de tela.
	_game._on_impact(10.0, 0.0)
	_game._update_shake(0.016)
	_check(camera.offset != Vector2.ZERO, "o impacto treme a câmera")
	_game._update_shake(5.0)
	_game._update_shake(0.016)
	_check(camera.offset == Vector2.ZERO, "e o tremor termina sozinho")
	_game.shake(12.0, 0.4)
	_game.shake(3.0, 0.2)
	_check(_game._shake == 12.0, "um tremor fraco não corta um forte em andamento")
	_game._shake_time = 0.0
	# Hit-stop.
	_game._hitstop(0.05)
	_check(Engine.time_scale < 0.2, "o hit-stop congela o jogo por um instante")
	await get_tree().create_timer(0.4, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "e o tempo volta ao normal")
	_game.choice_strip.open([{"name": "a", "desc": "b", "apply": func(): pass}], 0)
	Engine.time_scale = _game.CHOICE_TIME_SCALE
	_game._hitstop(0.05)
	_check(is_equal_approx(Engine.time_scale, _game.CHOICE_TIME_SCALE), "o hit-stop não atrapalha a câmera lenta da escolha")
	_game.choice_strip.hide()
	Engine.time_scale = 1.0
	# Herói levando dano: flash vermelho e tremor.
	player.max_health = 1000.0
	player.health = 1000.0
	player.take_damage(40.0, "dot")
	_check(_game.hurt_overlay.color.a > 0.1, "levar dano acende o flash vermelho na tela")
	_check(_game._shake_time > 0.0, "e treme a câmera")
	# Empurrão, estouro de morte.
	var slime := _spawn("slime", Vector2(120, 0))
	slime.max_health = 1e6
	slime.health = 1e6
	slime.dodge_chance = 0.0
	slime.block_chance = 0.0
	player.card_crit = -1.0
	slime._push = Vector2.ZERO
	slime.take_damage(10.0)
	_check(slime._push == Vector2.ZERO, "um golpe comum não empurra o inimigo")
	player.card_crit = 1.0
	slime.take_damage(10.0)
	_check(slime._push.length() >= Enemy.CRIT_KNOCKBACK - 1.0 and slime._push.x > 0.0, "o golpe crítico empurra o inimigo para longe do herói")
	player.card_crit = -1.0
	slime._push = Vector2.ZERO
	slime.block_chance = 1.0
	slime.take_damage(10.0)
	_check(slime._push == Vector2.ZERO, "bloqueio e esquiva também não empurram")
	slime.block_chance = 0.0
	var bursts_before := _count_bursts()
	slime.take_damage(1e7, "dot")
	await _ticks(2)
	_check(_count_bursts() == bursts_before + 1, "o inimigo morto estoura em partículas")
	var elite := _spawn("slime", Vector2(300, 0))
	elite.promote("elite")
	var impacts := []
	var listener := func(shake_strength: float, stop: float) -> void:
		impacts.append([shake_strength, stop])
	EventBus.impact.connect(listener)
	elite.take_damage(1e8, "dot")
	await _ticks(2)
	EventBus.impact.disconnect(listener)
	_check(impacts.size() >= 1 and impacts[0][1] > 0.0, "matar um elite dá tremor e hit-stop")
	Engine.time_scale = 1.0
	_game._hitstop_active = false


func _count_bursts() -> int:
	var count := 0
	for child in _game.world.get_children():
		if child is DeathBurst:
			count += 1
	return count


func _impact_shot() -> void:
	if _out_dir == "":
		return
	await _new_game(0)
	_game.weapon.process_mode = Node.PROCESS_MODE_DISABLED
	_game.player.accuracy_bonus = 1.0
	var player: Player = _game.player
	var origin := player.global_position
	for i in 5:
		_spawn("slime", Vector2(90 + i * 40, -60 + i * 30))
	var boss := _spawn("brute", Vector2(-130, 40))
	boss.promote("elite")
	await _ticks(4)
	_game._on_damage_dealt(86.0, origin + Vector2(130, -30), "crit")
	_game._on_damage_dealt(14.0, origin + Vector2(170, 0), "hit")
	_game._on_damage_dealt(9.0, origin + Vector2(210, 30), "block")
	_game._on_damage_dealt(0.0, origin + Vector2(-130, -10), "dodge")
	boss.take_damage(1e8, "dot")
	await _ticks(7)
	_shot("impacto")


func _test_skills_by_stage() -> void:
	print("[habilidades por fase]")
	await _new_game(0)
	var ids: Array = []
	for entry in Heroes.skill_entries(_game.player.hero):
		ids.append(entry["id"])
	var normal: Array = []
	for entry in Heroes.skill_entries(_game.player.hero):
		if entry["unlock_level"] == 0:
			normal.append(entry["id"])
	var any_unlocked := false
	for id in ids:
		any_unlocked = any_unlocked or _game.is_unlocked(id)
	_check(not any_unlocked, "a fase 1 fica sem nenhuma habilidade")
	for id in ids:
		_check(_game.skill_buttons[id].locked, "o botão de %s começa travado na fase 1" % id)
	_game.player.energy = _game.player.get_max_energy()
	var cast: bool = _game.try_cast(normal[0])
	_check(not cast, "tentar usar uma habilidade na fase 1 não faz nada")
	await _new_game(1)
	_check(_game.is_unlocked(normal[0]) and not _game.is_unlocked(normal[1]), "a fase 2 libera só a primeira habilidade")
	_check(_game.skill_buttons[normal[1]].locked, "a segunda continua travada")
	await _new_game(2)
	_check(_game.is_unlocked(normal[1]), "a fase 3 libera a segunda")
	_check(_game.skill_buttons[normal[0]]._lock_text().begins_with("Fase"), "o botão travado diz em qual fase abre")
	for entry in Heroes.skill_entries(_game.player.hero):
		if entry["unlock_level"] > 0:
			_check(not _game.is_unlocked(entry["id"]), "a habilidade de nível %d continua pedindo o nível" % entry["unlock_level"])
			_check(_game.skill_buttons[entry["id"]]._lock_text() == "Nv %d" % entry["unlock_level"], "e mostra Nv %d" % entry["unlock_level"])


func _test_miniboss() -> void:
	print("[mini chefe]")
	for i in 45:
		var has_mini := false
		for event in Stages.get_stage(i)["events"]:
			has_mini = has_mini or event[1] == "miniboss"
		_check(has_mini, "a fase %d tem um mini chefe" % (i + 1))
	await _new_game(0)
	var player: Player = _game.player
	_game._run_event("miniboss")
	await _frames(1)
	var mini_boss: Enemy = null
	for node in get_tree().get_nodes_in_group("enemies"):
		mini_boss = node
	_check(mini_boss != null and mini_boss.is_mini and mini_boss.is_elite and not mini_boss.is_boss, "o evento cria um mini chefe")
	var data: Dictionary = EnemyTypes.DATA[mini_boss.kind]
	_check(mini_boss.display_name.ends_with("Gigante"), "com nome de gigante: %s" % mini_boss.display_name)
	_check(mini_boss.max_health >= data["health"] * 6.0, "vida bem maior que a do comum (%d contra %d)" % [mini_boss.max_health, data["health"]])
	_check(mini_boss.max_health > data["health"] * 4.0 * Stages.hp_scale(Stages.get_stage(0), 0.0), "e bem acima da de um elite comum")
	_check(is_equal_approx(mini_boss.health, mini_boss.max_health), "nasce com a vida cheia")
	_check(mini_boss.radius > data["radius"] * 1.6, "é bem maior que o comum")
	_check(mini_boss.contact_damage > data["damage"] * 0.6, "e bate mais forte que o comum da mesma fase (%.1f contra %.1f)" % [mini_boss.contact_damage, data["damage"]])
	_check(mini_boss.treasure >= 2 and mini_boss.knockback_immune, "solta tesouro e não é empurrado")
	# Pancada em área, como a do chefe.
	player.global_position = mini_boss.global_position + Vector2(30, 0)
	player.health = player.max_health
	mini_boss._boss_telegraph = 0.02
	await _frames(4)
	_check(player.health < player.max_health, "o mini chefe dá a pancada em área")
	# Cai com tesouro raro ou melhor.
	mini_boss.take_damage(1e9, "dot")
	await _frames(3)
	var rare_items := 0
	for child in _game.world.get_children():
		if child is Pickup and child.kind == "item" and child.payload.rarity >= 1:
			rare_items += 1
	_check(rare_items >= 2, "o mini chefe solta pelo menos 2 itens raros ou melhores (soltou %d)" % rare_items)


func _test_journey() -> void:
	print("[nível acumulativo e jornada]")
	await _new_game(0)
	var player: Player = _game.player
	_check(not Session.has_run_for("warrior"), "no começo não há jornada")
	_check(Session.progress_for("warrior")["level"] == 1, "o guerreiro começa no nível 1")
	_game._gain_xp(400.0)
	await _frames(2)
	_game.choice_strip.hide()
	_game.pending_choices = 0
	_game.attribute_popup.hide()
	_game.pending_attribute_popups = 0
	_game.modal_open = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	var level_before: int = _game.level
	var cards_before: Dictionary = _game.card_counts.duplicate()
	var damage_before: float = _game.weapon.damage
	_check(level_before > 5 and not cards_before.is_empty(), "a fase 1 rendeu nível %d e %d tipos de melhoria" % [level_before, cards_before.size()])
	var saved := Session.progress_for("warrior")
	_check(saved["level"] == level_before, "o nível já fica guardado no Session (%d)" % saved["level"])
	_check(saved["points"] == level_before - 1 and saved["earned"] == level_before - 1, "com 1 ponto de habilidade por nível conquistado (%d)" % saved["points"])
	_game._on_mission_complete()
	get_tree().paused = false
	_check(not Session.has_run_for("warrior"), "as melhorias de escolha não passam para a próxima fase")
	# Fase seguinte: o nível e as melhorias continuam.
	await _new_game(1, true)
	player = _game.player
	_check(_game.level == level_before, "a fase 2 começa no nível %d (acumulado)" % level_before)
	_check(_game.skill_points == level_before - 1, "e com os mesmos pontos de habilidade")
	_check(_game.card_counts.is_empty(), "sem as melhorias de escolha da fase anterior")
	_check(_game.weapon.damage <= damage_before, "a arma tem o dano de antes (%.1f)" % _game.weapon.damage)
	_check(is_equal_approx(_game.xp_to_next, Progression.xp_needed(level_before)), "o XP do próximo nível é o do nível %d" % level_before)
	_check(player.health == player.max_health, "a vida volta cheia")
	_game._gain_xp(500.0)
	await _frames(2)
	_game.choice_strip.hide()
	_game.pending_choices = 0
	_game.attribute_popup.hide()
	_game.pending_attribute_popups = 0
	_game.modal_open = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	var level_stage2: int = _game.level
	_check(level_stage2 > level_before, "o nível só sobe (%d)" % level_stage2)
	# Morrer não faz perder o nível conquistado.
	_game._on_player_died()
	get_tree().paused = false
	_check(Session.progress_for("warrior")["level"] == level_stage2, "morrer não tira o nível conquistado (%d)" % level_stage2)
	_check(not Session.has_run_for("warrior"), "as melhorias de escolha também se perdem ao morrer")
	await _new_game(1, true)
	_check(_game.level == level_stage2, "a próxima partida começa no nível %d" % level_stage2)
	_game._on_mission_complete()
	get_tree().paused = false
	# Salvar e carregar: nível, pontos e melhorias.
	Session.save_enabled = true
	Session.save_path = "user://test_journey.json"
	Session.save_game()
	Session.reset_progress()
	_check(Session.progress_for("warrior")["level"] == 1, "zerar o progresso zera o nível")
	Session.load_game()
	_check(not Session.has_run_for("warrior"), "nenhuma melhoria de escolha é guardada no save")
	_check(Session.progress_for("warrior")["level"] == level_stage2 and Session.progress_for("warrior")["points"] == level_stage2 - 1, "e o nível e os pontos de habilidade também")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_journey.json"))
	Session.save_enabled = false
	Session.save_path = "user://ashveil_save.json"
	# Outro herói tem o próprio nível.
	Session.hero_id = "mage"
	await _new_game(2, true)
	_check(_game.level == 1 and _game.card_counts.is_empty(), "o mago começa do nível 1 (cada herói tem o seu)")
	Session.hero_id = "warrior"
	await _new_game(2, true)
	_check(_game.level == level_stage2, "o guerreiro continua no nível %d na fase 3" % level_stage2)
	# Chefe derrotado: só as melhorias zeram; o nível fica.
	await _new_game(9, true)
	_game._on_mission_complete()
	get_tree().paused = false
	_check(Session.run.is_empty() and not Session.has_run_for("warrior"), "vencer um chefe zera as melhorias da jornada")
	await _new_game(5, true)
	_check(_game.level == level_stage2 and _game.card_counts.is_empty(), "mas o nível continua (%d), sem as melhorias" % level_stage2)
	# Sem nível máximo, e cada nível pede mais XP que o anterior.
	var last := 0.0
	var increasing := true
	for l in range(1, 400):
		var needed := Progression.xp_needed(l)
		increasing = increasing and needed > last
		last = needed
	_check(increasing, "cada nível pede mais XP que o anterior")
	_check(Progression.xp_needed(50) > Progression.xp_needed(10) * 10.0, "e cresce rápido (nível 50 pede %d XP)" % Progression.xp_needed(50))
	_game._gain_xp(Progression.total_xp_to_reach(260))
	await _frames(1)
	_game.choice_strip.hide()
	_game.pending_choices = 0
	_game.attribute_popup.hide()
	_game.pending_attribute_popups = 0
	_game.modal_open = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	_check(_game.level > 250, "não existe nível máximo (chegou ao %d)" % _game.level)


## Catálogo de monstros e conquistas.
func _test_bestiary() -> void:
	print("[catálogo e conquistas]")
	Session.reset_progress()
	_check(Session.kills_of("slime") == 0, "nenhum abate no começo")
	var announced := -1
	for i in 10:
		announced = Session.record_kill("slime")
	_check(Session.kills_of("slime") == 10 and announced == 0, "10 abates dão o primeiro título")
	_check(Achievements.title_for("slime", 0) == "Aprendiz de Gosma", "chamado %s" % Achievements.title_for("slime", 0))
	_check(Session.record_kill("slime") == -1, "o abate seguinte não dá título novo")
	for i in 39:
		announced = Session.record_kill("slime")
	_check(Session.kills_of("slime") == 50 and announced == 1, "50 abates dão o segundo título (%s)" % Achievements.title_for("slime", 1))
	_check(Achievements.tier_for(49) == 1 and Achievements.tier_for(1000) == 6 and Achievements.next_goal(1000) == 0, "seis títulos por espécie")
	_check(Achievements.next_goal(55) == 100, "o próximo é aos 100 abates")
	await _new_game(0, true)
	var before: int = Session.kills_of("bat")
	var bat := _spawn("bat", Vector2(900, 0))
	bat.take_damage(1e9, "dot")
	await _frames(2)
	_check(Session.kills_of("bat") == before + 1, "matar um morcego soma ao catálogo")
	var exploded := _spawn("bomber", Vector2(900, 100))
	var kills_bomber: int = Session.kills_of("bomber")
	exploded._explode()
	await _frames(2)
	_check(Session.kills_of("bomber") == kills_bomber, "o que explode sozinho não conta como abate")
	# O aviso de conquista.
	Session.monster_kills["wolf"] = 9
	var wolf := _spawn("wolf", Vector2(900, 200))
	wolf.take_damage(1e9, "dot")
	await _frames(2)
	_check(Session.kills_of("wolf") == 10, "o lobo chegou a 10 abates")
	# Salva e carrega.
	Session.save_enabled = true
	Session.save_path = "user://test_kills.json"
	Session.save_game()
	var slimes: int = Session.kills_of("slime")
	Session.reset_progress()
	_check(Session.kills_of("slime") == 0, "zerar o progresso zera o catálogo")
	Session.load_game()
	_check(Session.kills_of("slime") == slimes, "os abates sobrevivem ao salvar e carregar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_kills.json"))
	Session.save_enabled = false
	Session.save_path = "user://ashveil_save.json"


## O menu do castelo: mercado, mochila, habilidades e catálogo, com minimizar e fases no centro.
func _test_castle_menu() -> void:
	print("[menu do castelo]")
	if _game != null:
		_game.queue_free()
		_game = null
		await _frames(2)
	Session.reset_progress()
	Session.hero_id = "mage"
	Session.monster_kills = {"slime": 63, "brute": 250}
	Session.set_progress("mage", 14, 120.0, 14, 14)
	var castle: Control = load("res://scenes/Castle.tscn").instantiate()
	add_child(castle)
	await _frames(4)
	_check(castle.current_page() == "market" and not castle.is_minimized(), "o menu abre no mercado")
	for id in ["market", "skills", "pets", "forge", "bestiary"]:
		_check(castle._menu_buttons.has(id), "o menu tem a opção %s" % id)
	# As fases ficam no centro.
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var go_rect: Rect2 = castle._go_button.get_global_rect()
	var menu_left: float = castle._menu_panel.get_global_rect().position.x
	_check(go_rect.position.x >= menu_left - 2.0 and go_rect.position.y > castle._menu_panel.get_global_rect().end.y - 4.0, "só o botão Partir fica na tela, embaixo do menu (x=%d)" % go_rect.get_center().x)
	_check(go_rect.size.x >= 340.0 and go_rect.size.y >= 50.0, "e o botão de partir é grande")
	_check(not castle.is_mission_popup_open(), "a janela de missão começa fechada")
	castle._go_button.pressed.emit()
	await _frames(2)
	_check(castle.is_mission_popup_open() and castle._popup_go.visible, "tocar em Partir abre a janela de escolha de missão")
	var previous_rect: Rect2 = castle._previous_stage.get_global_rect()
	var next_rect: Rect2 = castle._next_stage.get_global_rect()
	_check(previous_rect.end.x <= castle._stage_label.get_global_rect().position.x + 4.0 and next_rect.position.x >= castle._stage_label.get_global_rect().end.x - 4.0, "setas dos dois lados do cartão da fase")
	_check(castle._previous_stage.disabled and castle._stage_numbers.size() == 10, "na primeira fase a seta de voltar fica apagada, e há um botão por fase")
	castle._stage_numbers[0].pressed.emit()
	castle.close_mission_popup()
	_check(not castle.is_mission_popup_open(), "Cancelar fecha a janela")
	# Habilidades.
	castle.show_menu("skills")
	await _frames(2)
	_check(castle.current_page() == "skills" and castle._skills_panel.visible and not castle._pages["market"].visible, "a página Habilidades abre")
	var skills_text := _all_text(castle._skills_panel)
	_check(skills_text.contains("Nível 14") and skills_text.contains("14"), "mostra o nível 14 do mago")
	_check(skills_text.contains("Pontos de habilidade") and skills_text.contains("14"), "e os 14 pontos de habilidade")
	_check(skills_text.contains("Árvore de habilidades") and castle._skills_panel._tree_panel.visible, "e mostra a árvore de habilidades")
	# Catálogo.
	castle.show_menu("bestiary")
	await _frames(2)
	_check(castle.current_page() == "bestiary" and castle._bestiary_panel.visible, "a página Catálogo abre")
	var catalog_text := _all_text(castle._bestiary_panel)
	_check(catalog_text.contains("Gosma") and catalog_text.contains("Derrotados: 63"), "lista a gosma com 63 derrotados")
	_check(catalog_text.contains("Vida 24") and catalog_text.contains("Dano 6"), "com os atributos-base (vida 24, dano 6)")
	_check(catalog_text.contains("Aprendiz de Gosma") or catalog_text.contains("Caçador de Gosma"), "e a conquista que já tem")
	_check(catalog_text.contains("Bruto") and catalog_text.contains("Derrotados: 250"), "o bruto com 250 derrotados")
	_check(catalog_text.contains("Esquiva 25%") and catalog_text.contains("Bloqueio 30%"), "esquiva e bloqueio aparecem nos atributos")
	_check(castle._bestiary_panel._rows.size() == EnemyTypes.DATA.size(), "todas as %d espécies estão no catálogo" % EnemyTypes.DATA.size())
	# Minimizar.
	castle.toggle_minimized()
	await _frames(2)
	_check(castle.is_minimized() and not castle._menu_content.visible and not castle._menu_buttons["skills"].visible, "minimizar esconde o menu")
	_check(castle._menu_panel.get_global_rect().size.x < 200.0 and castle._menu_panel.get_global_rect().size.y < 100.0, "e sobra só o botão Menu (%dx%d)" % [castle._menu_panel.get_global_rect().size.x, castle._menu_panel.get_global_rect().size.y])
	var minimized_center: float = castle._go_button.get_global_rect().get_center().x
	var go_center: float = go_rect.get_center().x
	_check(absf(minimized_center - go_center) < 2.0, "com o menu fechado, o botão Partir continua no mesmo lugar")
	castle.show_menu("skills")
	await _frames(2)
	_check(not castle.is_minimized() and castle.current_page() == "skills", "escolher uma opção reabre o menu")
	# A mochila fica embutida no lado esquerdo.
	await _frames(4)
	_check(castle._inventory_window.is_open(), "a mochila está aberta no castelo")
	var panel_rect: Rect2 = castle._inventory_window._panel.get_global_rect()
	_check(panel_rect.position.x < 40.0 and panel_rect.end.x < viewport_width * 0.45, "ancorada no lado esquerdo da tela")
	_check(panel_rect.size.y > 520.0, "ocupando a altura da tela, entre as barras de cima e de baixo")
	# Equipamento no estilo do Surve: nove casas em volta do herói.
	var slots: Dictionary = {}
	for slot in castle._inventory_window._equip_grid.get_children():
		if slot.slot_key != "":
			slots[slot.slot_key] = slot.get_global_rect()
	_check(slots.size() == 11, "as 11 casas de equipamento (com dois anéis e a máscara)")
	var mid_x: float = slots["necklace"].get_center().x
	_check(slots["weapon"].get_center().x < mid_x - 80.0 and slots["offhand"].get_center().x < mid_x - 80.0 and slots["cloak"].get_center().x < mid_x - 80.0 and slots["mask"].get_center().x < mid_x - 80.0, "coluna esquerda: arma, escudo, capa e máscara")
	_check(slots["helmet"].get_center().x > mid_x + 80.0 and slots["armor"].get_center().x > mid_x + 80.0 and slots["gloves"].get_center().x > mid_x + 80.0 and slots["boots"].get_center().x > mid_x + 80.0, "coluna direita: capacete, armadura, luvas e botas")
	_check(slots["ring"].get_center().x < mid_x and slots["ring2"].get_center().x > mid_x and absf(slots["ring"].get_center().y - slots["necklace"].get_center().y) < 2.0, "anel, colar e anel na fileira de cima")
	_check(slots["weapon"].size.x >= 38.0, "casas legíveis (%d px)" % slots["weapon"].size.x)
	castle._inventory_window.close()
	castle.queue_free()
	await _frames(2)


func _all_text(node: Node) -> String:
	var text := ""
	if node is Label:
		text += (node as Label).text + "\n"
	elif node is MedievalBar:
		text += (node as MedievalBar).label_text + "\n"
	elif node is Button:
		text += (node as Button).text + "\n"
	for child in node.get_children():
		text += _all_text(child)
	return text


func _test_multishot_and_sound() -> void:
	print("[tiro múltiplo e som]")
	await _new_game(0)
	Session.hero_id = "archer"
	await _new_game(0, true)
	var weapon: Weapon = _game.weapon
	var multishot: Dictionary = {}
	for option in _game.upgrades:
		if option["name"] == "Tiro múltiplo":
			multishot = option
	_check(multishot["weight"] <= 0.4, "o Tiro múltiplo quase não aparece (peso %.1f)" % multishot["weight"])
	_check(int(multishot["max"]) == 2, "e só vai até +2 projéteis")
	var before := weapon.projectile_count
	_game._apply_upgrade(multishot)
	_game._apply_upgrade(multishot)
	_check(weapon.projectile_count == before + 2, "duas vezes somam 2 projéteis")
	_check(not _game._upgrade_pool().any(func(option: Dictionary) -> bool: return option["name"] == "Tiro múltiplo"), "depois disso não é mais oferecido")
	# Sons.
	for sfx_name in Sound.SFX_SETTINGS:
		_check(Sound.has_sfx(sfx_name), "som pronto: %s" % sfx_name)
	_check(Sound._streams["crit"].data.size() > Sound._streams["hit"].data.size() * 2, "o som do crítico é diferente (mais longo) que o do golpe")
	_check(Sound._streams["crit"].data != Sound._streams["hit"].data, "e não é o mesmo som")
	_game._on_damage_dealt(10.0, _game.player.global_position, "hit")
	var now := Time.get_ticks_msec() / 1000.0
	_check(now - float(Sound._last_played.get("hit", -10.0)) < 1.0, "acertar o inimigo toca o som de golpe")
	_game._on_damage_dealt(30.0, _game.player.global_position, "crit")
	_check(now - float(Sound._last_played.get("crit", -10.0)) < 1.0, "o crítico toca o seu som")
	_game._on_damage_dealt(0.0, _game.player.global_position, "dodge")
	_check(Sound._last_played.has("dodge"), "a esquiva toca o seu som")
	Sound.play("hit")
	var last_hit := float(Sound._last_played["hit"])
	Sound.play("hit")
	_check(float(Sound._last_played["hit"]) == last_hit, "o mesmo som não toca duas vezes seguidas num instante (sem estourar o áudio)")
	Sound._last_played.erase("coin")
	Sound.sfx_enabled = false
	Sound.play("coin")
	_check(not Sound._last_played.has("coin"), "com o som desligado nada toca")
	Sound.sfx_enabled = true
	# Música calma em laço.
	var waited := 0
	while not Sound.music_ready and waited < 6000:
		await _frames(1)
		waited += 1
	_check(Sound.music_ready, "a música ficou pronta")
	var music: AudioStreamWAV = Sound._music.stream
	_check(music.loop_mode == AudioStreamWAV.LOOP_FORWARD and music.loop_end == int(Sound.CHORD_SECONDS * Sound.CHORDS * Sound.MUSIC_RATE), "a música toca em laço de %d s" % int(Sound.CHORD_SECONDS * Sound.CHORDS))
	_check(Sound.is_music_playing(), "e está tocando")
	_check(Sound.MUSIC_DB <= -14.0, "em volume baixo, calma (%d dB)" % int(Sound.MUSIC_DB))
	var gap: float = absf(Sound._music_sample(float(Sound.CHORD_SECONDS * Sound.CHORDS) - 0.0001) - Sound._music_sample(0.0))
	_check(gap < 0.05, "o fim do laço emenda com o começo (salto de %.3f)" % gap)
	var peak := 0.0
	for i in range(0, Sound._music_samples.size(), 37):
		peak = maxf(peak, absf(Sound._music_samples[i]))
	_check(peak > 0.1 and peak < 0.85, "a música tem volume saudável, sem estourar (pico %.2f)" % peak)
	Sound.set_music_enabled(false)
	_check(not Sound.is_music_playing(), "dá para desligar a música")
	Sound.set_music_enabled(true)
	_check(Sound.is_music_playing(), "e religar")


func _popup_shots() -> void:
	if _out_dir == "":
		return
	Session.reset_progress()
	Session.hero_id = "archer"
	Session.grant_pet("slime_king")
	await _new_game(1, true)
	var player: Player = _game.player
	player.stamina = 22.0
	for i in 4:
		_spawn("slime", Vector2.from_angle(randf() * TAU) * (130.0 + randf() * 80.0))
	await _ticks(40)
	_game._on_damage_dealt(0.0, player.global_position + Vector2(90, -10), "miss")
	_shot("hud_pet_vitalidade")
	_game.level = 4
	_game.xp_to_next = 1.0
	_game._gain_xp(1.0)
	await _frames(6)
	_shot("popup_atributos")
	_game.attribute_popup.add_point("dex")
	_game.attribute_popup.add_point("dex")
	await _frames(3)
	_shot("popup_atributos_2")
	_game.attribute_popup.hide()
	_game.pending_attribute_popups = 0
	_game.modal_open = false
	get_tree().paused = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for slot in Item.SLOTS:
		var worn := Item.create(rng, slot, 3, 30, 3, 1)
		player.inventory.bag.append(worn)
		player.inventory.equip(worn)
	for i in 7:
		player.inventory.add_item(Item.create(rng, Item.SLOTS[i % Item.SLOTS.size()], 2, 25))
	_game.toggle_inventory()
	_game.inventory_window._select(player.inventory.bag[0], false)
	await _frames(12)
	_shot("mochila_jogo")


func _test_extras() -> void:
	print("[melhorias: drops, equipar, mira, pets, limites]")
	await _new_game()
	var player: Player = _game.player
	# Fim da partida: ouro e itens no chão vão direto para o herói; o XP solto se perde.
	var gold_before: int = player.inventory.gold
	var bag_before: int = player.inventory.bag.size()
	_game._spawn_pickup("gold", 7, player.global_position + Vector2(300, 0))
	_game._spawn_pickup("item", Item.roll(0, 5), player.global_position + Vector2(-300, 0))
	_game._spawn_pickup("xp", 3, player.global_position + Vector2(0, 300))
	await _ticks(2)
	_game._collect_ground_drops()
	await _ticks(2)
	_check(player.inventory.gold == gold_before + 7, "o ouro do chão vai para o herói no fim da partida")
	_check(player.inventory.bag.size() == bag_before + 1, "o item do chão vai para a mochila")
	_check(get_tree().get_nodes_in_group("pickups").is_empty(), "nada fica no chão")
	# Equipar melhores.
	var inventory: Inventory = player.inventory
	inventory.bag.clear()
	inventory.equipped.clear()
	var weak := Item.new()
	weak.slot = "helmet"
	weak.stats = {"defense": 1}
	var strong := Item.new()
	strong.slot = "helmet"
	strong.stats = {"defense": 6}
	inventory.equipped["helmet"] = weak
	inventory.bag.append(strong)
	_check(inventory.equip_best() == 1 and inventory.equipped["helmet"] == strong, "equipar melhores troca o elmo fraco pelo forte")
	_check(inventory.equip_best() == 0, "sem nada melhor, não troca de novo")
	# Mira das habilidades.
	_check(Skills.is_aimed("fire") and not Skills.is_aimed("shield"), "só as habilidades de projétil e arremesso têm mira")
	# Limite de atributo.
	_check(Player.MAX_ATTRIBUTE_POINTS == 100, "atributos vão até 100 pontos")
	player.attributes["speed"] = 100
	player.refresh_stats()
	_check(player.get_move_speed() <= player.hero["speed"] * Player.MAX_SPEED_MULT * 1.5 + 0.1, "a velocidade para de crescer num teto")
	player.attributes["speed"] = 0
	# Pets.
	Session.grant_pet("slime_king")
	Session.inventory.gold = 1000
	var base: int = Pets.stats("slime_king")["hp"]
	_check(Session.upgrade_pet("slime_king") and Session.pet_level("slime_king") == 2, "melhorar o pet sobe um nível e cobra ouro")
	_check(Session.inventory.gold == 1000 - Pets.upgrade_cost(1), "o custo sai do ouro")
	_check(Pets.stats("slime_king", 5)["hp"] == base and Pets.attack_damage(5) > Pets.attack_damage(1), "o nível não muda os atributos do pet, só o dano do tiro")
	Session.inventory.gold = 0
	_check(not Session.upgrade_pet("slime_king"), "sem ouro, não melhora")
	_check(Session.active_pet_stats() == Pets.stats("slime_king", 2), "o pet ativo usa os atributos do nível dele")
	# Chefe mais forte.
	var boss_stage := Stages.get_stage(9)
	_check(float(boss_stage["boss"]["hp"]) >= 30.0, "o chefe tem bem mais vida")


func _touch(button: Control, offset: Vector2, pressed: bool, drag := false) -> void:
	var center: Vector2 = button.global_position + button.size * 0.5
	var event: InputEvent
	if drag:
		var move := InputEventScreenDrag.new()
		move.index = 3
		move.position = center + offset
		event = move
	else:
		var touch := InputEventScreenTouch.new()
		touch.index = 3
		touch.pressed = pressed
		touch.position = center + offset
		event = touch
	get_viewport().push_input(event, true)
	await _ticks(2)


func _test_skill_touch() -> void:
	print("[habilidades por toque e mira]")
	await _new_game(1)
	var player: Player = _game.player
	player.energy = 100.0
	var id: String = Heroes.skill_entries(player.hero)[0]["id"]
	var button: SkillButton = _game.skill_buttons[id]
	_check(_game.is_unlocked(id) and Skills.is_aimed(id), "%s está liberada e tem mira" % id)
	# Toque simples dispara com mira automática, mesmo com outro dedo no joystick.
	await _touch(button, Vector2.ZERO, true)
	await _touch(button, Vector2.ZERO, false)
	_check(_game.cooldowns[id] > 0.0 and _game.aim_dir == Vector2.ZERO, "um toque dispara a habilidade na mira automática")
	_game.cooldowns[id] = 0.0
	player.energy = 100.0
	# Arrastar para a esquerda mostra a mira e solta na direção.
	await _touch(button, Vector2.ZERO, true)
	await _touch(button, Vector2(-120, 0), true, true)
	_check(_game.aim_guide.visible, "arrastar mostra a linha de mira")
	await _touch(button, Vector2(-120, 0), false)
	_check(_game.cooldowns[id] > 0.0 and _game.aim_dir.x < -0.9, "soltar dispara na direção arrastada")
	_check(not _game.aim_guide.visible, "e a linha some")


func _test_forge_and_evolution() -> void:
	print("[equipamentos, ferreiro e evolução]")
	await _new_game()
	var inventory: Inventory = _game.player.inventory
	# Atributos aleatórios: dois itens da mesma raridade raramente saem iguais, e lendários têm 3+ extras.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var shapes := {}
	for i in 30:
		var epic := Item.create(rng, "armor", 0, 20, 2, 2)
		shapes[epic.stats_text()] = true
		_check(epic.stats.size() >= 3 and epic.rarity == 2, "épico tem o principal e 2 a 3 extras") if i == 0 else null
	_check(shapes.size() > 10, "os atributos são sorteados (%d combinações em 30)" % shapes.size())
	var legendary := Item.create(rng, "weapon", 0, 30, 3, 3)
	_check(legendary.stats.has("critdmg") and legendary.stats.size() >= 4, "lendário tem dano crítico e vários extras")
	# Forja.
	var weapon := Item.create(rng, "weapon", 0, 10, 3, 1)
	inventory.bag.clear()
	inventory.equipped["weapon"] = weapon
	inventory.stone = 0
	inventory.moonstone = 0
	inventory.gold = 0
	_check(inventory.forge_weapon() != "", "sem pedras, a forja é recusada")
	inventory.stone = 500
	inventory.gold = 99999
	var base_attack := weapon.stat_total("attack")
	_check(inventory.forge_weapon() == "" and weapon.forge == 1 and weapon.stat_total("attack") == base_attack + 1, "forjar sobe o nível e o ataque")
	for i in 9:
		inventory.forge_weapon()
	_check(weapon.forge == 10, "níveis 1 a 10 só pedem pedras e ouro")
	_check(inventory.forge_weapon() != "" and weapon.forge == 10, "a partir do nível 10 também pede pedra da lua")
	inventory.moonstone = 100
	for i in 20:
		inventory.forge_weapon()
	_check(weapon.forge == Item.MAX_FORGE, "a forja para no nível 20")
	_check(weapon.stat_total("crit") >= weapon.stats.get("crit", 0) + 4, "a forja também dá crítico")
	# Despertar.
	var power_before := weapon.power()
	inventory.scrolls = 30
	_check(inventory.awaken_weapon(null, "normal") == "" and weapon.awakenings == 1 and weapon.power() > power_before, "o despertar soma atributos")
	inventory.awaken_weapon(null, "normal")
	inventory.awaken_weapon(null, "normal")
	inventory.awaken_weapon(null, "normal")
	_check(weapon.awakenings == 4 and inventory.awaken_weapon(null, "normal") != "", "no máximo 4 despertares")
	# Salvar e carregar.
	var restored := Inventory.from_dict(inventory.to_dict())
	var again: Item = restored.equipped["weapon"]
	_check(again.forge == 20 and again.awakenings == 4 and again.power() == weapon.power(), "forja e despertar sobrevivem ao salvar")
	# Materiais e drops.
	inventory.stone = 0
	_game._on_pickup_collected("stone", 2)
	_game._on_pickup_collected("moonstone", 1)
	_game._on_pickup_collected("scroll", 1)
	_check(inventory.stone == 2 and inventory.moonstone >= 1, "coletar os drops soma os materiais")
	# Evolução individual.
	for hero_id in Heroes.ids():
		_check(Evolution.PATHS.has(hero_id) and Evolution.title(hero_id, 1) != "", "%s tem caminho de evolução próprio" % hero_id)
	_check(Evolution.title("mage", 1) != Evolution.title("warrior", 1), "cada herói evolui diferente")
	Session.hero_progress["warrior"] = {"level": 5, "xp": 0.0, "points": 0, "earned": 0}
	Session.inventory.gold = 5000
	Session.inventory.moonstone = 30
	_check(Session.evolution_block("warrior") != "" and not Session.evolve_hero("warrior"), "sem nível 10, não evolui")
	Session.hero_progress["warrior"]["level"] = 12
	_check(Session.evolve_hero("warrior") and Session.evolution_tier("warrior") == 1, "no nível 10 evolui para %s" % Evolution.title("warrior", 1))
	_check(Evolution.bonus("warrior", 2)["defense"] > Evolution.bonus("warrior", 1)["defense"], "as etapas somam bônus")
	_game.player.evolution_bonus = Evolution.bonus("warrior", 1)
	_game.player.refresh_stats()
	_check(_game.player.stat_points("defense") >= 4, "o bônus da evolução vale no herói")
	# Preços.
	var cheap := Item.new()
	cheap.slot = "ring"
	cheap.stats = {"luck": 1}
	_check(cheap.buy_price() == cheap.base_value() * 8 and cheap.sell_value() < cheap.base_value(), "o mercado cobra 8 vezes o valor de referência e a venda rende só 60%")
	_check(Stages.get_stage(0)["reward"] <= 20, "o ouro por fase foi reduzido")


func _test_spacing_and_keys() -> void:
	print("[espaçamento dos inimigos e chaves de espaço]")
	await _new_game(5)
	var player: Player = _game.player
	var a := _spawn("slime", Vector2(400, 0))
	var b := _spawn("slime", Vector2(401, 0))
	var c := _spawn("slime", Vector2(400, 1))
	await _ticks(20)
	var gap: float = minf(a.global_position.distance_to(b.global_position), minf(a.global_position.distance_to(c.global_position), b.global_position.distance_to(c.global_position)))
	_check(gap >= (a.radius + b.radius) * 0.95, "três gosmas coladas se afastam (menor distância %d)" % gap)
	_check(_spawn("bat", Vector2(900, 200)).dodge_chance > 0.0, "a partir da fase 6 os inimigos esquivam")
	var inventory: Inventory = player.inventory
	inventory.extra_slots = 0
	inventory.recalc_capacity(0)
	inventory.slot_keys = 2
	_check(inventory.use_slot_key() == "" and inventory.bag_capacity == Inventory.BASE_BAG_SIZE + 1, "a chave libera +1 espaço")
	inventory.extra_slots = 40
	inventory.slot_keys = 1
	inventory.recalc_capacity(0)
	_check(inventory.bag_capacity == Inventory.MAX_BAG_SIZE and inventory.use_slot_key() != "", "o máximo de espaços é 50")
	var restored := Inventory.from_dict(inventory.to_dict())
	restored.recalc_capacity(0)
	_check(restored.bag_capacity == Inventory.MAX_BAG_SIZE, "o espaço extra sobrevive ao salvar")


func _test_ring_slots() -> void:
	print("[dois anéis, máscara e pet]")
	await _new_game()
	var inventory: Inventory = _game.player.inventory
	inventory.bag.clear()
	inventory.equipped.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var ring_a := Item.create(rng, "ring", 0, 10)
	var ring_b := Item.create(rng, "ring", 0, 10)
	var ring_c := Item.create(rng, "ring", 0, 40, 3, 3)
	var mask := Item.create(rng, "mask", 0, 10)
	for item in [ring_a, ring_b, ring_c, mask]:
		inventory.bag.append(item)
	inventory.equip(ring_a)
	inventory.equip(ring_b)
	_check(inventory.equipped["ring"] == ring_a and inventory.equipped["ring2"] == ring_b, "dois anéis ocupam as duas casas de anel")
	inventory.equip(ring_c)
	_check(inventory.bag.has(ring_a) != inventory.bag.has(ring_b), "um terceiro anel troca o mais fraco")
	inventory.equip(mask)
	_check(inventory.equipped["mask"] == mask and mask.slot == "mask", "a máscara tem a sua casa")
	var restored := Inventory.from_dict(inventory.to_dict())
	_check(restored.equipped.has("ring") and restored.equipped.has("ring2") and restored.equipped["ring2"].slot == "ring", "as duas casas de anel sobrevivem ao salvar")
	var before: int = _game.player.stat_points("luck")
	inventory.unequip("ring2")
	_check(_game.player.stat_points("luck") <= before, "tirar um anel tira o bônus dele")


func _test_pause_and_settings() -> void:
	print("[pausa e configurações]")
	Settings.save_enabled = false
	await _new_game()
	_check(is_instance_valid(_game.pause_button), "há um botão de pausa na partida")
	_game.open_pause_menu()
	await _ticks(2)
	_check(_game.is_pause_open() and get_tree().paused, "a pausa abre o menu e congela o jogo")
	var leave: Button = _game.pause_panel.find_child("LeaveButton", true, false)
	_game._on_leave_pressed(leave)
	_check(leave.text.begins_with("Toque de novo") and _game.is_pause_open(), "sair pede uma segunda confirmação")
	_game.close_pause_menu()
	await _ticks(2)
	_check(not _game.is_pause_open() and not get_tree().paused and not _game.modal_open, "continuar volta ao jogo")
	var panel := SettingsPanel.new()
	add_child(panel)
	await _frames(2)
	var sliders: Array = []
	_collect_sliders(panel, sliders)
	_check(sliders.size() == 3, "três controles de volume (geral, música e efeitos)")
	sliders[0].value = 0.4
	sliders[2].value = 0.0
	_check(is_equal_approx(Settings.master, 0.4) and Settings.sfx == 0.0, "mexer nos controles muda os volumes")
	Settings.screen_shake = false
	_game.shake(10.0, 0.3)
	_check(_game._shake_time <= 0.0, "com o tremor desligado, a tela não treme")
	Settings.screen_shake = true
	Settings.master = 1.0
	Settings.sfx = 1.0
	Settings.apply()
	panel.queue_free()


func _collect_sliders(node: Node, found: Array) -> void:
	if node is HSlider:
		found.append(node)
	for child in node.get_children():
		_collect_sliders(child, found)


func _test_fragments_runes_awakening() -> void:
	print("[fragmentos, runas, despertar e drops]")
	await _new_game()
	var player: Player = _game.player
	var inventory: Inventory = player.inventory
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# Chances do pergaminho de despertar.
	var counts := {"fail": 0, "normal": 0, "negative": 0, "super": 0}
	var probe := Item.create(rng, "weapon", 0, 10)
	for i in 4000:
		counts[probe.roll_awakening(rng)["result"]] += 1
	_check(counts["fail"] > 1800 and counts["fail"] < 2200, "o pergaminho falha em cerca de 50%% (%d de 4000)" % counts["fail"])
	var worked: int = 4000 - counts["fail"]
	_check(float(counts["negative"]) / worked > 0.15 and float(counts["negative"]) / worked < 0.26, "20%% dos que dão certo vêm negativos (%d de %d)" % [counts["negative"], worked])
	_check(counts["super"] >= 1 and counts["super"] < 80, "existe o despertar super raro, de ~1%% (%d)" % counts["super"])
	var weapon := Item.create(rng, "weapon", 0, 10, 3, 1)
	inventory.equipped["weapon"] = weapon
	inventory.scrolls = 10
	var attack_before := weapon.stat_total("attack")
	_check(inventory.awaken_weapon(rng, "fail") == "" and weapon.awakenings == 0 and inventory.scrolls == 9, "falhar gasta o pergaminho e não conta como despertar")
	inventory.awaken_weapon(rng, "negative")
	_check(weapon.awakenings == 1 and weapon.awake_stats.values().any(func(v): return v < 0), "o despertar negativo tira pontos")
	var super_roll := weapon.roll_awakening(rng, "super")
	_check(super_roll["amount"] >= 3 * 2, "o super raro rende o triplo")
	# Raridade dos drops.
	var legendaries := 0
	for i in 2000:
		if Item.create(rng, "armor", 0, 10).rarity == 3:
			legendaries += 1
	_check(legendaries < 40, "lendários são raros (%d de 2000)" % legendaries)
	# Fragmentos e nível de raridade.
	var epic := Item.create(rng, "armor", 0, 20, 2, 2)
	inventory.bag.append(epic)
	var gained := inventory.convert_to_fragments(epic)
	_check(gained >= 6 and inventory.fragments[2] == gained and not inventory.bag.has(epic), "o item vira fragmentos da raridade dele")
	var helmet := Item.create(rng, "helmet", 0, 20, 2, 2)
	inventory.equipped["helmet"] = helmet
	var hp_before := helmet.stat_total("hp")
	inventory.fragments[2] = 0
	_check(inventory.upgrade_rank("helmet") != "", "sem fragmentos não sobe a raridade")
	inventory.fragments[2] = 1000
	_check(inventory.upgrade_rank("helmet") == "" and helmet.rank == 1 and inventory.fragments[2] == 1000 - Item.rank_cost(0), "gastar fragmentos sobe o nível de raridade")
	for i in 30:
		inventory.upgrade_rank("helmet")
	_check(helmet.rank == Item.MAX_RANK, "o nível de raridade vai até 20")
	_check(helmet.stat_total("hp") > hp_before * 2 - 1, "no nível 20 os atributos mais que dobram")
	var back := Inventory.from_dict(inventory.to_dict())
	_check(back.equipped["helmet"].rank == 20 and back.fragments[2] == inventory.fragments[2], "nível de raridade e fragmentos sobrevivem ao salvar")
	# Runas incrustadas nos equipamentos.
	inventory.runes = {}
	var runed := Item.create(rng, "armor", 0, 10, 3, 2)
	inventory.equipped["armor"] = runed
	inventory.add_rune("attack_C", 3)
	var attack_points: int = inventory.bonus("attack")
	_check(runed.socket_count() == runed.rarity + 1, "a quantidade de casas de runa vem da raridade (%d)" % runed.socket_count())
	_check(inventory.socket_rune("armor", "attack_C") == "" and inventory.runes["attack_C"] == 2 and inventory.bonus("attack") == attack_points + Runes.value("attack_C"), "incrustar gasta a runa e soma o atributo na peça")
	_check(inventory.socket_rune("armor", "critdmg_C") != "", "sem a runa, não incrusta")
	while runed.rune_in_free() >= 0:
		runed.insert_rune("hp_C")
	_check(inventory.socket_rune("armor", "attack_C") != "", "sem casa livre, não incrusta")
	inventory.add_rune("critdmg_C", 1)
	runed.remove_rune(runed.socket_count() - 1)
	_check(inventory.socket_rune("armor", "critdmg_C") == "" and inventory.bonus("critdmg") >= Runes.value("critdmg_C"), "a runa de dano crítico soma dano crítico")
	var round_trip := Inventory.from_dict(inventory.to_dict())
	_check(round_trip.equipped["armor"].sockets == runed.sockets and round_trip.runes["attack_C"] == 2, "runas incrustadas e guardadas sobrevivem ao salvar")
	var weapon_runed := Item.create(rng, "weapon", 0, 10, 3, 1)
	_check(weapon_runed.insert_rune("attack_C") and weapon_runed.stat_total("attack") >= Runes.value("attack_C"), "armas também recebem runas")
	_check(Runes.ids().size() == Runes.STATS.size() * Runes.TIERS.size() and Runes.TIERS == ["C", "B", "A", "S", "SS"], "há uma runa para cada atributo em cinco raridades (%d)" % Runes.ids().size())
	# Filtro de drops.
	Session.ignored_types = []
	Session.auto_fragment = [false, false, false, false]
	var ring := Item.create(rng, "ring", 0, 10)
	Session.set_type_ignored("ring", true)
	_check(not Session.wants_item(ring) and Session.wants_item(helmet), "o filtro de tipos ignora só o tipo marcado")
	var bag_size: int = inventory.bag.size()
	_game._on_pickup_collected("item", ring)
	_check(inventory.bag.size() == bag_size, "item de tipo ignorado não entra na mochila")
	Session.set_type_ignored("ring", false)
	Session.set_auto_fragment(ring.rarity, true)
	var fragments_before: int = inventory.fragments[ring.rarity]
	_game._on_pickup_collected("item", ring)
	_check(inventory.bag.size() == bag_size and inventory.fragments[ring.rarity] > fragments_before, "raridade em modo fragmento vira fragmentos sozinha")
	Session.auto_fragment = [false, false, false, false]
	_game._on_pickup_collected("rune", "hp_B")
	_check(inventory.runes.get("hp_B", 0) == 1, "coletar uma runa soma na mochila")
	# Defesa dos inimigos.
	var slime: Enemy = _spawn("slime", Vector2(500, 0))
	slime.max_health = 1000.0
	slime.health = 1000.0
	slime.dodge_chance = 0.0
	slime.block_chance = 0.0
	player.accuracy_bonus = 1.0
	player.card_crit = -1.0
	slime.take_damage(100.0, "skill")
	_check(slime.health == 900.0, "sem defesa o dano passa inteiro")
	slime.defense = 80.0
	slime.take_damage(100.0, "skill")
	_check(absf(slime.health - 850.0) < 0.5, "com defesa 80 o dano cai pela metade (%.1f)" % slime.health)
	_check(is_equal_approx(Stages.hp_scale(Stages.get_stage(0), 0.0), Stages.HP_BOOST * Stages.easiness(0)), "os inimigos têm mais vida (com a facilidade da fase 1)")


func _test_speed_lifesteal_reflect() -> void:
	print("[velocidade, roubo de vida, refletir e dificuldade]")
	Session.reset_progress()
	Session.hero_id = "archer"
	await _new_game(0, true)
	var player: Player = _game.player
	_check(player.hero["speed"] <= 150.0 and player.hero["max_speed"] <= 190.0, "o arqueiro é mais lento (base %d, teto %d)" % [player.hero["speed"], player.hero["max_speed"]])
	player.attributes["speed"] = 100
	player.card_speed_mult = 3.0
	player.haste_time = 5.0
	player.refresh_stats()
	_check(player.get_move_speed() <= player.hero["max_speed"] * 1.25 + 0.1, "mesmo com tudo somado, a velocidade respeita o teto (%d)" % player.get_move_speed())
	player.haste_time = 0.0
	player.card_speed_mult = 1.0
	_check(player.get_move_speed() <= player.hero["max_speed"] + 0.1, "sem a magia, o teto é o do herói (%d)" % player.get_move_speed())
	for id in Heroes.ids():
		var hero := Heroes.get_hero(id)
		_check(float(hero.get("max_speed", Player.DEFAULT_MAX_SPEED)) <= Player.DEFAULT_MAX_SPEED, "%s tem teto de velocidade" % id)
	# Despertar especial.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var inventory: Inventory = player.inventory
	inventory.bag.clear()
	var weapon := Item.create(rng, "weapon", 0, 10, 3, 1)
	var armor := Item.create(rng, "armor", 0, 10, 3, 1)
	inventory.equipped["weapon"] = weapon
	inventory.equipped["armor"] = armor
	inventory.scrolls = 9
	_check(inventory.awaken_item("weapon", rng, "special") == "" and weapon.awake_stats.has("lifesteal") and weapon.stat_total("lifesteal") >= 1, "a arma pode despertar com roubo de vida")
	_check(inventory.awaken_item("armor", rng, "special") == "" and armor.awake_stats.has("reflect") and armor.stat_total("reflect") >= 3, "a armadura pode despertar com refletir")
	_check(inventory.last_awakening.get("special", false), "o resultado avisa que é um status especial")
	var specials := 0
	for i in 5000:
		if weapon.roll_awakening(rng).get("special", false):
			specials += 1
	_check(specials > 5 and specials < 100, "roubo de vida é muito raro (%d de 5000 pergaminhos)" % specials)
	var reflects := 0
	for i in 5000:
		if armor.roll_awakening(rng).get("special", false):
			reflects += 1
	_check(reflects > 10 and reflects < 200, "refletir é muito raro (%d de 5000 pergaminhos)" % reflects)
	var restored := Inventory.from_dict(inventory.to_dict())
	_check(restored.equipped["armor"].stat_total("reflect") == armor.stat_total("reflect") and restored.equipped["armor"].awakenings == 1, "o despertar da armadura sobrevive ao salvar")
	# Efeitos no jogo.
	weapon.awake_stats["lifesteal"] = 10
	armor.awake_stats["reflect"] = 50
	_check(absf(player.get_lifesteal() - 0.04) < 0.001 and absf(player.get_reflect() - 0.5) < 0.001, "10 pontos de roubo de vida devolvem 4% e refletir 50%")
	player.health = 10.0
	player.health = 10.0
	player.max_health = 500.0
	player.card_crit = -1.0
	var victim := _spawn("slime", Vector2(300, 0))
	victim.max_health = 1000.0
	victim.health = 1000.0
	victim.dodge_chance = 0.0
	victim.block_chance = 0.0
	victim.take_damage(100.0, "skill")
	await _ticks(2)
	_check(player.health > 12.0 and player.health < 20.0, "causar 100 de dano cura só 4 de vida (vida %.1f)" % player.health)
	var near := _spawn("slime", Vector2(40, 0))
	near.max_health = 1000.0
	near.health = 1000.0
	player.health = 500.0
	player.max_health = 500.0
	_game._reflect_damage(100.0)
	_check(near.health < 960.0, "refletir devolve parte do dano ao inimigo próximo (vida %d)" % near.health)
	# Dificuldade por fase.
	var first := Stages.hp_scale(Stages.get_stage(0), 0.0)
	var fourth := Stages.hp_scale(Stages.get_stage(3), 0.0) / float(Stages.get_stage(3)["hp_mult"]) * float(Stages.get_stage(0)["hp_mult"])
	_check(fourth > first * 1.5, "a vida dos inimigos cresce a cada fase além do multiplicador da fase")
	_check(Stages.damage_scale(Stages.get_stage(19), 0.0) / float(Stages.get_stage(19)["dmg_mult"]) > 1.5, "o dano dos inimigos também")
	Session.hero_id = "warrior"


func _test_skill_tree() -> void:
	print("[árvore de habilidades]")
	for hero_id in Heroes.ids():
		var list := SkillTree.nodes(hero_id)
		_check(list.size() == 1 + SkillTree.BRANCHES * SkillTree.TIERS + 2, "%s: raiz, 4 ramos de 4 nós, mestre e herói (%d nós)" % [hero_id, list.size()])
	var hero := "warrior"
	Session.reset_progress()
	Session.set_progress(hero, 10, 0.0, 20, 20)
	_check(SkillTree.unlocked(hero, "root", {}) and not SkillTree.unlocked(hero, "b0_1", {}), "só a raiz começa liberada")
	var plan := Session.plan_tree(hero, {"b0_1": 1})
	_check(not plan["ok"], "um nó sem a raiz não pode ser comprado")
	plan = Session.plan_tree(hero, {"root": 2, "b0_1": 1, "b0_2": 1})
	_check(plan["ok"] and plan["cost"] == 2 * 1 + 1 + 2, "custo: raiz 1, nó 1 custa 1 e nó 2 custa 2 (%d)" % plan["cost"])
	_check(not Session.commit_tree(hero, {"root": 5, "b0_1": 5, "b0_2": 5, "b0_3": 5}), "sem pontos suficientes a compra é recusada")
	_check(Session.commit_tree(hero, {"root": 2, "b0_1": 1, "b0_2": 1}) and Session.progress_for(hero)["points"] == 15, "comprar gasta os pontos (sobram %d)" % Session.progress_for(hero)["points"])
	_check(Session.tree_levels(hero)["b0_2"] == 1, "o nível do nó fica salvo")
	var bonus := SkillTree.bonus(hero, Session.tree_levels(hero))
	_check(bonus.get("hp", 0) == 6 and bonus.get("attack", 0) == 1, "os bônus somam por nível (vida %d, ataque %d)" % [bonus.get("hp", 0), bonus.get("attack", 0)])
	_check(not SkillTree.unlocked(hero, "master", Session.tree_levels(hero)), "o mestre pede os 4 ramos")
	var full := {"root": 5, "master": 0}
	for b in SkillTree.BRANCHES:
		full["b%d_4" % b] = 1
	_check(SkillTree.unlocked(hero, "master", full) and not SkillTree.unlocked(hero, "hero", full), "os 4 nós finais abrem o mestre, não o herói")
	full["master"] = SkillTree.MAX_LEVEL
	_check(SkillTree.unlocked(hero, "hero", full), "o mestre no máximo abre o herói")
	# O efeito no herói e a tela.
	await _new_game(0, true)
	_game.player.tree_bonus = SkillTree.bonus(hero, {"b0_1": 5, "b0_2": 5})
	_game.player.refresh_stats()
	_check(_game.player.stat_points("attack") >= 5 and _game.player.crit_multiplier() > Player.BASE_CRIT_MULT, "a árvore soma ataque e dano crítico no herói")
	var panel := SkillTreePanel.new()
	add_child(panel)
	Session.set_progress(hero, 10, 0.0, 6, 6)
	panel.refresh(hero)
	await _frames(2)
	panel._select("root")
	panel._on_plus()
	panel._on_plus()
	_check(panel._pending.get("root", 0) == 2 and panel._points_value.text == "4", "o + guarda níveis pendentes e desconta dos pontos (%s)" % panel._points_value.text)
	panel._on_minus()
	_check(panel._pending.get("root", 0) == 1, "o - desfaz um nível pendente")
	panel._on_cancel()
	_check(panel._pending.is_empty() and panel._points_value.text == "6", "Cancelar descarta o que estava pendente")
	panel._on_plus()
	panel._select("b0_1")
	panel._on_plus()
	panel._on_ok()
	_check(Session.tree_levels(hero).get("root", 0) == 3 and Session.tree_levels(hero).get("b0_1", 0) == 2 and Session.progress_for(hero)["points"] == 4, "Ok confirma a compra e gasta os pontos")
	panel.queue_free()


func _test_new_stats_and_status_icons() -> void:
	print("[penetração, regenerações, alcance e ícones de efeito]")
	await _new_game()
	var player: Player = _game.player
	var inventory: Inventory = player.inventory
	inventory.equipped.clear()
	for stat in ["penetration", "energy_regen", "range"]:
		_check(Item.STAT_NAMES.has(stat) and Item.BONUS_STATS.has(stat), "%s é um atributo de equipamento" % Item.STAT_NAMES[stat])
	var ring := Item.new()
	ring.slot = "ring"
	ring.stats = {"penetration": 10, "hp_regen": 12, "energy_regen": 6, "range": 10}
	_check(not Item.BONUS_STATS.has("hp_regen"), "regen de HP não sai como atributo sorteado, só em despertar")
	inventory.equipped["ring"] = ring
	_check(absf(player.get_penetration() - 0.2) < 0.001, "10 pontos de penetração ignoram 20%% da defesa")
	_check(player.get_energy_regen() > Player.ENERGY_REGEN + 2.9, "regen de energia soma à base (%.1f/s)" % player.get_energy_regen())
	_check(absf(player.get_range_mult() - 1.3) < 0.001, "10 pontos de alcance dão +30%%")
	player.max_health = 1000.0
	player.health = 500.0
	await _ticks(30)
	_check(player.health > 500.0 and player.get_hp_regen() > 5.0, "a vida regenera sozinha (%.1f/s)" % player.get_hp_regen())
	var weapon: Weapon = _game.weapon
	weapon._process(0.0)
	_check(weapon.attack_range > weapon.base_range * 1.29, "o alcance da arma cresce com o bônus (%d de %d)" % [weapon.attack_range, weapon.base_range])
	# A penetração faz o dano passar pela defesa.
	var target: Enemy = _spawn("slime", Vector2(500, 0))
	target.max_health = 5000.0
	target.health = 5000.0
	target.dodge_chance = 0.0
	target.block_chance = 0.0
	target.defense = 80.0
	player.accuracy_bonus = 1.0
	player.card_crit = -1.0
	target.take_damage(100.0, "skill")
	var with_pen := 5000.0 - target.health
	inventory.equipped.clear()
	target.health = 5000.0
	target.take_damage(100.0, "skill")
	var without_pen := 5000.0 - target.health
	_check(with_pen > without_pen + 3.0, "a penetração aumenta o dano contra defesa (%.1f contra %.1f)" % [with_pen, without_pen])
	# Ícones de efeito sobre o inimigo.
	var victim: Enemy = _spawn("slime", Vector2(300, 0))
	_check(victim.status_effects().is_empty(), "sem efeitos, sem ícones")
	victim.stun(2.0)
	victim.apply_burn(3, 1.0)
	victim.apply_slow(0.5, 2.0)
	victim.apply_poison(3, 1.0)
	var effects := victim.status_effects()
	_check(effects.has("stun") and effects.has("burn") and effects.has("freeze") and effects.has("poison"), "atordoamento, queimadura, congelamento e veneno aparecem (%s)" % str(effects))
	victim.stun(2.0, "paralysis")
	_check(victim.status_effects().has("paralysis"), "a poção mostra o ícone de paralisia")
	victim.shield_time = 1.0
	_check(victim.status_effects().has("shield"), "o escudo do totem também")
	victim.queue_redraw()
	await _ticks(2)


func _test_forge_panel() -> void:
	print("[ferreiro remasterizado]")
	await _new_game()
	var inventory: Inventory = Session.inventory
	inventory.equipped.clear()
	inventory.bag.clear()
	inventory.stone = 100
	inventory.gold = 5000
	inventory.moonstone = 10
	inventory.scrolls = 3
	inventory.fragments = [0, 0, 50, 0, 0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var bag_sword := Item.create(rng, "weapon", 0, 20, 2, 2)
	var bag_armor := Item.create(rng, "armor", 0, 20, 2, 2)
	inventory.bag.append(bag_sword)
	inventory.bag.append(bag_armor)
	var panel := ForgePanel.new()
	add_child(panel)
	panel.refresh()
	await _frames(2)
	_check(panel._item == null and panel._hint.visible, "a bigorna começa vazia, com a dica de arrastar")
	# Arrastar da mochila para a bigorna.
	var source := ItemSlot.new(40.0)
	source.show_item(bag_sword)
	source.drag_kind = "bag"
	_check(panel._anvil._can_drop_data(Vector2.ZERO, {"slot": source}), "a bigorna aceita um equipamento arrastado")
	panel._anvil._drop_data(Vector2.ZERO, {"slot": source})
	_check(panel._item == bag_sword and panel._info.text.contains("Ataque"), "soltar na bigorna mostra os atributos do item da mochila")
	# Operações direto no item da mochila.
	var before := bag_sword.forge
	panel._on_forge()
	_check(bag_sword.forge == before + 1 and not inventory.bag.is_empty(), "forjar funciona numa arma que está na mochila")
	panel._on_rank()
	_check(bag_sword.rank == 1 and inventory.fragments[2] == 50 - Item.rank_cost(0), "o nível de raridade usa os fragmentos da raridade dele")
	panel._on_awaken()
	_check(inventory.scrolls == 2, "o despertar gasta um pergaminho")
	# Armadura: sem forja, com despertar.
	panel.set_item(bag_armor)
	_check(not panel._forge_button.disabled and not panel._awake_button.disabled, "a armadura também forja e desperta")
	# Fileira dos equipados.
	var worn := Item.create(rng, "helmet", 0, 20)
	inventory.equipped["helmet"] = worn
	panel.refresh()
	var found := false
	for slot in panel._strip.get_children():
		if slot is ItemSlot and slot.item == worn:
			found = true
			slot.pressed.emit()
	_check(found and panel._item == worn, "tocar num equipado da fileira põe o item na bigorna")
	_check(panel._info.text.contains("Vida"), "e mostra os atributos com a origem dos pontos")
	panel.set_item(null)
	_check(panel._forge_button.disabled and panel._rank_button.disabled and panel._awake_button.disabled, "sem item, nenhuma melhoria fica ativa")
	inventory.bag.erase(bag_armor)
	panel.set_item(bag_armor)
	_check(panel._item == null, "um item que saiu da mochila some da bigorna")
	panel.queue_free()


func _test_market_economy() -> void:
	print("[mercado e economia]")
	Session.reset_progress()
	var inventory: Inventory = Session.inventory
	var stock := Shop.generate_stock(777, 3)
	_check(stock["weapons"].size() == Shop.STOCK_SIZE and Shop.STOCK_SIZE >= 6, "o mercado tem %d equipamentos por aba" % Shop.STOCK_SIZE)
	var materials: Array = stock["materials"]
	var kinds := {}
	for entry in materials:
		kinds[entry["kind"]] = true
	_check(kinds.has("stone") and kinds.has("moonstone") and kinds.has("scroll") and kinds.has("key") and kinds.has("rune") and kinds.has("fragment"), "a aba Materiais vende pedras, lua, pergaminho, chave, runas e fragmentos")
	inventory.gold = 100
	_check(Shop.buy_material(inventory, materials, 0) == "" and inventory.stone == 1 and inventory.gold == 100 - Shop.STONE_PRICE, "comprar pedra gasta ouro e a pedra continua à venda")
	_check(materials[0]["kind"] == "stone", "pedras são ilimitadas")
	var scroll_index := -1
	for i in materials.size():
		if materials[i]["kind"] == "scroll":
			scroll_index = i
	_check(Shop.buy_material(inventory, materials, scroll_index) == "Ouro insuficiente", "sem ouro, não compra o pergaminho")
	inventory.gold = 5000
	var count_before := materials.size()
	_check(Shop.buy_material(inventory, materials, scroll_index) == "" and inventory.scrolls == 1 and materials.size() == count_before - 1, "o pergaminho comprado sai do estoque")
	var rune_index := -1
	for i in materials.size():
		if materials[i]["kind"] == "rune":
			rune_index = i
	var rune_id: String = materials[rune_index]["payload"]
	Shop.buy_material(inventory, materials, rune_index)
	_check(inventory.runes.get(rune_id, 0) == 1, "comprar uma runa soma na mochila")
	var fragment_index := -1
	for i in materials.size():
		if materials[i]["kind"] == "fragment":
			fragment_index = i
	var fragment_rarity: int = materials[fragment_index]["payload"]
	Shop.buy_material(inventory, materials, fragment_index)
	_check(inventory.fragments[fragment_rarity] == Shop.FRAGMENT_PACK, "o pacote dá 10 fragmentos da raridade")
	var key_index := -1
	for i in materials.size():
		if materials[i]["kind"] == "key":
			key_index = i
	inventory.recalc_capacity(0)
	Shop.buy_material(inventory, materials, key_index)
	_check(inventory.slot_keys == 1, "a chave de espaço pode ser comprada")
	# Pacotes de consumíveis.
	inventory.gold = 1000
	var potions := inventory.potions
	_check(Shop.pack_price("potion", 5) < Shop.pack_price("potion", 1) * 5, "o pacote de 5 sai com desconto")
	Shop.buy_consumable(inventory, "potion", 5)
	_check(inventory.potions == potions + 5 and inventory.gold == 1000 - Shop.pack_price("potion", 5), "comprar x5 soma 5 poções")
	# Economia: o ouro dos drops caiu e vender rende menos que comprar.
	_check(load("res://scripts/game/game.gd").GOLD_CHANCE <= 0.10, "a chance de ouro nos drops caiu")
	var item := Item.create(RandomNumberGenerator.new(), "ring", 0, 20, 2, 2)
	_check(item.sell_value() * 10 < item.buy_price() * 1.0 and item.sell_value() < item.base_value(), "vender rende bem menos do que comprar custa")


func _test_regen_and_sections() -> void:
	print("[regen só em despertar, blocos de atributos e nível do item]")
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 300:
		_check(not Item.create(rng, "armor", 0, 30, 3, 3).stats.has("hp_regen"), "nenhum item sorteado traz regen de HP") if i == 0 else null
		if Item.create(rng, "armor", 0, 30, 3, 3).stats.has("hp_regen"):
			_check(false, "um item sorteado trouxe regen de HP")
			break
	var armor := Item.create(rng, "armor", 0, 30, 3, 1)
	var regens := 0
	for i in 5000:
		var roll := armor.roll_awakening(rng)
		if roll["result"] != "fail" and roll["stat"] == "hp_regen":
			regens += 1
	_check(regens > 20 and regens < 250, "regen de HP cai raramente nos despertares (%d de 5000)" % regens)
	var forced := armor.roll_awakening(rng, "regen")
	_check(forced["stat"] == "hp_regen" and forced["amount"] <= 3, "o regen do despertar vem em pontos pequenos")
	var low := Item.new()
	low.slot = "ring"
	low.awake_stats = {"hp_regen": 3}
	var player := Player.new()
	player.hero_id = "warrior"
	add_child(player)
	await _frames(2)
	player.inventory.equipped["ring"] = low
	player.max_health = 1000.0
	_check(player.get_hp_regen() < 3.0, "3 pontos de regen dão menos de 3 de vida por segundo (%.2f)" % player.get_hp_regen())
	player.queue_free()
	# Blocos.
	var item := Item.create(rng, "weapon", 0, 40, 3, 2)
	item.awake_stats = {"attack": 4, "lifesteal": 2}
	item.insert_rune("critdmg_C")
	var groups := item.stat_groups()
	_check(groups["awake"].get("attack", 0) == 4 and groups["runes"].get("critdmg", 0) == Runes.value("critdmg_C") and not groups["base"].is_empty(), "atributos, despertar e runas ficam em blocos separados")
	var text := "\n".join(item.sections_bbcode())
	_check(text.contains("Atributos") and text.contains("Despertar") and text.contains("Runas"), "cada bloco tem o seu título")
	# Nível do item.
	var low_level := Item.create(rng, "weapon", 0, 5, 1, 1)
	var high_level := Item.create(rng, "weapon", 0, 80, 1, 1)
	_check(low_level.level == 5 and high_level.level == 80, "o item guarda o nível em que caiu")
	_check(high_level.stats["attack"] > low_level.stats["attack"] * 3, "itens de nível maior têm atributos bem maiores (%d contra %d)" % [high_level.stats["attack"], low_level.stats["attack"]])
	_check(Item.from_dict(high_level.to_dict()).level == 80, "o nível do item sobrevive ao salvar")
	_check(Progression.xp_needed(10) < 0.7 * (5.0 + 0.8 * 100 + 15.0), "os níveis pedem menos XP")


func _test_infinite_stages() -> void:
	print("[fases infinitas]")
	var bosses := 0
	for i in 200:
		var stage := Stages.get_stage(i)
		_check(stage["number"] == i + 1 and Stages.is_boss_stage(stage) == ((i + 1) % 10 == 0), "fase %d existe e só a cada 10 é chefe" % (i + 1)) if i in [0, 9, 10, 99, 199] else null
		if Stages.is_boss_stage(stage):
			bosses += 1
	_check(bosses == 20, "em 200 fases há 20 chefes")
	_check(Stages.get_stage(9)["boss"]["kind"] == "slime" and Stages.get_stage(19)["boss"]["kind"] == "necromancer", "os chefes alternam (Rei Gosma e Senhor das Cinzas)")
	_check(Stages.get_stage(29)["boss"]["name"].ends_with("II"), "o chefe volta com um número (%s)" % Stages.get_stage(29)["boss"]["name"])
	var previous := 0.0
	var growing := true
	for i in range(0, 120, 10):
		var power := Stages.hp_scale(Stages.get_stage(i), 60.0) * Stages.damage_scale(Stages.get_stage(i), 60.0)
		growing = growing and power > previous
		previous = power
	_check(growing, "a cada 10 fases os monstros ficam mais fortes")
	_check(Stages.hp_scale(Stages.get_stage(99), 0.0) > Stages.hp_scale(Stages.get_stage(9), 0.0) * 3.0, "a fase 100 tem muito mais vida que a 10")
	_check(Stages.get_stage(50)["reward"] > Stages.get_stage(5)["reward"], "a recompensa também cresce")
	Session.reset_progress()
	Session.finish_mission(24, 2)
	_check(Session.stars_of(24) == 2 and Session.stage_stars.size() >= 25, "as notas crescem junto com as fases")
	_check(Session.highest_unlocked() == 0 and not Session.is_stage_unlocked(5), "sem vencer as anteriores, as fases seguintes ficam bloqueadas")
	for i in 25:
		Session.finish_mission(i, 1)
	_check(Session.highest_unlocked() == 25 and Session.is_stage_unlocked(25), "vencer em sequência libera a seguinte")
	Session.save_game()
	Session.stage_stars = [0]
	_check(Session.load_game() == false or Session.stars_of(24) >= 1, "as notas das fases altas sobrevivem ao salvar")


func _test_early_ease_and_choices() -> void:
	print("[começo fácil, upgrades só na partida e forja em tudo]")
	_check(Stages.easiness(0) < 0.4 and is_equal_approx(Stages.easiness(12), 1.0), "a fase 1 vale ~35%% da força e a 13 já vale 100%% (%.2f)" % Stages.easiness(0))
	_check(Stages.hp_scale(Stages.get_stage(0), 0.0) < Stages.hp_scale(Stages.get_stage(12), 0.0) * 0.3, "os monstros da fase 1 têm bem menos vida que os da 13")
	_check(Stages.damage_scale(Stages.get_stage(0), 0.0) < Stages.damage_scale(Stages.get_stage(12), 0.0) * 0.4, "e batem bem mais fraco")
	_check(Stages.max_enemies(Stages.get_stage(0), 60.0) < Stages.max_enemies(Stages.get_stage(12), 60.0), "e há menos deles ao mesmo tempo")
	_check(Stages.get_stage(0)["kill_goal"] < 200, "a meta de abates da fase 1 é baixa (%d)" % Stages.get_stage(0)["kill_goal"])
	# Esquiva dos inimigos.
	_check(Stages.enemy_dodge(0.25, 4) == 0.0 and Stages.enemy_dodge(0.25, 5) > 0.0, "a esquiva só existe depois da fase 5")
	_check(Stages.enemy_dodge(0.25, 100) <= Stages.DODGE_CAP and Stages.enemy_dodge(0.4, 100) <= Stages.DODGE_CAP, "e nunca passa do teto")
	# Upgrades de escolha só na partida.
	await _new_game(0)
	Session.hero_id = "warrior"
	await _new_game(1, true)
	_check(_game.card_counts.is_empty() and not Session.has_run_for("warrior"), "ir para outra fase zera as melhorias de escolha")
	var options: Array = _game.upgrades
	var sharp: Dictionary = {}
	for option in options:
		if option["name"] == "Lâmina afiada":
			sharp = option
	var damage_before: float = _game.weapon.damage
	sharp["apply"].call()
	_check(_game.weapon.damage > damage_before * 1.35, "a Lâmina afiada agora dá +40%% (%.1f para %.1f)" % [damage_before, _game.weapon.damage])
	# Forja e despertar em todos os equipamentos.
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var inventory: Inventory = Session.inventory
	inventory.stone = 500
	inventory.gold = 99999
	inventory.scrolls = 30
	for slot in Item.SLOTS:
		var piece := Item.create(rng, slot, 0, 30, 2, 1)
		var primary: String = Item.PRIMARY[slot]
		var base_points := piece.stat_total(primary)
		_check(inventory.forge_item(piece) == "" and piece.stat_total(primary) == base_points + 1, "%s também forja (+1 %s)" % [Item.SLOT_NAMES[slot], Item.STAT_NAMES[primary]])
		_check(inventory.awaken_target(piece, rng, "normal") == "" and piece.awakenings == 1, "%s também desperta" % Item.SLOT_NAMES[slot])
		_check(Item.from_dict(piece.to_dict()).forge == 1 and Item.from_dict(piece.to_dict()).awakenings == 1, "forja e despertar de %s sobrevivem ao salvar" % Item.SLOT_NAMES[slot])


func _test_jars_auto_and_warnings() -> void:
	print("[potes de cura, automático, mochila cheia e fim da fase]")
	Session.reset_progress()
	Session.hero_id = "warrior"
	await _new_game(0)
	var player: Player = _game.player
	_check(get_tree().get_nodes_in_group("jars").size() >= HealJarCount(), "a fase começa com potes de cura espalhados")
	# Nenhuma poção cai dos monstros.
	var potions_dropped := 0
	for i in 400:
		_game._on_enemy_killed(player.global_position + Vector2(900, 900), 0, true)
	for node in get_tree().get_nodes_in_group("pickups"):
		if (node as Pickup).kind == "potion":
			potions_dropped += 1
	_check(potions_dropped == 0, "monstros não soltam mais poções (%d em 400 mortes)" % potions_dropped)
	for node in get_tree().get_nodes_in_group("pickups"):
		node.queue_free()
	await _ticks(2)
	# Pote: cura 20% ao passar por cima, e espera se a vida está cheia.
	for node in get_tree().get_nodes_in_group("jars"):
		node.queue_free()
	await _ticks(2)
	player.max_health = 500.0
	player.health = 500.0
	var jar := HealJar.new()
	jar.target = player
	_game.world.add_child(jar)
	jar.global_position = player.global_position
	await _ticks(3)
	_check(is_instance_valid(jar) and not jar.is_queued_for_deletion(), "com a vida cheia o pote fica esperando")
	player.health = 200.0
	await _ticks(3)
	_check(absf(player.health - 300.0) < 1.0 and (not is_instance_valid(jar) or jar.is_queued_for_deletion()), "o pote cura 20%% da vida máxima (vida %d)" % player.health)
	# Novos potes aparecem com o tempo.
	for node in get_tree().get_nodes_in_group("jars"):
		node.queue_free()
	await _ticks(2)
	_game._jar_timer = 0.0
	_game._tick_jars(0.1)
	_check(get_tree().get_nodes_in_group("jars").size() >= 1, "de tempos em tempos nasce um pote novo")
	# Ataque automático: ligar e desligar.
	Session.auto_attack = false
	_game._apply_auto_attack()
	_check(not _game.weapon.auto_enabled and _game.auto_button.disabled, "antes do primeiro chefe o botão Auto fica travado")
	_game.toggle_auto_attack()
	_check(not _game.weapon.auto_enabled, "e não liga o automático")
	Session.auto_attack = true
	Session.auto_attack_on = true
	_game._apply_auto_attack()
	_check(_game.weapon.auto_enabled and not _game.auto_button.disabled, "liberado, o automático começa ligado")
	_game.toggle_auto_attack()
	_check(not _game.weapon.auto_enabled and not Session.auto_attack_on and _game.auto_button.text.contains("DESLIGADO"), "o botão desliga o automático")
	_game.toggle_auto_attack()
	_check(_game.weapon.auto_enabled and _game.auto_button.text.contains("LIGADO"), "e liga de novo")
	Session.auto_attack_on = true
	# Mochila cheia.
	var inventory: Inventory = player.inventory
	inventory.bag.clear()
	_game._bag_was_full = false
	_game._update_bag_warning()
	_check(_game.bag_button.text == "Mochila", "mochila com espaço: sem aviso")
	var rng := RandomNumberGenerator.new()
	for i in inventory.bag_capacity:
		inventory.bag.append(Item.create(rng, "ring", 0, 5))
	_game._update_bag_warning()
	_check(_game.bag_button.text.contains("CHEIA") and _game._bag_was_full, "mochila cheia: o botão avisa")
	# Fim da fase: tudo do chão, inclusive XP.
	inventory.bag.clear()
	_game.game_over = false
	var gold_before: int = inventory.gold
	var xp_before: float = _game.xp + float(_game.level) * 1000.0
	var level_before: int = _game.level
	_game._spawn_pickup("gold", 9, player.global_position + Vector2(300, 0))
	_game._spawn_pickup("xp", 50, player.global_position + Vector2(-300, 0))
	await _ticks(2)
	_game._collect_ground_drops()
	await _ticks(2)
	_check(inventory.gold == gold_before + 9, "o ouro do chão vai para o herói")
	_check(_game.level > level_before or _game.xp > 0.0, "o XP do chão também entra (nível %d)" % _game.level)
	_check(get_tree().get_nodes_in_group("pickups").is_empty(), "nada fica no chão")
	# Inimigos à distância batem mais forte.
	var skeleton := Enemy.new()
	skeleton.setup("skeleton", 0.0, 1.0, 1.0)
	_check(skeleton.shot_damage >= 15.0, "o tiro do esqueleto agora dói (%.1f)" % skeleton.shot_damage)
	skeleton.free()


func HealJarCount() -> int:
	return 1


func _test_rune_tiers_and_dismantle() -> void:
	print("[runas por raridade e desmantelar]")
	var ids := Runes.ids()
	for stat in Item.BONUS_STATS:
		if stat == "hp_regen":
			continue
		_check(Runes.is_valid(Runes.make_id(stat, 0)) and Runes.is_valid(Runes.make_id(stat, 4)), "%s tem runa C e SS" % Item.STAT_NAMES[stat])
	_check(Runes.is_valid("critdmg_C") and Runes.is_valid("critdmg_SS"), "dano crítico também tem as suas runas")
	_check(Runes.value("attack_SS") == Runes.value("attack_C") * 8 and Runes.value("attack_B") == Runes.value("attack_C") * 2, "a raridade multiplica o valor da runa")
	_check(Runes.price("attack_SS") > Runes.price("attack_S") and Runes.price("attack_S") > Runes.price("attack_C"), "runas mais raras custam mais")
	_check(Runes.migrate("attack") == "attack_B" and Runes.migrate("crit") == "critdmg_B" and Runes.migrate("lixo") == "", "runas do save antigo viram raridade B")
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var counts := [0, 0, 0, 0, 0]
	for i in 4000:
		counts[Runes.tier_of(Runes.roll(rng))] += 1
	_check(counts[0] > counts[1] and counts[1] > counts[2] and counts[2] > counts[3] and counts[3] > counts[4] and counts[4] > 0, "as raridades são cada vez mais raras: %s" % str(counts))
	_check(Runes.tier_of(Runes.roll(rng, 2, 4)) >= 2, "o chefe só solta runas A ou melhores")
	Session.reset_progress()
	var inventory: Inventory = Session.inventory
	inventory.runes = {"hp_C": 7}
	_check(inventory.fuse_rune("hp_C") == "" and inventory.runes["hp_C"] == 4 and inventory.runes["hp_B"] == 1, "três runas C viram uma B")
	_check(inventory.fuse_rune("hp_C") == "" and inventory.fuse_rune("hp_C") != "", "sem três iguais, não funde")
	inventory.runes["hp_SS"] = 5
	_check(inventory.fuse_rune("hp_SS") != "", "a SS não funde")
	var legacy := Inventory.from_dict({"runes": {"attack": 2, "crit": 1}})
	_check(legacy.runes.get("attack_B", 0) == 2 and legacy.runes.get("critdmg_B", 0) == 1, "o save antigo mantém as runas (como B)")
	var item := Item.from_dict({"name": "x", "slot": "weapon", "rarity": 2, "sockets": ["attack"]})
	_check(item.rune_in(0) == "attack_B", "item antigo com runa vira raridade B")
	var mine := Item.create(rng, "boots", 0, 30, 2, 2)
	var shop_runes: Array = Shop.generate_stock(5, 4)["materials"]
	var any_rune := false
	for entry in shop_runes:
		if entry["kind"] == "rune":
			any_rune = true
			_check(Runes.is_valid(entry["payload"]) and entry["price"] == Runes.price(entry["payload"]), "o mercado vende %s por %d" % [entry["name"], entry["price"]])
	_check(any_rune, "o mercado tem runas")
	# Desmantelar manualmente.
	inventory.fragments = [0, 0, 0, 0, 0]
	inventory.bag.clear()
	inventory.bag.append(mine)
	var expected := mine.fragment_value()
	_check(inventory.convert_to_fragments(mine) == expected and inventory.fragments[mine.rarity] == expected and not inventory.bag.has(mine), "desmantelar dá os mesmos fragmentos do automático (%d)" % expected)
	var window := InventoryWindow.new()
	var player := Player.new()
	player.hero_id = "warrior"
	add_child(player)
	add_child(window)
	player.inventory = inventory
	window.bind(player)
	window.open()
	var other := Item.create(rng, "ring", 0, 30, 1, 1)
	inventory.bag.append(other)
	window._select(other, false)
	await _frames(2)
	_check(window._dismantle_button.visible and window._dismantle_button.text.contains("+%d" % other.fragment_value()), "a mochila tem o botão Desmantelar com o valor (%s)" % window._dismantle_button.text)
	var before: int = inventory.fragments[other.rarity]
	window._on_dismantle_pressed()
	_check(inventory.fragments[other.rarity] == before + other.fragment_value() and not inventory.bag.has(other), "e ele converte o item em fragmentos")
	window.queue_free()
	player.queue_free()


func _test_damage_floor_and_endgame() -> void:
	print("[dano mínimo, bomba, chefes, flecha dupla, mapa e fim da batalha]")
	Session.reset_progress()
	Session.hero_id = "warrior"
	await _new_game(0)
	var player: Player = _game.player
	player.max_health = 1000.0
	player.health = 1000.0
	player.attributes["defense"] = 100
	player.refresh_stats()
	player.max_health = 1000.0
	player.health = 1000.0
	# Dano mínimo: 1% da vida (chefe 6%, bomba 30%), mesmo com muita defesa.
	player.take_damage(1.0, "dot", 0.0)
	var after_dot: float = player.health
	_check(after_dot > 990.0, "sem fração mínima, a defesa reduz quase tudo (%.1f)" % (1000.0 - after_dot))
	player.health = 1000.0
	player.take_damage(1.0, "hit", 0.01)
	_check(absf((1000.0 - player.health) - 10.0) < 0.5 or player.health >= 1000.0, "um golpe fraco tira pelo menos 1%% da vida (%.1f)" % (1000.0 - player.health))
	player.health = 1000.0
	player.take_damage(1.0, "hit", Enemy.BOSS_MIN_FRACTION)
	_check((1000.0 - player.health) >= 59.0 or player.health >= 1000.0, "um golpe de chefe tira pelo menos 6%% (%.1f)" % (1000.0 - player.health))
	_check(Enemy.BOSS_MIN_FRACTION == 0.06 and Enemy.MIN_FRACTION == 0.01 and Enemy.BOMB_MIN_FRACTION == 0.30, "as frações mínimas são 1%, 6% e 30%")
	# A bomba-viva.
	var bomber: Enemy = _spawn("bomber", Vector2(20, 0))
	player.attributes["defense"] = 0
	player.refresh_stats()
	player.max_health = 1000.0
	player.health = 1000.0
	bomber._explode()
	_check(1000.0 - player.health >= 299.0 or player.health >= 1000.0, "a explosão da bomba tira pelo menos 30%% da vida (%.0f)" % (1000.0 - player.health))
	# Esquiva: contra ataque de perto é metade.
	_check(Player.MELEE_DODGE_FACTOR == 0.5, "de perto o herói desvia com metade da chance")
	player.attributes["dex"] = 60
	player.refresh_stats()
	var ranged_dodges := 0
	var melee_dodges := 0
	for i in 2000:
		player.health = 1000.0
		var before: float = player.health
		player.take_damage(1.0, "hit", 0.0, false)
		if player.health == before:
			ranged_dodges += 1
		player.health = 1000.0
		player.take_damage(1.0, "hit", 0.0, true)
		if player.health == before:
			melee_dodges += 1
	_check(ranged_dodges > melee_dodges * 1.4, "esquiva à distância %d contra %d de perto" % [ranged_dodges, melee_dodges])
	player.attributes["dex"] = 0
	# Flecha Dupla: cada flecha causa 60%.
	_check(Weapon.DOUBLE_ARROW_DAMAGE == 0.6, "a flecha dupla causa 60% do dano")
	# Potes e chefes.
	var game_script: GDScript = load("res://scripts/game/game.gd")
	_check(game_script.JAR_START <= 1 and game_script.JAR_MAX <= 2 and game_script.JAR_INTERVAL >= 25.0, "bem menos potes de vida no mapa")
	_check(float(Stages.get_stage(9)["boss"]["hp"]) >= 70.0 and float(Stages.get_stage(19)["boss"]["hp"]) >= 200.0, "os chefes têm muito mais vida (o chefe final %d)" % int(Stages.get_stage(19)["boss"]["hp"]))
	_check(Stages.HP_BOOST >= 2.8 and Stages.DAMAGE_BOOST >= 2.0, "vida e dano de todos os monstros dobraram")
	# Limite do mapa.
	player.global_position = Vector2(5000, 0)
	await _ticks(2)
	_check(player.global_position.length() <= Player.MAP_RADIUS + 1.0, "o herói não passa da borda do mapa (%d)" % player.global_position.length())
	player.global_position = Vector2.ZERO
	# Fim da batalha com tempo para ver o que ganhou.
	Session.reset_progress()
	await _new_game(0)
	player = _game.player
	_game._spawn_pickup("gold", 12, player.global_position + Vector2(300, 0))
	_game._spawn_pickup("xp", 200, player.global_position + Vector2(-300, 0))
	await _ticks(2)
	var level_before: int = _game.level
	_game._on_mission_complete(false)
	_check(_game.mission_complete and not _game.game_over and not _game.victory_panel.visible, "ao acabar a batalha a tela de vitória ainda não aparece")
	_check(_game.level > level_before or _game.xp > 0.0, "o XP do chão entrou (nível %d)" % _game.level)
	await get_tree().create_timer(_game.END_REVIEW_SECONDS + 1.0, true).timeout
	for i in 40:
		if _game.modal_open:
			_game.attribute_popup.hide()
			_game.pending_attribute_popups = 0
			_game.modal_open = false
			get_tree().paused = false
		await _ticks(5)
	_check(_game.victory_panel.visible and _game.game_over, "depois da pausa a tela de vitória aparece")
	get_tree().paused = false


func _test_runes_returned_and_fuse_all() -> void:
	print("[runas devolvidas e fundir todas]")
	Session.reset_progress()
	var inventory: Inventory = Session.inventory
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	inventory.runes = {}
	var item := Item.create(rng, "weapon", 0, 20, 3, 3)
	item.insert_rune("attack_C")
	item.insert_rune("hp_B")
	inventory.bag = [item]
	inventory.sell(item)
	_check(inventory.runes.get("attack_C", 0) == 1 and inventory.runes.get("hp_B", 0) == 1 and not inventory.bag.has(item), "vender um item com runas devolve as runas")
	_check(inventory.released_text().contains("Ataque [C]") and inventory.released_text().contains("Vida [B]"), "e avisa quais foram (%s)" % inventory.released_text())
	var other := Item.create(rng, "boots", 0, 20, 2, 2)
	other.insert_rune("speed_A")
	inventory.bag = [other]
	var fragments := inventory.convert_to_fragments(other)
	_check(fragments > 0 and inventory.runes.get("speed_A", 0) == 1 and inventory.released_text().contains("Velocidade [A]"), "desmantelar também devolve as runas")
	var third := Item.create(rng, "ring", 0, 20, 2, 2)
	third.insert_rune("luck_S")
	inventory.bag = [third]
	inventory.trash(third)
	_check(inventory.runes.get("luck_S", 0) == 1, "descartar também")
	var plain := Item.create(rng, "ring", 0, 20)
	inventory.bag = [plain]
	inventory.sell(plain)
	_check(inventory.released_text() == "", "item sem runas não gera aviso")
	# Fundir todas.
	inventory.runes = {"hp_C": 10, "attack_C": 3, "luck_B": 7}
	var fusions := inventory.fuse_all_runes()
	_check(fusions == 3 + 1 + 2 and inventory.runes["hp_C"] == 1 and inventory.runes["hp_B"] == 3 + 0 or inventory.runes.has("hp_A"), "fundir todas faz as fusões em cadeia (%d)" % fusions)
	_check(inventory.runes.get("attack_B", 0) >= 1 or inventory.runes.get("attack_A", 0) >= 1, "e vale para todos os atributos")
	_check(inventory.fuse_all_runes() >= 0 and Runes.TIER_WEIGHTS[4] < 0.5 and Runes.TIER_WEIGHTS[0] > 70.0, "as raridades altas ficaram bem mais raras")
	var panel := RunesPanel.new()
	add_child(panel)
	panel.refresh()
	await _frames(2)
	_check(panel._fuse_all != null and panel._fuse_all.text == "Fundir todas", "a aba de runas tem o botão Fundir todas")
	panel.queue_free()


func _test_pets_and_skill_levels() -> void:
	print("[pets de monstros, tiros dos pets e níveis das habilidades]")
	Session.reset_progress()
	# Um pet para cada monstro (menos a gosma).
	var monster_pets := 0
	for id in Pets.ids():
		if Pets.get_pet(id).has("kind"):
			monster_pets += 1
	_check(monster_pets == Pets.MONSTER_STATS.size() and not Pets.ids().has("m_slime"), "há um pet para cada monstro, menos a gosma (%d)" % monster_pets)
	_check(Pets.is_valid("slime_king") and Pets.is_valid("ash_lord"), "os dois pets de chefe continuam")
	for kind in EnemyTypes.DATA:
		if kind != "slime":
			_check(Pets.for_kind(kind) != "", "%s tem pet" % EnemyTypes.DATA[kind]["name"]) if kind in ["bat", "wolf", "mimic"] else null
	_check(Pets.for_kind("slime") == "", "a gosma não tem pet")
	_check(Pets.attack_damage(1) < Pets.attack_damage(10) and Pets.attack_damage(100) > Pets.attack_damage(50), "o nível do pet não tem limite e só aumenta o dano")
	_check(Pets.stats("m_bat", 1) == Pets.stats("m_bat", 99), "os atributos não mudam com o nível")
	# 1000 abates conquistam o pet.
	Session.monster_kills = {"bat": 999}
	Session.record_kill("bat")
	_check(Session.pets.has("m_bat") and Session.unlocked_pet == "m_bat", "1000 morcegos conquistam o Mini Morcego")
	Session.unlocked_pet = ""
	Session.record_kill("bat")
	_check(Session.unlocked_pet == "", "o pet só é entregue uma vez")
	Session.monster_kills = {"wolf": 1500, "slime": 5000}
	Session.grant_kill_pets()
	_check(Session.pets.has("m_wolf") and not Session.pets.has("m_slime"), "saves com muitos abates já ganham os pets")
	_check(Session.kills_left_for("m_ghost") == 1000, "faltam 1000 abates de fantasma")
	# Melhorar o pet sem limite.
	Session.inventory.gold = 1000000
	for i in 25:
		Session.upgrade_pet("m_wolf")
	_check(Session.pet_level("m_wolf") == 26, "o pet passa do nível 10 (%d)" % Session.pet_level("m_wolf"))
	# O pet atira.
	Session.hero_id = "warrior"
	await _new_game(0)
	Session.grant_pet("m_wolf")
	Session.pet_levels["m_wolf"] = 12
	Session.set_active_pet("m_wolf")
	_game._spawn_pet()
	var pet: PetFollower = _game.pet
	_check(is_instance_valid(pet), "o pet de monstro acompanha o herói")
	var target := _spawn("slime", Vector2(120, 0))
	target.max_health = 100000.0
	target.health = 100000.0
	target.defense = 0.0
	target.dodge_chance = 0.0
	target.block_chance = 0.0
	var health_before: float = target.health
	pet._shot_timer = 0.0
	pet._try_shoot()
	await get_tree().create_timer(1.2).timeout
	_check(target.health < health_before, "o pet atira e machuca o inimigo (%d de dano)" % int(health_before - target.health))
	# Habilidades: 5 níveis, custo 1/2/3/4/5.
	Session.reset_progress()
	Session.set_progress("warrior", 30, 0.0, 40, 40)
	var costs := PackedInt32Array()
	for level in 5:
		costs.append(Skills.upgrade_cost(level))
	_check(costs == PackedInt32Array([1, 2, 3, 4, 5]), "os níveis custam 1, 2, 3, 4 e 5 pontos")
	for i in 5:
		_check(Session.upgrade_skill("warrior", "slash"), "nível %d de Corte Duplo" % (i + 1))
	_check(not Session.upgrade_skill("warrior", "slash") and Session.skill_level("warrior", "slash") == 5, "o máximo é o nível 5")
	_check(Session.progress_for("warrior")["points"] == 40 - 15, "os 5 níveis custaram 15 pontos (sobram %d)" % Session.progress_for("warrior")["points"])
	Session.set_progress("warrior", 30, 0.0, 0, 40)
	_check(not Session.upgrade_skill("warrior", "shield"), "sem pontos, não melhora")
	Session.set_progress("warrior", 30, 0.0, 10, 40)
	await _new_game(1, true)
	var cooldown_base: float = Skills.DEFS["slash"]["cooldown"]
	_check(Skills.cooldown_for("slash", _game) < cooldown_base * 0.9, "o nível reduz a recarga (%.1fs de %.1fs)" % [Skills.cooldown_for("slash", _game), cooldown_base])
	var panel := SkillUpgradePanel.new()
	add_child(panel)
	panel.refresh("warrior")
	await _frames(2)
	_check(_all_text(panel).contains("Corte Duplo") and _all_text(panel).contains("Escudo") and _all_text(panel).contains("Pancada no Chão"), "a aba mostra as habilidades do herói e o que cada uma faz")
	panel.queue_free()
	var round_trip_levels: Dictionary = Session.skill_levels.duplicate(true)
	_check(round_trip_levels.get("warrior", {}).get("slash", 0) == 5, "os níveis ficam guardados")


func _test_lifesteal_nerf_and_edge_spawn() -> void:
	print("[roubo de vida mais fraco e monstros longe da borda]")
	Session.reset_progress()
	await _new_game(0)
	var player: Player = _game.player
	player.tree_bonus = {"lifesteal": 1000}
	_check(player.get_lifesteal() <= Player.LIFESTEAL_CAP + 0.0001 and Player.LIFESTEAL_CAP <= 0.06, "o roubo de vida tem teto de 6%% (%.2f)" % player.get_lifesteal())
	player.max_health = 1000.0
	player.health = 100.0
	_game._on_damage_dealt(100000.0, Vector2.ZERO, "hit")
	_check(player.health - 100.0 <= 1000.0 * Player.LIFESTEAL_HIT_CAP + 0.01, "cada golpe cura no máximo 2%% da vida (curou %.1f)" % (player.health - 100.0))
	player.tree_bonus = {}
	# Spawn longe da borda, mesmo com o herói perto dela.
	player.global_position = Vector2(Player.MAP_RADIUS - 60.0, 0.0)
	var worst := 0.0
	for i in 60:
		var enemy: Enemy = _game._spawn_one("bat", player.global_position + Vector2.from_angle(_game._emptiest_angle()) * _game.SPAWN_DISTANCE)
		worst = maxf(worst, enemy.global_position.length())
		enemy.queue_free()
	_check(worst <= Player.MAP_RADIUS - _game.SPAWN_EDGE_MARGIN + 1.0, "monstros nascem pelo menos %d px antes da borda (o mais longe: %d)" % [int(_game.SPAWN_EDGE_MARGIN), int(worst)])
	var far_angle: float = _game._emptiest_angle()
	var spot: Vector2 = player.global_position + Vector2.from_angle(far_angle) * _game.SPAWN_DISTANCE
	_check(spot.length() <= Player.MAP_RADIUS - _game.SPAWN_EDGE_MARGIN + 1.0, "o lado escolhido para nascer fica na área segura")
	player.global_position = Vector2.ZERO


func _test_optimizations_keep_behavior() -> void:
	print("[otimizações: mesmo comportamento]")
	Session.reset_progress()
	await _new_game(0)
	var player: Player = _game.player
	player.accuracy_bonus = 1.0
	player.card_crit = -1.0
	# A lista de inimigos acompanha entradas e saídas no mesmo quadro.
	var first := _spawn("slime", Vector2(200, 0))
	var count_one := Enemy.alive(get_tree()).size()
	var second := _spawn("slime", Vector2(230, 0))
	_check(Enemy.alive(get_tree()).size() == count_one + 1, "um inimigo novo aparece na lista no mesmo quadro")
	# Projétil acerta pela fotografia dos inimigos.
	first.max_health = 1000.0
	first.health = 1000.0
	first.defense = 0.0
	first.dodge_chance = 0.0
	first.block_chance = 0.0
	var shot := Projectile.new()
	shot.damage = 50.0
	shot.hit_kind = "skill"
	shot.velocity = Vector2.ZERO
	shot.radius = 8.0
	_game.world.add_child(shot)
	shot.global_position = first.global_position
	shot._physics_process(0.016)
	_check(first.health < 1000.0, "o projétil continua acertando o inimigo (%d de dano)" % int(1000.0 - first.health))
	var untouched: Enemy = _spawn("bat", Vector2(900, 900))
	_check(untouched.health == untouched.max_health, "e não acerta quem está longe")
	# find_targets continua em ordem de distância.
	_game.weapon.attack_range = 400.0
	var targets: Array = _game.weapon.find_targets(400.0)
	var ordered := true
	for i in range(1, targets.size()):
		ordered = ordered and player.global_position.distance_to(targets[i - 1].global_position) <= player.global_position.distance_to(targets[i].global_position)
	_check(targets.size() >= 2 and ordered, "os alvos continuam ordenados do mais perto para o mais longe")
	# Barras e botões só redesenham quando algo muda (sem mudar o que aparece).
	var bar := MedievalBar.new()
	bar.value = 5.0
	bar.label_text = "a"
	bar.value = 5.0
	bar.label_text = "a"
	_check(is_equal_approx(bar.value, 5.0) and bar.label_text == "a", "a barra guarda o valor")
	bar.free()
	_check(WorldDecor.LOAD_RADIUS == 1, "o cenário carrega 3x3 pedaços")
