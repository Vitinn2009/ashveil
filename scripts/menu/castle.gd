extends Control

## Castelo: a base entre as missões. No mercado o herói compra poções, comidas,
## armas, armaduras e acessórios, vende o que pegou nos drops e se equipa antes
## de partir. O ouro e os itens são os mesmos da missão (ver Session).

const GAME_SCENE := "res://scenes/Game.tscn"
const SELECT_SCENE := "res://scenes/CharacterSelect.tscn"
const MENU_SCENE := "res://scenes/Main.tscn"
const SHOP_WIDTH := 690.0
## Altura da barra de cima (voltar, título, ouro) e da de baixo (próxima missão e Partir).
const TOP_BAR := 56.0
const BOTTOM_BAR := 76.0
const SIDE_WIDTH := 316.0
## Largura da caixa de atributos do herói (o menu da direita começa logo depois dela).
const STATS_WIDTH := 212.0
const MENU_ENTRIES := [
	{"id": "market", "name": "Mercado"},
	{"id": "skills", "name": "Habilidades"},
	{"id": "pets", "name": "Pets"},
	{"id": "forge", "name": "Ferreiro"},
	{"id": "runes", "name": "Runas"},
	{"id": "bestiary", "name": "Catálogo"},
]

var category := "potions"
var _stock := {}
var _tabs := {}
var _list: VBoxContainer
var _gold_label: Label
var _missions_label: Label
var _stats_label: Label
var _message: Label
var _sell_commons: Button
var _message_tween: Tween
var _layout_signature := 0
var _stage_label: Label
var _stage_stars_label: Label
var _stage_blurb: Label
var _go_button: Button
var _top_hero: Label
var _top_gold: Label
var _next_label: Label
var _pets_panel: PetsPanel
var _title_label: Label
var _forge_panel: ForgePanel
var _runes_panel: RunesPanel
var _pet_label: Label
var _pet_button: Button
var _level_label: Label
var _mission_popup: Control
var _popup_go: Button
var _stage_numbers: Array[Button] = []
var _right_column: VBoxContainer
var _hero_stats: GridContainer
var _menu_spacer: Control
var _previous_stage: Button
var _next_stage: Button
var _stage_number: Label
var _menu_panel: PanelContainer
var _shortcuts: VBoxContainer
var _menu_buttons := {}
var _menu_content: VBoxContainer
var _minimize_button: Button
var _pages := {}
var _page := "market"
var _minimized := false
var _skills_panel: SkillsPanel
var _bestiary_panel: BestiaryPanel
var _inventory_window: InventoryWindow
var _preview: Player


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hero := Heroes.get_hero(Session.hero_id)
	var inventory := Session.inventory
	inventory.recalc_capacity(int(hero.get("bag_bonus", 0)))
	_stock = Session.ensure_stock()
	_build_backdrop()
	_build_bars()
	_build_side_panel(hero)
	_build_center_stage()
	_build_shop_panel()
	inventory.changed.connect(_refresh)
	select_category("potions")


func inventory() -> Inventory:
	return Session.inventory


# --- Cenário ----------------------------------------------------------------

func _build_backdrop() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 0.8, 1.0])
	gradient.colors = PackedColorArray([Color("1f1c52"), Color("6b4a8c"), Color("e8a56a"), Color("f6c98a")])
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = gradient
	sky_texture.fill_from = Vector2(0.5, 0.0)
	sky_texture.fill_to = Vector2(0.5, 1.0)
	sky_texture.width = 8
	sky_texture.height = 256
	var sky := TextureRect.new()
	sky.texture = sky_texture
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	_add_art("res://assets/world/castle.svg", 0.5, Vector2(830, 480), 168.0)
	var ground := TextureRect.new()
	ground.texture = load("res://assets/world/grass.png")
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -178.0
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	_add_art("res://assets/world/tree_pine.svg", 0.3, Vector2(130, 245), 120.0)
	_add_art("res://assets/world/tree_oak.svg", 0.7, Vector2(200, 250), 120.0)
	_add_art("res://assets/world/market_stall.svg", 0.42, Vector2(250, 208), 48.0)
	_add_art("res://assets/world/bush.svg", 0.57, Vector2(120, 86), 56.0)
	_add_art("res://assets/world/rock_a.svg", 0.34, Vector2(96, 67), 30.0)


## Põe um elemento com a base `base_y` acima do rodapé, centrado em `anchor_x`.
func _add_art(path: String, anchor_x: float, art_size: Vector2, base_y: float) -> void:
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.anchor_left = anchor_x
	art.anchor_right = anchor_x
	art.anchor_top = 1.0
	art.anchor_bottom = 1.0
	art.offset_left = -art_size.x * 0.5
	art.offset_right = art_size.x * 0.5
	art.offset_bottom = -base_y + 8.0
	art.offset_top = art.offset_bottom - art_size.y
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)


# --- Mochila (esquerda) e identificação do herói ----------------------------

