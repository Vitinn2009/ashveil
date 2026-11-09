extends Control

const SELECT_SCENE := "res://scenes/CharacterSelect.tscn"
const CASTLE_SCENE := "res://scenes/Castle.tscn"

## Botão com o desenho de uma engrenagem (a fonte do jogo não tem esse símbolo).
class GearButton extends Button:
	func _init() -> void:
		var normal := Brand.make_wood_button("", Vector2(48, 48)).get_theme_stylebox("normal")
		add_theme_stylebox_override("normal", normal)
		add_theme_stylebox_override("hover", Brand.make_wood_button("", Vector2(48, 48)).get_theme_stylebox("hover"))
		add_theme_stylebox_override("pressed", Brand.make_wood_button("", Vector2(48, 48)).get_theme_stylebox("pressed"))
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		custom_minimum_size = Vector2(48, 48)

	func _draw() -> void:
		var center := size * 0.5
		var color := Brand.BRASS
		for i in 8:
			var direction := Vector2.from_angle(TAU * i / 8.0)
			draw_line(center + direction * 9.0, center + direction * 15.0, color, 5.0)
		draw_circle(center, 11.0, color)
		draw_circle(center, 4.5, Brand.LEATHER)


var _gear_button: Button
var _play_button: Button
var _options_button: Button
var _gold_label: Label
var _mission_card: Control
var _update_panel: PanelContainer
var _update_label: Label
var _update_button: Button
var _dismiss_button: Button
var _check_button: Button
var _update_manual := false
var _update_dismissed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Brand.NIGHT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Campo de grama com árvores atrás dos heróis.
	var ground := TextureRect.new()
	ground.texture = load("res://assets/world/grass.png")
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -210.0
	add_child(ground)
	_add_scenery("res://assets/world/tree_pine.svg", 0.07, Vector2(150, 285), 232.0)
	_add_scenery("res://assets/world/tree_oak.svg", 0.93, Vector2(260, 325), 232.0)
	_add_scenery("res://assets/world/tree_pine.svg", 0.18, Vector2(110, 210), 200.0)
	_add_scenery("res://assets/world/bush.svg", 0.84, Vector2(150, 107), 180.0)
	_add_scenery("res://assets/world/rock_a.svg", 0.27, Vector2(110, 77), 168.0)

	var heroes := HBoxContainer.new()
	heroes.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	heroes.offset_top = -330.0
	heroes.offset_bottom = -30.0
	heroes.alignment = BoxContainer.ALIGNMENT_CENTER
	heroes.add_theme_constant_override("separation", 48)
	add_child(heroes)
	for id in ["mage", "gnome", "warrior", "archer"]:
		heroes.add_child(_make_hero_art(id, 1.0 if id == "warrior" else (0.72 if id == "gnome" else 0.82)))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.offset_top = 36.0
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	var logo := TextureRect.new()
	logo.texture = load("res://assets/brand/logo.svg")
	logo.custom_minimum_size = Vector2(150, 150)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(logo)

	column.add_child(_make_title("ASHVEIL", 64, Brand.GOLD))
	column.add_child(_make_title("Sobreviva. Evolua. Forje seu destino.", 22, Brand.PARCHMENT))

	# Jogar em destaque e, abaixo, os atalhos: castelo, heróis e catálogo de monstros.
	var play := Brand.make_button("JOGAR", Vector2(420, 76))
	play.add_theme_font_size_override("font_size", 34)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void: get_tree().change_scene_to_file(SELECT_SCENE))
	column.add_child(play)
	_play_button = play

	var shortcuts := HBoxContainer.new()
	shortcuts.alignment = BoxContainer.ALIGNMENT_CENTER
	shortcuts.add_theme_constant_override("separation", 10)
	column.add_child(shortcuts)
	var castle_button := Brand.make_wood_button("Castelo", Vector2(136, 50), 20)
	castle_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(CASTLE_SCENE))
	shortcuts.add_child(castle_button)
	var heroes_button := Brand.make_wood_button("Heróis", Vector2(136, 50), 20)
	heroes_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SELECT_SCENE))
	shortcuts.add_child(heroes_button)
	var bestiary_button := Brand.make_wood_button("Bestiário", Vector2(136, 50), 20)
	bestiary_button.pressed.connect(open_bestiary)
	shortcuts.add_child(bestiary_button)
	var arena_button := Brand.make_wood_button("Arena PvP", Vector2(136, 50), 20)
	arena_button.pressed.connect(open_arena)
	shortcuts.add_child(arena_button)

	_build_top_bar()
	_build_last_mission_card()
	_build_update_banner()

	var version := _make_title("v%s" % Updater.VERSION, 14, Brand.MOSS.lightened(0.4))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -200.0
	version.offset_top = -30.0
	version.offset_right = -12.0
	version.offset_bottom = -8.0
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)


