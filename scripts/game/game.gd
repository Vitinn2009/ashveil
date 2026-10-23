extends Node2D

## Partida: hordas, XP e níveis, habilidades, drops, HUD e fim de jogo.

const SPAWN_DISTANCE := 560.0
const MAX_ENEMIES := 280
const MENU_SCENE := "res://scenes/Main.tscn"
const STAT_POINTS_PER_POPUP := 3
const STAT_POPUP_EVERY := 5
const GOLD_CHANCE := 0.30
const POTION_CHANCE := 0.035
const ITEM_CHANCE := 0.04

var world: Node2D
var player: Player
var weapon: Weapon
var joystick: VirtualJoystick
var hp_bar: ProgressBar
var hp_text: Label
var xp_bar: ProgressBar
var info_label: Label
var toast_label: Label
var level_panel: PanelContainer
var cards_box: VBoxContainer
var gameover_panel: PanelContainer
var gameover_label: Label
var inventory_panel: InventoryPanel
var stat_popup: StatPopup
var skill_buttons := {}
var cooldowns := {}
var cooldown_scale := 1.0

var elapsed := 0.0
var kills := 0
var xp := 0.0
var level := 1
var xp_to_next := 6.0
var spawn_cooldown := 0.0
var pending_level_ups := 0
var pending_stat_popups := 0
var modal_open := false
var game_over := false
var upgrades: Array = []
var _toast_tween: Tween


func _ready() -> void:
	world = Node2D.new()
	add_child(world)

	player = Player.new()
	player.hero_id = Session.hero_id
	world.add_child(player)

	weapon = Weapon.new()
	player.add_child(weapon)
	weapon.configure(player, world)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.offset = Vector2(InventoryPanel.WIDTH * 0.5, 0)
	player.add_child(camera)

	_build_hud()
	player.joystick = joystick
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.pickup_collected.connect(_on_pickup_collected)

	_on_player_health_changed(player.health, player.max_health)
	upgrades = _build_upgrades()
	xp_bar.max_value = xp_to_next
	_update_hud()


func _process(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		spawn_cooldown = max(0.2, 1.15 - elapsed / 160.0)
		_spawn_enemy()
	for id in cooldowns:
		cooldowns[id] = max(0.0, cooldowns[id] - delta)
		skill_buttons[id].set_cooldown(cooldowns[id], Skills.def(id)["cooldown"] * cooldown_scale)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var skills: Array = player.hero["skills"]
	match event.keycode:
		KEY_1:
			_try_cast_index(skills, 0)
		KEY_2:
			_try_cast_index(skills, 1)
		KEY_3:
			_try_cast_index(skills, 2)
		KEY_Q:
			_use_potion()


func _try_cast_index(skills: Array, index: int) -> void:
	if index < skills.size():
		try_cast(skills[index])


func try_cast(id: String) -> bool:
	if game_over or modal_open or cooldowns.get(id, 0.0) > 0.0:
		return false
	cooldowns[id] = Skills.def(id)["cooldown"] * cooldown_scale
	Skills.cast(id, self)
	return true


func _use_potion() -> void:
	if not game_over and not modal_open and player.inventory.use_potion(player):
		_toast("Poção usada", Color("e0452d"))


# --- Inimigos e drops -------------------------------------------------------

func _spawn_enemy() -> void:
	if get_tree().get_node_count_in_group("enemies") >= MAX_ENEMIES:
		return
	var enemy := Enemy.new()
	enemy.target = player
	enemy.setup(EnemyTypes.pick(elapsed), elapsed)
	world.add_child(enemy)
	enemy.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * SPAWN_DISTANCE


func _on_enemy_killed(at_position: Vector2, xp_value: int, loot: bool) -> void:
	kills += 1
	_spawn_pickup("xp", xp_value, at_position)
	if not loot:
		return
	var luck := player.get_luck()
	var drop_mult := player.get_drop_mult()
	var rolls := 1 + (1 if randf() < 0.05 * luck else 0)
	for i in rolls:
		if randf() < GOLD_CHANCE * drop_mult:
			var amount := int(round(randi_range(1, 3) * (1.0 + 0.1 * luck)))
			_spawn_pickup("gold", amount, at_position)
		if randf() < POTION_CHANCE * drop_mult:
			_spawn_pickup("potion", 1, at_position)
		if randf() < ITEM_CHANCE * drop_mult:
			_spawn_pickup("item", Item.roll(luck, level), at_position)


func _spawn_pickup(kind: String, payload: Variant, at_position: Vector2) -> void:
	var pickup := Pickup.new()
	pickup.kind = kind
	pickup.payload = payload
	pickup.target = player
	world.add_child(pickup)
	pickup.global_position = at_position + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))