## A mochila ocupa o lado esquerdo da tela, sempre aberta (equipar, comparar, vender, ordenar, usar
## chaves). O resto das informações do herói vai numa plaquinha no alto do castelo e nas abas.
func _build_side_panel(hero: Dictionary) -> void:
	# Rótulos de apoio (ouro, missões, mochila): ficam escondidos, o ouro aparece na mochila.
	var hidden := Control.new()
	hidden.visible = false
	add_child(hidden)
	_gold_label = Label.new()
	_missions_label = Label.new()
	_stats_label = Label.new()
	_pet_label = Label.new()
	_pet_button = Button.new()
	for node in [_gold_label, _missions_label, _stats_label, _pet_label, _pet_button]:
		hidden.add_child(node)

	# A janela mostra os atributos de um herói: usa um jogador de fachada, parado e invisível.
	_preview = Player.new()
	_preview.hero_id = Session.hero_id
	_preview.inventory = Session.inventory
	_preview.visible = false
	add_child(_preview)
	_preview.process_mode = Node.PROCESS_MODE_DISABLED
	_inventory_window = InventoryWindow.new()
	_inventory_window.embedded = true
	_inventory_window.dock_top = TOP_BAR + 8.0
	_inventory_window.dock_bottom = BOTTOM_BAR + 8.0
	_inventory_window.pet_changeable = true
	add_child(_inventory_window)
	_inventory_window.bind(_preview)
	_inventory_window.item_selected.connect(_on_item_selected)
	_inventory_window.open()

	# Plaquinha no alto, no centro: nome, evolução, nível e pontos de habilidade.
	var plaque := Brand.make_wood_panel(10, Color(Brand.WOOD, 0.92))
	plaque.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	plaque.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plaque.offset_left = SIDE_WIDTH + 36.0
	plaque.offset_bottom = -(BOTTOM_BAR + 60.0)
	# Nome, título e nível já aparecem na barra de cima; a plaquinha fica só como apoio (escondida).
	plaque.visible = false
	add_child(plaque)
	var plaque_box := VBoxContainer.new()
	plaque_box.add_theme_constant_override("separation", 2)
	plaque.add_child(plaque_box)
	var name_label := Brand.make_label(hero["name"], 22, hero["color"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque_box.add_child(name_label)
	_title_label = Brand.make_label(hero["title"], 12, Brand.BRASS)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque_box.add_child(_title_label)
	_level_label = Brand.make_label("", 13, Color("ffe9a8"))
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque_box.add_child(_level_label)

	# Atributos do herói, no alto, entre a mochila e o menu.
	var stats_panel := Brand.make_wood_panel(10, Color(Brand.WOOD, 0.92))
	stats_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stats_panel.position = Vector2(SIDE_WIDTH + 36.0, TOP_BAR + 10.0)
	stats_panel.custom_minimum_size = Vector2(STATS_WIDTH, 0)
	add_child(stats_panel)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 6)
	stats_panel.add_child(stats_box)
	var stats_title := Brand.make_label("ATRIBUTOS DO HERÓI", 14, Brand.GOLD)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_child(stats_title)
	_hero_stats = GridContainer.new()
	_hero_stats.columns = 2
	_hero_stats.add_theme_constant_override("h_separation", 10)
	_hero_stats.add_theme_constant_override("v_separation", 3)
	stats_box.add_child(_hero_stats)

	# Trocar de herói e menu principal, no pé da tela, entre a mochila e o menu.
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	buttons.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	buttons.offset_left = SIDE_WIDTH + 36.0
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	buttons.offset_bottom = -(BOTTOM_BAR + 10.0)
	add_child(buttons)
	var back := Brand.make_wood_button("Trocar de herói", Vector2(190, 40), 15)
	back.pressed.connect(func() -> void: _leave(SELECT_SCENE))
	buttons.add_child(back)


# --- Barras de cima e de baixo ---------------------------------------------------

## Barra de cima: voltar ao menu, título, herói e ouro. Barra de baixo: a próxima missão e o botão de partir.
func _build_bars() -> void:
	var top := Brand.make_wood_panel(8, Color(Brand.WOOD, 0.97))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = TOP_BAR
	add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top.add_child(top_row)
	var back := Brand.make_wood_button("‹ Menu", Vector2(110, 38), 18)
	back.pressed.connect(func() -> void: _leave(MENU_SCENE))
	top_row.add_child(back)
	top_row.add_child(Brand.make_label("CASTELO", 26, Brand.GOLD))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	_top_hero = Brand.make_label("", 18, Brand.PARCHMENT)
	top_row.add_child(_top_hero)
	_top_gold = Brand.make_label("", 20, Brand.GOLD)
	top_row.add_child(_top_gold)

	var bottom := Brand.make_wood_panel(8, Color(Brand.WOOD, 0.97))
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -BOTTOM_BAR
	add_child(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 16)
	bottom.add_child(bottom_row)
	_next_label = Brand.make_label("", 18, Brand.PARCHMENT)
	_next_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom_row.add_child(_next_label)
	var arena_button := Brand.make_wood_button("ARENA PvP", Vector2(190, 56), 20)
	arena_button.pressed.connect(open_arena_popup)
	bottom_row.add_child(arena_button)
	# Na tela só fica o botão: ele abre a janela de escolha da missão.
	_go_button = Brand.make_wood_button("PARTIR PARA A MISSÃO", Vector2(380, 56), 24)
	_go_button.pressed.connect(open_mission_popup)
	_style_go_button(_go_button)
	bottom_row.add_child(_go_button)


# --- Fases, embaixo à direita ----------------------------------------------------

## Escolha de fase na parte de baixo, à direita (sob o menu): setas dos dois lados do cartão da fase e,
## embaixo, o botão de partir.
func _build_center_stage() -> void:
	# A coluna da direita: o menu estica de cima até o botão de partir, do lado dos atributos do herói até a borda.
	_right_column = VBoxContainer.new()
	_right_column.add_theme_constant_override("separation", 10)
	_right_column.anchor_left = 0.0
	_right_column.anchor_right = 1.0
	_right_column.anchor_top = 0.0
	_right_column.anchor_bottom = 1.0
	_right_column.offset_left = SIDE_WIDTH + 36.0 + STATS_WIDTH + 10.0
	_right_column.offset_right = -16.0
	_right_column.offset_top = TOP_BAR + 10.0
	_right_column.offset_bottom = -(BOTTOM_BAR + 10.0)
	add_child(_right_column)
	_build_mission_popup()


func _style_go_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", Brand.make_box(Color("7a2a14"), Brand.GOLD, 4, 14))
	button.add_theme_stylebox_override("hover", Brand.make_box(Color("9a3a1c"), Color("ffe9a8"), 4, 14))
	button.add_theme_stylebox_override("pressed", Brand.make_box(Color("5a1e0e"), Color("ffe9a8"), 4, 14))
	button.add_theme_stylebox_override("disabled", Brand.make_box(Color("3a2a22"), Color("6a5a4a"), 3, 14))


## A janela de escolha da missão: os números das fases, as setas, o cartão da fase e os botões Partir e Cancelar.
func _build_mission_popup() -> void:
	_mission_popup = Control.new()
	_mission_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mission_popup.visible = false
	add_child(_mission_popup)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.62)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mission_popup.add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_popup.add_child(center)
	var panel := Brand.make_wood_panel(16, Color(Brand.WOOD, 0.98))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(640, 0)
	panel.add_child(column)
	column.add_child(Ribbon.new("ESCOLHER MISSÃO", 40))

	var numbers := HBoxContainer.new()
	numbers.add_theme_constant_override("separation", 6)
	numbers.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(numbers)
	var page_back := Brand.make_wood_button("«", Vector2(44, 44), 18)
	page_back.tooltip_text = "10 fases para trás"
	page_back.pressed.connect(select_stage.bind(-10, true))
	numbers.add_child(page_back)
	for i in 10:
		var number := Brand.make_wood_button(str(i + 1), Vector2(46, 44), 17)
		number.pressed.connect(_on_stage_number.bind(i))
		_stage_numbers.append(number)
		numbers.add_child(number)
	var page_forward := Brand.make_wood_button("»", Vector2(44, 44), 18)
	page_forward.tooltip_text = "10 fases para a frente"
	page_forward.pressed.connect(select_stage.bind(10, true))
	numbers.add_child(page_forward)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	_previous_stage = Brand.make_wood_button("<", Vector2(54, 110), 36)
	_previous_stage.pressed.connect(select_stage.bind(-1, true))
	row.add_child(_previous_stage)
	var card := Brand.make_wood_panel(10, Color(Brand.WOOD, 0.95))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 3)
	card.add_child(text)
	_stage_number = Brand.make_label("", 15, Brand.BRASS)
	_stage_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_child(_stage_number)
	_stage_label = Brand.make_label("", 26, Color("ffe9a8"))
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stage_label.add_theme_color_override("font_outline_color", Color("120a05"))
	_stage_label.add_theme_constant_override("outline_size", 4)
	text.add_child(_stage_label)
	_stage_stars_label = Brand.make_label("", 15, Brand.GOLD)
	_stage_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_child(_stage_stars_label)
	_stage_blurb = Brand.make_label("", 13, Color("b8c9a0"))
	_stage_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stage_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_blurb.custom_minimum_size = Vector2(400, 0)
	text.add_child(_stage_blurb)
	row.add_child(card)
	_next_stage = Brand.make_wood_button(">", Vector2(54, 110), 36)
	_next_stage.pressed.connect(select_stage.bind(1, true))
	row.add_child(_next_stage)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	_popup_go = Brand.make_wood_button("PARTIR", Vector2(0, 58), 22)
	_popup_go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_go.pressed.connect(start_mission)
	_style_go_button(_popup_go)
	buttons.add_child(_popup_go)
	var cancel := Brand.make_wood_button("Cancelar", Vector2(160, 58), 18)
	cancel.pressed.connect(close_mission_popup)
	buttons.add_child(cancel)


