class_name ArenaPopup
extends Control

## Janela da Arena PvP: escolha do herói rival (controlado pela IA) e da dificuldade. O rival usa a força do
## jogador (vida, dano, defesa, velocidade e habilidades que ele já liberou), então o duelo é equilibrado.

const GAME_SCENE := "res://scenes/Game.tscn"

signal closed

var rival := "mage"
var difficulty := "normal"
var _rival_buttons := {}
var _difficulty_buttons := {}
var _fight_button: Button
var _info: Label


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	# Por padrão enfrenta um herói diferente do seu.
	for id in Heroes.ids():
		if id != Session.hero_id:
			rival = id
			break
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.66)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := Brand.make_wood_panel(18, Color(Brand.WOOD, 0.98))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(640, 0)
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Brand.make_label("ARENA PvP", 32, Brand.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var score := Brand.make_label("Vitórias %d  ·  Derrotas %d" % [Session.pvp_wins, Session.pvp_losses], 16, Brand.BRASS)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(score)
	var rules := Brand.make_label("O rival usa a sua força: mesma vida, dano e defesa, e as habilidades que você já liberou. Vence quem zerar a vida do outro (ou tiver mais vida em 2min30).", 14)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(rules)

	column.add_child(Brand.make_label("Adversário", 16, Brand.GOLD))
	var heroes := HBoxContainer.new()
	heroes.add_theme_constant_override("separation", 8)
	column.add_child(heroes)
	for id in Heroes.ids():
		var button := Brand.make_wood_button(Heroes.get_hero(id)["name"], Vector2(0, 52), 18)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(choose_rival.bind(id))
		_rival_buttons[id] = button
		heroes.add_child(button)

	column.add_child(Brand.make_label("Dificuldade", 16, Brand.GOLD))
	var levels := HBoxContainer.new()
	levels.add_theme_constant_override("separation", 8)
	column.add_child(levels)
	for id in ["easy", "normal", "hard"]:
		var button := Brand.make_wood_button(RivalBrain.DIFFICULTY[id]["name"], Vector2(0, 48), 18)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(choose_difficulty.bind(id))
		_difficulty_buttons[id] = button
		levels.add_child(button)

	_info = Brand.make_label("", 14, Color("b8c9a0"))
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_info)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	_fight_button = Brand.make_wood_button("LUTAR", Vector2(0, 58), 24)
	_fight_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_button.add_theme_stylebox_override("normal", Brand.make_box(Color("7a2a14"), Brand.GOLD, 4, 14))
	_fight_button.add_theme_stylebox_override("hover", Brand.make_box(Color("9a3a1c"), Color("ffe9a8"), 4, 14))
	_fight_button.pressed.connect(start_fight)
	buttons.add_child(_fight_button)
	var cancel := Brand.make_wood_button("Cancelar", Vector2(160, 58), 18)
	cancel.pressed.connect(close)
	buttons.add_child(cancel)
	_refresh()


func choose_rival(id: String) -> void:
	rival = id
	_refresh()


func choose_difficulty(id: String) -> void:
	difficulty = id
	_refresh()


func _refresh() -> void:
	for id in _rival_buttons:
		_rival_buttons[id].set_pressed_no_signal(id == rival)
	for id in _difficulty_buttons:
		_difficulty_buttons[id].set_pressed_no_signal(id == difficulty)
	var setting: Dictionary = RivalBrain.DIFFICULTY[difficulty]
	var hero := Heroes.get_hero(rival)
	_info.text = "%s: %s. Recompensa: %d%% do ouro base. Vida do rival %d%%, dano %d%% da sua." % [
		hero["name"], hero["title"], int(round(float(setting["reward"]) * 100.0)),
		int(round(float(setting["hp"]) * 100.0)), int(round(float(setting["dmg"]) * 100.0))]


## Grava o duelo e abre a partida.
func start_fight() -> void:
	Session.pvp = true
	Session.pvp_rival = rival
	Session.pvp_difficulty = difficulty
	Session.save_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func close() -> void:
	closed.emit()
	queue_free()