func _on_pickup_collected(kind: String, payload: Variant) -> void:
	match kind:
		"xp":
			_gain_xp(float(payload) * player.get_xp_mult())
		"gold":
			player.inventory.add_gold(int(payload))
		"potion":
			player.inventory.add_potion()
			_toast("Poção de vida!", Color("e0452d"))
		"item":
			var item: Item = payload
			if player.inventory.add_item(item):
				_toast("%s (%s)" % [item.item_name, item.rarity_name()], item.color())
			else:
				_toast("Mochila cheia: %s vendido" % item.item_name, Brand.GOLD)


# --- Níveis, cartas e atributos ---------------------------------------------

func _gain_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 4.0 + level * 2.5
		pending_level_ups += 1
		if level % STAT_POPUP_EVERY == 0:
			pending_stat_popups += 1
	xp_bar.max_value = xp_to_next
	_open_next_modal()


func _open_next_modal() -> void:
	if modal_open or game_over:
		return
	if pending_level_ups > 0:
		_open_level_up()
	elif pending_stat_popups > 0:
		_open_stat_popup()


func _open_level_up() -> void:
	pending_level_ups -= 1
	modal_open = true
	for child in cards_box.get_children():
		child.queue_free()
	var pool := upgrades.filter(func(option: Dictionary) -> bool:
		return option["kinds"].is_empty() or option["kinds"].has(weapon.kind))
	pool.shuffle()
	for option in pool.slice(0, 3):
		var button := Brand.make_button("%s\n%s" % [option["name"], option["desc"]], Vector2(460, 84))
		button.pressed.connect(_choose_upgrade.bind(option))
		cards_box.add_child(button)
	level_panel.show()
	get_tree().paused = true


func _choose_upgrade(option: Dictionary) -> void:
	option["apply"].call()
	level_panel.hide()
	_close_modal()


func _open_stat_popup() -> void:
	pending_stat_popups -= 1
	modal_open = true
	# O nível exibido é o do marco de 5 em 5 mais recente já alcançado.
	stat_popup.open(player, STAT_POINTS_PER_POPUP, level - level % STAT_POPUP_EVERY)
	get_tree().paused = true


func _on_stat_popup_closed() -> void:
	_close_modal()


func _close_modal() -> void:
	modal_open = false
	get_tree().paused = false
	_open_next_modal()


func _build_upgrades() -> Array:
	return [
		{"name": "Lâmina afiada", "desc": "+25% de dano", "kinds": [], "apply": func(): weapon.damage *= 1.25},
		{"name": "Gatilho rápido", "desc": "15% menos tempo entre ataques", "kinds": [], "apply": func(): weapon.fire_interval *= 0.85},
		{"name": "Mira longa", "desc": "+20% de alcance", "kinds": ["magic", "arrow"], "apply": func(): weapon.attack_range *= 1.2},
		{"name": "Golpe amplo", "desc": "+20% de área do golpe", "kinds": ["melee"], "apply": func(): weapon.attack_range *= 1.2},
		{"name": "Tiro múltiplo", "desc": "+1 projétil por disparo", "kinds": ["magic", "arrow"], "apply": func(): weapon.projectile_count += 1},
		{"name": "Vitalidade", "desc": "+25 de vida máxima e cura", "kinds": [], "apply": func(): player.raise_max_health(25.0)},
		{"name": "Botas leves", "desc": "+12% de velocidade", "kinds": [], "apply": func(): player.card_speed_mult *= 1.12},
		{"name": "Foco", "desc": "Habilidades recarregam 12% mais rápido", "kinds": [], "apply": func(): cooldown_scale *= 0.88},
	]