## Abre a escolha do adversário da Arena PvP.
func open_arena_popup() -> ArenaPopup:
	var popup := ArenaPopup.new()
	add_child(popup)
	return popup


func open_mission_popup() -> void:
	_refresh_stage()
	_mission_popup.show()


func close_mission_popup() -> void:
	_mission_popup.hide()


func is_mission_popup_open() -> bool:
	return _mission_popup != null and _mission_popup.visible


# --- Mercado ----------------------------------------------------------------

## Menu do castelo, no canto direito: Mercado, Mochila, Habilidades e Catálogo dos monstros, com um
## botão para minimizar (sobra só o botão "Menu" e a tela do castelo fica livre).
func _build_shop_panel() -> void:
	_menu_panel = Brand.make_wood_panel(14)
	_menu_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_column.add_child(_menu_panel)
	_right_column.move_child(_menu_panel, 0)
	_menu_spacer = Control.new()
	_menu_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_column.add_child(_menu_spacer)
	_right_column.move_child(_menu_spacer, 1)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_menu_panel.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	column.add_child(header)
	for entry in MENU_ENTRIES:
		var button := Brand.make_wood_button(entry["name"], Vector2(0, 44), 12)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = entry["id"] != "backpack"
		button.pressed.connect(show_menu.bind(entry["id"]))
		_menu_buttons[entry["id"]] = button
		header.add_child(button)
	_minimize_button = Brand.make_wood_button("—", Vector2(46, 44), 18)
	_minimize_button.tooltip_text = "Minimizar o menu"
	_minimize_button.pressed.connect(toggle_minimized)
	header.add_child(_minimize_button)

	_menu_content = VBoxContainer.new()
	_menu_content.add_theme_constant_override("separation", 8)
	_menu_content.custom_minimum_size = Vector2(0, 200)
	_menu_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_menu_content)

	_pages["market"] = _build_market_page()
	_menu_content.add_child(_pages["market"])
	_skills_panel = SkillsPanel.new()
	_skills_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skills_panel.changed.connect(_refresh)
	_pages["skills"] = _scroll_wrap(_skills_panel)
	_menu_content.add_child(_pages["skills"])
	_forge_panel = ForgePanel.new()
	_forge_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_forge_panel.changed.connect(_refresh)
	_pages["forge"] = _scroll_wrap(_forge_panel)
	_menu_content.add_child(_pages["forge"])
	_runes_panel = RunesPanel.new()
	_runes_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_runes_panel.changed.connect(_refresh)
	_pages["runes"] = _scroll_wrap(_runes_panel)
	_menu_content.add_child(_pages["runes"])
	_pets_panel = PetsPanel.new()
	_pets_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pets_panel.changed.connect(_refresh)
	_pages["pets"] = _pets_panel
	_menu_content.add_child(_pets_panel)
	_bestiary_panel = BestiaryPanel.new()
	_bestiary_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages["bestiary"] = _bestiary_panel
	_menu_content.add_child(_bestiary_panel)
	# Com o menu minimizado, atalhos em coluna abaixo do botão Menu abrem cada página direto.
	_shortcuts = VBoxContainer.new()
	_shortcuts.add_theme_constant_override("separation", 8)
	_shortcuts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_shortcuts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_shortcuts.offset_right = -16.0
	_shortcuts.offset_left = -(16.0 + 150.0)
	_shortcuts.offset_top = 100.0
	add_child(_shortcuts)
	for entry in MENU_ENTRIES:
		var shortcut := Brand.make_wood_button(entry["name"], Vector2(150, 52), 16)
		shortcut.pressed.connect(show_menu.bind(entry["id"]))
		_shortcuts.add_child(shortcut)
	_apply_menu()


