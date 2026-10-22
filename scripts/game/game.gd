extends Node2D

## Partida: spawna hordas, gerencia XP e level-up, HUD e fim de jogo.

const SPAWN_DISTANCE := 520.0
const MAX_ENEMIES := 300
const MENU_SCENE := "res://scenes/Main.tscn"

var world: Node2D
var player: Player
var weapon: Weapon
var joystick: VirtualJoystick
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var time_label: Label
var level_label: Label
var kills_label: Label
var level_panel: PanelContainer
var cards_box: VBoxContainer
var gameover_panel: PanelContainer
var gameover_label: Label

var elapsed := 0.0
var kills := 0
var xp := 0
var level := 1
var xp_to_next := 5
var spawn_cooldown := 0.0
var pending_level_ups := 0
var level_up_open := false
var game_over := false
var upgrades: Array = []


func _ready() -> void:
	world = Node2D.new()
	add_child(world)

	player = Player.new()
	world.add_child(player)

	weapon = Weapon.new()
	player.add_child(weapon)
	weapon.setup(player, world)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	player.add_child(camera)

	_build_hud()
	player.joystick = joystick
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.xp_collected.connect(_on_xp_collected)

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
		spawn_cooldown = max(0.18, 1.0 - elapsed / 150.0)
		_spawn_enemy()
	_update_hud()


func _spawn_enemy() -> void:
	if get_tree().get_node_count_in_group("enemies") >= MAX_ENEMIES:
		return
	var enemy := Enemy.new()
	enemy.target = player
	enemy.max_health = 20.0 * (1.0 + elapsed / 45.0)
	enemy.contact_damage = 6.0 + elapsed / 30.0
	enemy.speed = 55.0 + min(45.0, elapsed / 6.0)
	world.add_child(enemy)
	enemy.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * SPAWN_DISTANCE


func _on_enemy_killed(at_position: Vector2, xp_value: int) -> void:
	kills += 1
	var gem := XpGem.new()
	gem.value = xp_value
	gem.target = player
	world.add_child(gem)
	gem.global_position = at_position


func _on_xp_collected(value: int) -> void:
	xp += value
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 5 + level * 3
		pending_level_ups += 1
	xp_bar.max_value = xp_to_next
	_open_level_up()


func _open_level_up() -> void:
	if level_up_open or pending_level_ups == 0:
		return
	pending_level_ups -= 1
	level_up_open = true
	for child in cards_box.get_children():
		child.queue_free()
	var pool := upgrades.duplicate()
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
	level_up_open = false
	get_tree().paused = false
	_open_level_up()


func _build_upgrades() -> Array:
	return [
		{"name": "Lâmina afiada", "desc": "+25% de dano", "apply": func(): weapon.damage *= 1.25},
		{"name": "Gatilho rápido", "desc": "15% menos tempo entre disparos", "apply": func(): weapon.fire_interval *= 0.85},
		{"name": "Mira longa", "desc": "+20% de alcance", "apply": func(): weapon.attack_range *= 1.2},
		{"name": "Vitalidade", "desc": "+25 de vida máxima e cura total", "apply": func(): player.raise_max_health(25.0)},
		{"name": "Botas leves", "desc": "+12% de velocidade", "apply": func(): player.move_speed *= 1.12},
		{"name": "Tiro múltiplo", "desc": "+1 projétil por disparo", "apply": func(): weapon.projectile_count += 1},
	]


func _on_player_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current


func _on_player_died() -> void:
	game_over = true
	level_panel.hide()
	gameover_label.text = "Você caiu na Floresta Sombria\nTempo: %s\nAbates: %d\nNível: %d" % [_format_time(), kills, level]
	gameover_panel.show()
	get_tree().paused = true


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
	xp_bar = _make_bar(Brand.GOLD)
	top.add_child(hp_bar)
	top.add_child(xp_bar)

	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 24)
	top.add_child(info)
	time_label = _make_label()
	level_label = _make_label()
	kills_label = _make_label()
	info.add_child(time_label)
	info.add_child(level_label)
	info.add_child(kills_label)

	level_panel = _make_centered_panel(hud)
	var level_box := VBoxContainer.new()
	level_box.add_theme_constant_override("separation", 12)
	level_panel.add_child(level_box)
	level_box.add_child(_make_label("Subiu de nível! Escolha uma melhoria"))
	cards_box = VBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 10)
	level_box.add_child(cards_box)

	gameover_panel = _make_centered_panel(hud)
	var over_box := VBoxContainer.new()
	over_box.add_theme_constant_override("separation", 16)
	gameover_panel.add_child(over_box)
	gameover_label = _make_label()
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
	bar.custom_minimum_size = Vector2(320, 16)
	bar.modulate = color
	return bar


func _make_label(text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Brand.PARCHMENT)
	return label


func _update_hud() -> void:
	xp_bar.value = xp
	time_label.text = "Tempo %s" % _format_time()
	level_label.text = "Nível %d" % level
	kills_label.text = "Abates %d" % kills


func _format_time() -> String:
	var seconds := int(elapsed)
	return "%02d:%02d" % [seconds / 60, seconds % 60]