# --- Fim de jogo ------------------------------------------------------------

func _on_player_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_text.text = "%d / %d" % [int(ceil(current)), int(maximum)]


func _on_player_died() -> void:
	game_over = true
	level_panel.hide()
	stat_popup.hide()
	gameover_label.text = "%s caiu na Floresta Sombria\nTempo: %s\nAbates: %d\nNível: %d\nOuro: %d" % [
		player.hero["name"], _format_time(), kills, level, player.inventory.gold]
	gameover_panel.show()
	get_tree().paused = true


# --- HUD --------------------------------------------------------------------

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	joystick = VirtualJoystick.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(joystick)

	var top := VBoxContainer.new()
	top.position = Vector2(16, 16)
	top.add_theme_constant_override("separation", 6)
	hud.add_child(top)
	hp_bar = _make_bar(Brand.EMBER)
	hp_text = _bar_label(hp_bar)
	xp_bar = _make_bar(Brand.GOLD)
	top.add_child(hp_bar)
	top.add_child(xp_bar)
	info_label = Brand.make_label("", 20)
	info_label.add_theme_color_override("font_outline_color", Brand.NIGHT)
	info_label.add_theme_constant_override("outline_size", 5)
	top.add_child(info_label)

	toast_label = Brand.make_label("", 24, Brand.GOLD)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -300.0
	toast_label.offset_right = 300.0 - InventoryPanel.WIDTH
	toast_label.offset_top = 22.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_outline_color", Brand.NIGHT)
	toast_label.add_theme_constant_override("outline_size", 6)
	toast_label.modulate.a = 0.0
	hud.add_child(toast_label)

	var skill_bar := HBoxContainer.new()
	skill_bar.add_theme_constant_override("separation", 10)
	skill_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skill_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skill_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	skill_bar.offset_right = -(InventoryPanel.WIDTH + 16.0)
	skill_bar.offset_bottom = -16.0
	hud.add_child(skill_bar)
	var hero_skills: Array = player.hero["skills"]
	for i in hero_skills.size():
		var id: String = hero_skills[i]
		var button := SkillButton.new()
		button.setup(id, str(i + 1))
		button.cast_requested.connect(try_cast)
		skill_bar.add_child(button)
		skill_buttons[id] = button
		cooldowns[id] = 0.0

	inventory_panel = InventoryPanel.new()
	hud.add_child(inventory_panel)
	inventory_panel.bind(player)

	level_panel = _make_centered_panel(hud)
	var level_box := VBoxContainer.new()
	level_box.add_theme_constant_override("separation", 12)
	level_panel.add_child(level_box)
	level_box.add_child(Brand.make_label("Subiu de nível! Escolha uma melhoria", 24, Brand.GOLD))
	cards_box = VBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 10)
	level_box.add_child(cards_box)

	stat_popup = StatPopup.new()
	stat_popup.closed.connect(_on_stat_popup_closed)
	hud.add_child(stat_popup)

	gameover_panel = _make_centered_panel(hud)
	var over_box := VBoxContainer.new()
	over_box.add_theme_constant_override("separation", 16)
	gameover_panel.add_child(over_box)
	gameover_label = Brand.make_label("", 22)
	over_box.add_child(gameover_label)
	var again := Brand.make_button("Jogar novamente")
	again.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene())
	over_box.add_child(again)
	var menu := Brand.make_button("Voltar ao menu")
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU_SCENE))
	over_box.add_child(menu)


func _make_centered_panel(parent: CanvasLayer) -> PanelContainer:
	var panel := Brand.make_panel()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	parent.add_child(panel)
	return panel


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(340, 22)
	bar.modulate = color
	return bar


func _bar_label(bar: ProgressBar) -> Label:
	var label := Brand.make_label("", 14, Color.WHITE)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Brand.NIGHT)
	label.add_theme_constant_override("outline_size", 4)
	bar.add_child(label)
	return label


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
	info_label.text = "%s · Nível %d · %s · Abates %d" % [
		player.hero["name"], level, _format_time(), kills]


func _format_time() -> String:
	var seconds := int(elapsed)
	return "%02d:%02d" % [seconds / 60, seconds % 60]