func _build_market_page() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	for id in Shop.CATEGORIES:
		var tab := Brand.make_wood_button(Shop.CATEGORY_NAMES[id], Vector2(0, 38), 13)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.toggle_mode = true
		tab.pressed.connect(select_category.bind(id))
		_tabs[id] = tab
		tab_row.add_child(tab)
	column.add_child(tab_row)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list_frame := PanelContainer.new()
	var frame_style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 4)
	frame_style.set_content_margin_all(8)
	list_frame.add_theme_stylebox_override("panel", frame_style)
	list_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	list_frame.add_child(scroll)
	column.add_child(list_frame)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	_message = Brand.make_label("", 16, Color("ffe9a8"))
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_message)
	_sell_commons = Brand.make_wood_button("Vender comuns", Vector2(170, 38), 14)
	_sell_commons.pressed.connect(sell_commons)
	footer.add_child(_sell_commons)
	column.add_child(footer)
	return column


## Abre uma página do menu. A mochila abre a janela do inventário (no canto direito) por cima.
func show_menu(id: String) -> void:
	if _minimized:
		_minimized = false
	_page = id
	if id == "skills":
		_skills_panel.refresh(Session.hero_id)
	elif id == "runes":
		_runes_panel.refresh()
	elif id == "forge":
		_forge_panel.auto_pick()
	elif id == "pets":
		_pets_panel.refresh()
	elif id == "bestiary":
		_bestiary_panel.refresh()
	_apply_menu()