## Aviso de nova versão (canto de cima) e o botão manual de busca, no canto de baixo.
func _build_update_banner() -> void:
	_update_panel = Brand.make_wood_panel(10)
	_update_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_update_panel.offset_left = -360.0
	_update_panel.offset_right = -20.0
	_update_panel.offset_top = 76.0
	_update_panel.offset_bottom = 77.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_update_panel.add_child(box)
	_update_label = Brand.make_label("", 16)
	_update_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_label.custom_minimum_size = Vector2(316, 0)
	box.add_child(_update_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	_update_button = Brand.make_button("Atualizar", Vector2(150, 46))
	_update_button.add_theme_font_size_override("font_size", 20)
	_update_button.pressed.connect(Updater.apply)
	buttons.add_child(_update_button)
	_dismiss_button = Brand.make_wood_button("Depois", Vector2(110, 46), 18)
	_dismiss_button.pressed.connect(func() -> void:
		_update_dismissed = true
		_refresh_update())
	buttons.add_child(_dismiss_button)
	add_child(_update_panel)

	if Updater.is_configured():
		_check_button = Brand.make_wood_button("Buscar atualização", Vector2(200, 40), 16)
		_check_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		_check_button.offset_left = -220.0
		_check_button.offset_right = -20.0
		_check_button.offset_top = -78.0
		_check_button.offset_bottom = -38.0
		_check_button.pressed.connect(func() -> void:
			_update_manual = true
			_update_dismissed = false
			Updater.check(true)
			_refresh_update())
		add_child(_check_button)
	Updater.state_changed.connect(_refresh_update)
	_refresh_update()
	Updater.check()


func _refresh_update() -> void:
	if _update_panel == null:
		return
	var available: bool = Updater.state == "available"
	var show_message: bool = _update_manual and Updater.state in ["checking", "current", "error"]
	_update_panel.visible = (available or show_message) and not _update_dismissed
	_update_button.visible = available
	_dismiss_button.text = "Depois" if available else "OK"
	var text: String = Updater.message
	if available and Updater.notes != "":
		text += "\n" + Updater.notes.substr(0, 140)
	_update_label.text = text


## Barra de cima: o ouro à esquerda e as opções à direita.
func _build_top_bar() -> void:
	var gold_panel := Brand.make_wood_panel(8)
	gold_panel.position = Vector2(20, 18)
	_gold_label = Brand.make_label("Ouro  %d" % Session.inventory.gold, 20, Brand.GOLD)
	gold_panel.add_child(_gold_label)
	add_child(gold_panel)

	var options := Brand.make_wood_button("Opções", Vector2(120, 48), 20)
	options.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	options.offset_left = -140.0
	options.offset_right = -20.0
	options.offset_top = 18.0
	options.offset_bottom = 66.0
	options.pressed.connect(open_settings)
	add_child(options)
	_options_button = options

	# Engrenagem do administrador: pede a senha e abre o painel de controle do jogo.
	var gear := GearButton.new()
	gear.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gear.offset_left = -198.0
	gear.offset_right = -150.0
	gear.offset_top = 18.0
	gear.offset_bottom = 66.0
	gear.tooltip_text = "Administração"
	gear.pressed.connect(open_admin)
	add_child(gear)
	_gear_button = gear


## Cartão no canto: a próxima fase e as estrelas da última vencida. Toque para ir ao castelo.
func _build_last_mission_card() -> void:
	var card := Brand.make_wood_panel(12)
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	card.offset_left = 20.0
	card.offset_bottom = -222.0
	card.offset_top = -330.0
	card.offset_right = 260.0
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file(CASTLE_SCENE))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var next_stage := Session.highest_unlocked()
	box.add_child(Brand.make_label("PRÓXIMA MISSÃO", 12, Brand.PARCHMENT.darkened(0.2)))
	box.add_child(Brand.make_label("Fase %d" % (next_stage + 1), 24, Brand.GOLD))
	var last_stars := Session.stars_of(next_stage - 1) if next_stage > 0 else 0
	var stars := ""
	for i in 3:
		stars += "★" if i < last_stars else "☆"
	box.add_child(Brand.make_label("Última: %s" % (stars if next_stage > 0 else "nenhuma"), 16, Brand.GOLD))
	box.add_child(Brand.make_label("Toque para continuar", 12, Brand.PARCHMENT.darkened(0.2)))
	_ignore_mouse(card)
	add_child(card)
	_mission_card = card


func _ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control and child != node:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(child)


## Coloca um elemento do cenário com a base na altura `base_y` acima do rodapé.
func _add_scenery(path: String, anchor_x: float, size: Vector2, base_y: float) -> void:
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.anchor_left = anchor_x
	art.anchor_right = anchor_x
	art.anchor_top = 1.0
	art.anchor_bottom = 1.0
	art.offset_left = -size.x * 0.5
	art.offset_right = size.x * 0.5
	art.offset_bottom = -base_y + 12.0
	art.offset_top = art.offset_bottom - size.y
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)


func _make_hero_art(id: String, scale_factor: float) -> TextureRect:
	var art := TextureRect.new()
	art.texture = load(Heroes.get_hero(id)["art"])
	art.custom_minimum_size = Vector2(192, 240) * scale_factor
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_SHRINK_END
	return art


func _make_title(text: String, font_size: int, color: Color) -> Label:
	var label := Brand.make_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## Abre o painel de administração (pede a senha antes).
func open_admin() -> AdminPanel:
	var panel := AdminPanel.new()
	add_child(panel)
	return panel


## Abre a Arena PvP: escolha do rival e da dificuldade.
func open_arena() -> ArenaPopup:
	var popup := ArenaPopup.new()
	add_child(popup)
	return popup


## Abre o catálogo de monstros por cima do menu.
func open_bestiary() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.02, 0.1, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var panel := Brand.make_wood_panel(14)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 120.0
	panel.offset_right = -120.0
	panel.offset_top = 30.0
	panel.offset_bottom = -30.0
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var bestiary := BestiaryPanel.new()
	bestiary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(bestiary)
	var close := Brand.make_wood_button("Fechar", Vector2(0, 46), 20)
	close.pressed.connect(overlay.queue_free)
	box.add_child(close)
	return overlay


## Abre as configurações (volume, tremor de tela, números de dano).
func open_settings() -> SettingsPanel:
	var panel := SettingsPanel.new()
	panel.closed.connect(panel.queue_free)
	add_child(panel)
	return panel
