extends Control

## Escolha do herói: grade de cartões à esquerda e, à direita, o painel com os atributos e as
## habilidades de quem está selecionado. Os botões ficam sempre à vista, embaixo.

const CASTLE_SCENE := "res://scenes/Castle.tscn"
const MENU_SCENE := "res://scenes/Main.tscn"
const MAX_HEALTH := 150.0
const MAX_SPEED := 180.0
const MAX_DAMAGE := 30.0
const MAX_ENERGY := 140.0
const GRID_WIDTH := 560.0

var _selected := "mage"
var _cards := {}
var _start_button: Button
var _detail_box: VBoxContainer
var _notice: Label
var _lock_labels := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Brand.NIGHT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 20.0
	column.offset_right = -20.0
	column.offset_top = 12.0
	column.offset_bottom = -12.0
	column.add_theme_constant_override("separation", 12)
	add_child(column)

	var title := Brand.make_label("Escolha seu herói", 30, Brand.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	column.add_child(body)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.custom_minimum_size = Vector2(GRID_WIDTH, 0)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	body.add_child(grid)
	for id in Heroes.ids():
		var card := _make_card(id)
		_cards[id] = card
		grid.add_child(card)

	# O painel de detalhes rola na vertical se a tela for baixa.
	var detail_panel := Brand.make_wood_panel(14)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_detail_box)

	_notice = Brand.make_label("", 16, Color("ffe9a8"))
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_notice)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	column.add_child(buttons)
	var back := Brand.make_button("Voltar", Vector2(200, 56))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	buttons.add_child(back)
	_start_button = Brand.make_button("Ir ao castelo", Vector2(440, 56))
	_start_button.pressed.connect(start_game)
	buttons.add_child(_start_button)

	select_hero(Session.hero_id if Heroes.DATA.has(Session.hero_id) else "mage")


func select_hero(id: String) -> void:
	_selected = id
	for card_id in _cards:
		var chosen: bool = card_id == id
		var border: Color = Brand.GOLD if chosen else Color("5a4a8a")
		var bg := Color("2a1a4d") if chosen else Color(Brand.NIGHT, 0.9)
		_cards[card_id].add_theme_stylebox_override("panel", _card_style(bg, border, 5 if chosen else 2))
		_cards[card_id].modulate = Color.WHITE if chosen else Color(0.82, 0.82, 0.88)
	_notice.text = ""
	if Session.hero_owned(id):
		_start_button.text = "Ir ao castelo com %s" % Heroes.get_hero(id)["name"]
	else:
		_start_button.text = "Comprar %s · %d diamantes" % [Heroes.get_hero(id)["name"], Premium.price("hero_" + id)]
	_fill_details(id)


## Grava o herói escolhido e segue para o castelo, onde fica o mercado. Herói pago ainda não comprado:
## o botão compra (com diamantes) em vez de seguir.
func start_game() -> void:
	if not Session.hero_owned(_selected):
		var error := Premium.buy("hero_" + _selected)
		if error != "":
			_notice.text = "%s. Compre diamantes na loja do castelo." % error if error.begins_with("Faltam") else error
			return
		_notice.text = "%s desbloqueado!" % Heroes.get_hero(_selected)["name"]
		if _lock_labels.has(_selected):
			_lock_labels[_selected].queue_free()
			_lock_labels.erase(_selected)
		_cards[_selected].modulate = Color.WHITE
		_start_button.text = "Ir ao castelo com %s" % Heroes.get_hero(_selected)["name"]
		return
	Session.hero_id = _selected
	Session.save_game()
	get_tree().change_scene_to_file(CASTLE_SCENE)


func _card_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := Brand.make_box(background, border, width, 16)
	style.set_content_margin_all(10)
	return style


## Dano que o herói causa de uma vez: o bacamarte solta 4 fragmentos.
func _burst_damage(hero: Dictionary) -> float:
	return hero["damage"] * (Weapon.FRAGMENTS if hero["attack"] == "blunderbuss" else 1.0)


## Cartão da grade: só o retrato, o nome e o nível. O resto fica no painel de detalhes.
func _make_card(id: String) -> PanelContainer:
	var hero := Heroes.get_hero(id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2((GRID_WIDTH - 28.0) / 3.0, 190)
	# PASS deixa o arrasto do dedo chegar à rolagem, e o toque ainda escolhe o herói.
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			select_hero(id))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)

	var art := TextureRect.new()
	art.texture = load(hero["art"])
	art.custom_minimum_size = Vector2(0, 110)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(art)

	var name_label := Brand.make_label(hero["name"], 26, hero["color"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	if Session.hero_owned(id):
		var level := Brand.make_label("Nível %d" % Session.progress_for(id)["level"], 14, Brand.PARCHMENT.darkened(0.15))
		level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(level)
	else:
		var lock := Brand.make_label("Bloqueado · %d diamantes" % Premium.price("hero_" + id), 12, Color("7ad0ff"))
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(lock)
		_lock_labels[id] = lock

	_ignore_mouse(card)
	return card


## Painel da direita: título, descrição, barras de atributos e habilidades do herói escolhido.
func _fill_details(id: String) -> void:
	for child in _detail_box.get_children():
		_detail_box.remove_child(child)
		child.queue_free()
	var hero := Heroes.get_hero(id)
	_detail_box.add_child(Brand.make_label(hero["name"], 32, hero["color"]))
	_detail_box.add_child(Brand.make_label(hero["title"], 16, Brand.GOLD))
	var description := Brand.make_label(hero["description"], 14)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(300, 0)
	_detail_box.add_child(description)

	_detail_box.add_child(_make_stat_row("Vida", hero["health"] / MAX_HEALTH, Color("d8452e")))
	_detail_box.add_child(_make_stat_row("Dano", _burst_damage(hero) / MAX_DAMAGE, Brand.GOLD))
	_detail_box.add_child(_make_stat_row("Veloc.", hero["speed"] / MAX_SPEED, Color("6fb06f")))
	_detail_box.add_child(_make_stat_row("Energia", hero["energy"] / MAX_ENERGY, Color("4a90e8")))

	_detail_box.add_child(Brand.make_label("Habilidades", 16, Brand.GOLD))
	for entry in Heroes.skill_entries(hero):
		var skill := Skills.def(entry["id"])
		var locked: int = entry["unlock_level"]
		var text := "• %s: %s" % [skill["name"], skill["desc"]]
		if locked > 0:
			text = "• %s (nível %d): %s" % [skill["name"], locked, skill["desc"]]
		var line := Brand.make_label(text, 13, Color("d8d2f0") if locked == 0 else Color("a89ec8"))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(300, 0)
		_detail_box.add_child(line)


func _make_stat_row(label_text: String, ratio: float, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Brand.make_label(label_text, 14)
	label.custom_minimum_size = Vector2(64, 0)
	row.add_child(label)
	var bar := Brand.make_bar(color, 14.0)
	bar.max_value = 1.0
	bar.value = clampf(ratio, 0.05, 1.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	return row


## Só o cartão recebe cliques; os filhos deixam o clique passar.
func _ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(child)