func toggle_minimized() -> void:
	_minimized = not _minimized
	_apply_menu()


func is_minimized() -> bool:
	return _minimized


func current_page() -> String:
	return _page


## Mostra a página escolhida (ou só o botão "Menu", minimizado) e recentra a escolha de fase.
func _apply_menu() -> void:
	for id in _pages:
		_pages[id].visible = not _minimized and id == _page
	for id in _menu_buttons:
		var button: Button = _menu_buttons[id]
		button.visible = not _minimized
		if button.toggle_mode:
			button.set_pressed_no_signal(id == _page)
	_menu_content.visible = not _minimized
	if _shortcuts != null:
		_shortcuts.visible = _minimized
	_minimize_button.text = "Menu" if _minimized else "—"
	_minimize_button.custom_minimum_size = Vector2(110 if _minimized else 46, 44)
	# Aberto, o menu estica até a caixa de fase; minimizado, vira só o botão no canto.
	_menu_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if _minimized else Control.SIZE_EXPAND_FILL
	_menu_panel.size_flags_horizontal = Control.SIZE_SHRINK_END if _minimized else Control.SIZE_FILL
	_menu_panel.custom_minimum_size = Vector2(150.0 if _minimized else 0.0, 0)
	_menu_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL if _minimized else Control.SIZE_SHRINK_BEGIN
	_menu_spacer.custom_minimum_size = Vector2.ZERO


func select_category(id: String) -> void:
	category = id
	for tab_id in _tabs:
		_tabs[tab_id].button_pressed = tab_id == id
	_layout_signature = 0
	_refresh()


func _refresh() -> void:
	_refresh_hero_stats()
	var inv := inventory()
	_gold_label.text = "Ouro: %d" % inv.gold
	_top_gold.text = "Ouro  %d" % inv.gold
	var hero_data := Heroes.get_hero(Session.hero_id)
	var hero_progress := Session.progress_for(Session.hero_id)
	_top_hero.text = "%s · nível %d · %d pontos" % [hero_data["name"], hero_progress["level"], hero_progress["points"]]
	_next_label.text = "Próxima missão: Fase %d · %s" % [Session.stage_index + 1, Stages.get_stage(Session.stage_index)["name"]]
	_missions_label.text = "Missões cumpridas: %d" % Session.missions_done
	_refresh_stage()
	_refresh_pet()
	_sell_commons.visible = category == "sell"
	_stats_label.text = "Mochila %d/%d" % [inv.bag.size(), inv.bag_capacity]
	var progress := Session.progress_for(Session.hero_id)
	_level_label.text = "Nível %d  ·  %d pontos" % [progress["level"], progress["points"]]
	_rebuild_list()


func _rebuild_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	match category:
		"potions":
			_add_consumable_row("potion")
		"food":
			for id in Consumables.FOOD_IDS:
				_add_consumable_row(id)
		"weapons":
			_add_stock_rows("weapons")
		"armor":
			_add_stock_rows("armor")
		"accessories":
			_add_stock_rows("accessories")
		"materials":
			_add_material_rows()
		"sell":
			_add_sell_rows()


func _row_frame() -> HBoxContainer:
	var frame := PanelContainer.new()
	var style := Brand.make_box(Color("2b1d12"), Color("5a4122"), 2, 4)
	style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", style)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	frame.add_child(row)
	_list.add_child(frame)
	return row


func _text_column(title: String, title_color: Color, detail: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(Brand.make_label(title, 18, title_color))
	var detail_label := Brand.make_label(detail, 13, Color("c9bfa8"))
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(240, 0)
	column.add_child(detail_label)
	return column


func _add_consumable_row(id: String) -> void:
	var data := Consumables.def(id)
	var row := _row_frame()
	var slot := ItemSlot.new(60.0)
	slot.show_consumable(id, inventory().count(id))
	slot.disabled = true
	row.add_child(slot)
	row.add_child(_text_column(data["name"], Color("ffe9a8"), data["desc"]))
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	row.add_child(buttons)
	for amount in [1, 5]:
		var price := Shop.pack_price(id, amount)
		var buy := Brand.make_wood_button("Comprar %s  %d" % ["" if amount == 1 else "x%d" % amount, price], Vector2(150, 34), 14)
		buy.disabled = inventory().gold < price
		buy.pressed.connect(func() -> void: buy_consumable(id, amount))
		buttons.add_child(buy)


func _add_stock_rows(group: String) -> void:
	var entries: Array = _stock.get(group, [])
	if entries.is_empty():
		_add_empty_message("Esgotado. O mercador traz novidades depois da próxima missão.")
		return
	for i in entries.size():
		var item: Item = entries[i]["item"]
		var price: int = entries[i]["price"]
		var row := _row_frame()
		var slot := ItemSlot.new(60.0)
		slot.show_item(item)
		slot.disabled = true
		row.add_child(slot)
		row.add_child(_text_column(item.display_name(), item.color(), "%s · %s\n%s" % [item.rarity_name(), Item.SLOT_NAMES[item.slot], item.stats_text()]))
		var buy := Brand.make_wood_button("Comprar  %d" % price, Vector2(130, 44), 15)
		buy.disabled = inventory().gold < price
		buy.pressed.connect(func() -> void: buy_item(group, i))
		row.add_child(buy)


## A aba Materiais: pedras (sempre à venda), pedra da lua, pergaminho, chave de espaço, runas e pacotes de
## fragmentos. O estoque muda a cada missão.
func _add_material_rows() -> void:
	var entries: Array = _stock.get("materials", [])
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var row := _row_frame()
		row.add_child(_material_badge(entry))
		var detail := _material_detail(entry)
		row.add_child(_text_column(entry["name"], _material_color(entry), detail))
		var buy := Brand.make_wood_button("Comprar  %d" % entry["price"], Vector2(130, 44), 15)
		buy.disabled = inventory().gold < int(entry["price"])
		buy.pressed.connect(func() -> void: buy_material(i))
		row.add_child(buy)
	if entries.is_empty():
		_add_empty_message("Esgotado. O mercador traz novidades depois da próxima missão.")


func _material_color(entry: Dictionary) -> Color:
	match entry["kind"]:
		"stone":
			return Color("c9cfd6")
		"moonstone":
			return Color("9fd0ff")
		"scroll":
			return Color("d9a8ff")
		"key":
			return Color("ffd24a")
		"rune":
			return Runes.DATA[str(entry["payload"])]["color"]
		_:
			return Item.RARITIES[int(entry["payload"])]["color"]


func _material_detail(entry: Dictionary) -> String:
	match entry["kind"]:
		"stone":
			return "Forja armas no Ferreiro. Você tem %d." % inventory().stone
		"moonstone":
			return "Forja armas a partir do nível 10 e evolui o herói. Você tem %d." % inventory().moonstone
		"scroll":
			return "Desperta armas e armaduras (50%% de falhar). Você tem %d." % inventory().scrolls
		"key":
			return "Libera +1 espaço na mochila (máximo %d). Você tem %d." % [Inventory.MAX_BAG_SIZE, inventory().slot_keys]
		"rune":
			return "Incrustada num equipamento: %s. Você tem %d." % [Runes.effect_text(str(entry["payload"])), int(inventory().runes.get(str(entry["payload"]), 0))]
		_:
			return "Sobem o nível de raridade dos equipamentos %s. Você tem %d." % [Item.RARITIES[int(entry["payload"])]["name"].to_lower(), inventory().fragments[int(entry["payload"])]]


## Um selo quadrado na cor do material, com a inicial.
func _material_badge(entry: Dictionary) -> Control:
	var badge := PanelContainer.new()
	var style := Brand.make_box(Color("120a05"), _material_color(entry), 3, 6)
	style.set_content_margin_all(4)
	badge.add_theme_stylebox_override("panel", style)
	badge.custom_minimum_size = Vector2(60, 60)
	var amount: int = int(entry["amount"])
	var glyphs := {"stone": "PED", "moonstone": "LUA", "scroll": "PERG", "key": "CHV", "fragment": "FRAG"}
	var glyph: String = str(Runes.DATA[str(entry["payload"])]["glyph"]) if entry["kind"] == "rune" else str(glyphs.get(entry["kind"], "?"))
	var label := Brand.make_label(glyph + ("" if amount == 1 else "
x%d" % amount), 16, _material_color(entry))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge


func buy_material(index: int) -> String:
	var entries: Array = _stock.get("materials", [])
	var name_text := ""
	if index >= 0 and index < entries.size():
		name_text = str(entries[index]["name"])
	var problem := Shop.buy_material(inventory(), entries, index)
	_feedback(problem, "Comprou %s" % name_text)
	return problem


func _add_sell_rows() -> void:
	var inv := inventory()
	if inv.bag.is_empty():
		_add_empty_message("A mochila está vazia. Traga itens das missões para vender aqui.")
		return
	for item in inv.bag:
		var row := _row_frame()
		var slot := ItemSlot.new(60.0)
		slot.show_item(item)
		slot.disabled = true
		row.add_child(slot)
		row.add_child(_text_column(item.display_name(), item.color(), "%s · %s\n%s" % [item.rarity_name(), Item.SLOT_NAMES[item.slot], item.stats_text()]))
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 4)
		var equip := Brand.make_wood_button("Equipar", Vector2(120, 34), 14)
		equip.pressed.connect(func() -> void: equip_item(item))
		buttons.add_child(equip)
		var sell := Brand.make_wood_button("Vender  %d" % item.sell_value(), Vector2(120, 34), 14)
		sell.pressed.connect(func() -> void: sell_item(item))
		buttons.add_child(sell)
		var dismantle := Brand.make_wood_button("Desmantelar  +%d" % item.fragment_value(), Vector2(120, 34), 14)
		dismantle.pressed.connect(func() -> void: dismantle_item(item))
		buttons.add_child(dismantle)
		row.add_child(buttons)


func _add_empty_message(text: String) -> void:
	var label := Brand.make_label(text, 16, Color("a89a80"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(440, 60)
	_list.add_child(label)


# --- Ações ------------------------------------------------------------------

func buy_consumable(id: String, count := 1) -> String:
	var problem := Shop.buy_consumable(inventory(), id, count)
	_feedback(problem, "Comprou %d %s" % [count, Consumables.def(id)["name"]])
	return problem


func buy_item(group: String, index: int) -> String:
	var entries: Array = _stock.get(group, [])
	var name_text := ""
	if index >= 0 and index < entries.size():
		name_text = entries[index]["item"].display_name()
	var problem := Shop.buy_item(inventory(), entries, index)
	_feedback(problem, "Comprou %s" % name_text)
	return problem


func sell_item(item: Item) -> void:
	var value := item.sell_value()
	inventory().sell(item)
	_feedback("", ("Vendeu %s por %d. %s" % [item.display_name(), value, inventory().released_text()]).strip_edges())


func sell_commons() -> int:
	var earned := Shop.sell_commons(inventory())
	_feedback("" if earned > 0 else "Nenhum item comum para vender", ("Vendeu os itens comuns por %d. %s" % [earned, inventory().released_text()]).strip_edges())
	return earned


func equip_item(item: Item) -> void:
	inventory().equip(item)
	_feedback("", "Equipou %s" % item.display_name())


## A mochila do castelo fica sempre aberta, à esquerda: devolve a janela.
func open_inventory() -> InventoryWindow:
	_inventory_window.open()
	return _inventory_window


# --- Fases --------------------------------------------------------------------

## Passa para a fase vizinha (`step`) ou, sem `relative`, vai direto para o índice.
func select_stage(step: int, relative := false) -> void:
	var target := Session.stage_index + step if relative else step
	# Dá para ver até a próxima fase bloqueada; as fases seguintes só depois de vencer as anteriores.
	Session.stage_index = clampi(target, 0, Session.highest_unlocked() + 1)
	_refresh_stage()
	_refresh_pet()


func _refresh_stage() -> void:
	var index := Session.stage_index
	var stage := Stages.get_stage(index)
	var unlocked := Session.is_stage_unlocked(index)
	_stage_number.text = ("FASE %d" % (index + 1)) + (" · CHEFE" if Stages.is_boss_stage(stage) else "")
	_stage_label.text = stage["name"]
	_previous_stage.disabled = index <= 0
	_next_stage.disabled = index >= Session.highest_unlocked() + 1
	var stars := Session.stars_of(index)
	var details := ""
	if Stages.is_boss_stage(stage):
		details = "Chefe: %s" % stage["boss"]["name"]
	else:
		details = "%d min · meta %d abates" % [int(round(float(stage["duration"]) / 60.0)), stage["kill_goal"]]
	if unlocked:
		_stage_stars_label.text = "Estrelas %d/3 · %s" % [stars, details]
	else:
		_stage_stars_label.text = "Bloqueada"
	var journey := ""
	_stage_blurb.text = (str(stage["blurb"]) + journey) if unlocked else "Vença a fase anterior para liberar."
	_popup_go.disabled = not unlocked
	# Os 10 números mostram a página da fase escolhida (1 a 10, 11 a 20...).
	var page_start := (index / 10) * 10
	for i in _stage_numbers.size():
		var number_button := _stage_numbers[i]
		var number_index := page_start + i
		number_button.text = str(number_index + 1)
		number_button.disabled = false
		number_button.modulate = Color.WHITE if Session.is_stage_unlocked(number_index) else Color(0.6, 0.6, 0.6)
		number_button.add_theme_color_override("font_color", Color("ffd24a") if number_index == index else Color("f4e9d8"))


func start_mission() -> void:
	if not Session.is_stage_unlocked(Session.stage_index):
		return
	Session.pvp = false
	Session.save_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func _leave(scene: String) -> void:
	Session.save_game()
	get_tree().change_scene_to_file(scene)


func _feedback(problem: String, success: String) -> void:
	var text := problem if problem != "" else success
	_message.text = text
	_message.add_theme_color_override("font_color", Color("ff8a7a") if problem != "" else Color("b8e68a"))
	if _message_tween:
		_message_tween.kill()
	_message.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(2.5)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.6)


# --- Pet --------------------------------------------------------------------

func _build_pet_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_pet_label = Brand.make_label("", 12, Color("b8c9a0"))
	_pet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_pet_label)
	_pet_button = Brand.make_wood_button("Trocar pet", Vector2(0, 32), 14)
	_pet_button.pressed.connect(func() -> void:
		Session.cycle_pet()
		_refresh_pet())
	box.add_child(_pet_button)
	return box


func _refresh_pet() -> void:
	if _pet_label == null:
		return
	_pet_button.visible = false
	if _title_label != null:
		var evolved := Evolution.title(Session.hero_id, Session.evolution_tier(Session.hero_id))
		_title_label.text = Heroes.get_hero(Session.hero_id)["title"] if evolved == "" else "%s · %s" % [evolved, Heroes.get_hero(Session.hero_id)["title"]]
	if Session.pets.is_empty():
		_pet_label.text = "Pet: nenhum (aba Pets)"
	elif Session.active_pet == "":
		_pet_label.text = "Pet: nenhum ativo (aba Pets)"
	else:
		var data := Pets.get_pet(Session.active_pet)
		_pet_label.text = "Pet: %s (nível %d)\n%s" % [data["name"], Session.pet_level(Session.active_pet),Pets.stats_text(Session.active_pet, Session.pet_level(Session.active_pet))]


## Páginas de tamanho fixo (habilidades e ferreiro) rolam quando o menu é baixo.
func _scroll_wrap(page: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	return scroll


## Os atributos do herói: os mesmos que valem na partida (pontos permanentes, equipamentos com forja, raridade,
## despertar e runas, pet e evolução).
func _refresh_hero_stats() -> void:
	if _hero_stats == null or _preview == null:
		return
	_preview.attributes = Session.perm_for(Session.hero_id).duplicate()
	for stat in ["hp", "defense", "attack", "speed", "luck", "dex", "crit", "aspd", "stamina"]:
		if not _preview.attributes.has(stat):
			_preview.attributes[stat] = 0
	_preview.pet_stats = Session.active_pet_stats()
	_preview.evolution_bonus = Evolution.bonus(Session.hero_id, Session.evolution_tier(Session.hero_id))
	_preview.tree_bonus = SkillTree.bonus(Session.hero_id, Session.tree_levels(Session.hero_id))
	_preview.refresh_stats()
	for child in _hero_stats.get_children():
		_hero_stats.remove_child(child)
		child.queue_free()
	var rows := [
		["Vida", "%d" % int(_preview.get_max_health())],
		["Defesa", "%d" % int(_preview.get_defense())],
		["Ataque", "+%d%%" % int(round((_preview.get_damage_mult() - 1.0) * 100.0))],
		["Vel. de ataque", "+%d%%" % int(round((_preview.get_attack_speed_mult() - 1.0) * 100.0))],
		["Vel. de movimento", "%d" % int(_preview.get_move_speed())],
		["Acerto", "%d%%" % int(round(_preview.get_accuracy() * 100.0))],
		["Destreza", "%d" % _preview.get_dexterity()],
		["Esquiva", "%d%%" % int(round(_preview.get_dodge_chance() * 100.0))],
		["Crítico", "%d%%" % int(round(_preview.get_crit_chance() * 100.0))],
		["Dano crítico", "x%.2f" % _preview.crit_multiplier()],
		["Sorte", "%d" % _preview.get_luck()],
		["Bônus de XP", "+%d%%" % int(round((_preview.get_xp_mult() - 1.0) * 100.0))],
		["Bônus de drops", "+%d%%" % int(round((_preview.get_drop_mult() - 1.0) * 100.0))],
		["Penetração", "%d%%" % int(round(_preview.get_penetration() * 100.0))],
		["Regen de HP", "%.1f/s" % _preview.get_hp_regen()],
		["Regen de energia", "%.1f/s" % _preview.get_energy_regen()],
		["Alcance", "+%d%%" % int(round((_preview.get_range_mult() - 1.0) * 100.0))],
		["Roubo de vida", "%d%%" % int(round(_preview.get_lifesteal() * 100.0))],
		["Refletir", "%d%%" % int(round(_preview.get_reflect() * 100.0))],
		["Vitalidade", "%d" % int(_preview.get_max_stamina())],
		["Energia", "%d" % int(_preview.get_max_energy())],
	]
	for row in rows:
		var name_label := Brand.make_label(row[0], 13, Color("c9bfa8"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_hero_stats.add_child(name_label)
		var value_label := Brand.make_label(row[1], 13, Color("ffe9a8"))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_hero_stats.add_child(value_label)


## Tocar num equipamento da mochila mostra os atributos dele no Ferreiro (quando ele está aberto).
func _on_item_selected(item: Item) -> void:
	if _page == "forge" and not _minimized:
		_forge_panel.set_item(item)


## Os números do popup valem para a página atual (1 a 10, 11 a 20...).
func _on_stage_number(slot: int) -> void:
	select_stage((Session.stage_index / 10) * 10 + slot)


## Desmantela o item: vira fragmentos da raridade dele, como no desmantelamento automático.
func dismantle_item(item: Item) -> int:
	var amount := inventory().convert_to_fragments(item)
	_feedback("" if amount > 0 else "Item não encontrado", ("Desmantelou %s: +%d fragmentos %s. %s" % [item.display_name(), amount, item.rarity_name().to_lower(), inventory().released_text()]).strip_edges())
	return amount
