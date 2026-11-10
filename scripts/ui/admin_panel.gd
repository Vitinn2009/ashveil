class_name AdminPanel
extends Control

## Painel de administração (engrenagem do menu, protegido por senha). Edita os números do jogo todo:
## heróis (vida, dano base...), monstros, chances de drop por raridade e por tipo, e multiplicadores
## gerais. Tudo é gravado na hora (ver Tuning) e vale a partir da próxima partida.

signal closed

const TABS := [
	{"id": "heroes", "name": "Heróis"},
	{"id": "monsters", "name": "Monstros"},
	{"id": "drops", "name": "Drops"},
	{"id": "attributes", "name": "Atributos"},
	{"id": "general", "name": "Geral"},
]

var tab := "heroes"
var hero_id := "mage"
var monster_kind := "slime"
var _panel: PanelContainer
var _body: VBoxContainer
var _content: VBoxContainer
var _tab_buttons := {}
var _password: LineEdit
var _error: Label
var _percent_labels := {}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.72)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	_panel = Brand.make_wood_panel(14, Color(Brand.WOOD, 0.98))
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 70.0
	_panel.offset_right = -70.0
	_panel.offset_top = 24.0
	_panel.offset_bottom = -24.0
	add_child(_panel)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	_panel.add_child(_body)
	if Tuning.unlocked:
		_build_panel()
	else:
		_build_login()


# --- Senha --------------------------------------------------------------------------------------

func _clear_body() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


func _build_login() -> void:
	_clear_body()
	var title := Brand.make_label("ÁREA RESTRITA", 30, Brand.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(title)
	var hint := Brand.make_label("Entre com a senha de administrador.", 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(hint)
	_password = LineEdit.new()
	_password.secret = true
	_password.placeholder_text = "Senha"
	_password.custom_minimum_size = Vector2(320, 50)
	_password.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_password.add_theme_font_size_override("font_size", 22)
	_password.text_submitted.connect(func(_text: String) -> void: submit_password())
	_body.add_child(_password)
	_error = Brand.make_label("", 16, Color("ff7a6a"))
	_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(_error)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	_body.add_child(buttons)
	var enter := Brand.make_button("Entrar", Vector2(180, 52))
	enter.pressed.connect(submit_password)
	buttons.add_child(enter)
	var cancel := Brand.make_wood_button("Cancelar", Vector2(160, 52), 20)
	cancel.pressed.connect(close)
	buttons.add_child(cancel)
	_password.grab_focus.call_deferred()


## Confere a senha digitada; se estiver certa, abre o painel.
func submit_password() -> bool:
	if Tuning.check_password(_password.text):
		Tuning.unlocked = true
		_build_panel()
		return true
	_error.text = "Senha incorreta."
	_password.text = ""
	return false


# --- Painel -------------------------------------------------------------------------------------

func _build_panel() -> void:
	_clear_body()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_body.add_child(header)
	header.add_child(Brand.make_label("PAINEL ADMIN", 26, Brand.GOLD))
	var note := Brand.make_label("As mudanças valem na próxima partida.", 14, Color("b8c9a0"))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(note)
	var close_button := Brand.make_wood_button("Fechar", Vector2(120, 44), 18)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	_body.add_child(tabs)
	for entry in TABS:
		var button := Brand.make_wood_button(entry["name"], Vector2(0, 44), 18)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(show_tab.bind(entry["id"]))
		_tab_buttons[entry["id"]] = button
		tabs.add_child(button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	scroll.add_child(_content)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	_body.add_child(footer)
	var reset_tab := Brand.make_wood_button("Restaurar esta aba", Vector2(0, 44), 16)
	reset_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_tab.pressed.connect(reset_current_tab)
	footer.add_child(reset_tab)
	var reset_all := Brand.make_wood_button("Restaurar tudo ao padrão", Vector2(0, 44), 16)
	reset_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_all.pressed.connect(func() -> void:
		Tuning.reset_all()
		show_tab(tab))
	footer.add_child(reset_all)
	show_tab(tab)


func show_tab(id: String) -> void:
	tab = id
	for tab_id in _tab_buttons:
		_tab_buttons[tab_id].set_pressed_no_signal(tab_id == tab)
	_percent_labels.clear()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	match tab:
		"heroes":
			_build_heroes()
		"monsters":
			_build_monsters()
		"drops":
			_build_drops()
		"attributes":
			_build_attributes()
		_:
			_build_general()


func reset_current_tab() -> void:
	match tab:
		"heroes":
			Tuning.reset_group("heroes")
		"monsters":
			Tuning.reset_group("monsters")
		"drops":
			Tuning.reset_group("rarity")
			Tuning.reset_group("drops")
		"attributes":
			Tuning.reset_group("player")
			Tuning.reset_group("attrs")
		_:
			Tuning.reset_group("global")
	show_tab(tab)


# --- Abas ---------------------------------------------------------------------------------------

func _build_heroes() -> void:
	var picker := HBoxContainer.new()
	picker.add_theme_constant_override("separation", 6)
	_content.add_child(picker)
	for id in Heroes.ids():
		var button := Brand.make_wood_button(Heroes.DATA[id]["name"], Vector2(0, 44), 18)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.set_pressed_no_signal(id == hero_id)
		button.pressed.connect(func() -> void:
			hero_id = id
			show_tab("heroes"))
		picker.add_child(button)
	_content.add_child(Brand.make_label("Atributos base de %s (o que sobe com nível e equipamento é somado depois)" % Heroes.DATA[hero_id]["name"], 14, Color("b8c9a0")))
	var overrides: Dictionary = Tuning.data["heroes"].get(hero_id, {})
	for field in Tuning.HERO_FIELDS:
		var spec: Array = Tuning.HERO_FIELDS[field]
		var base := float(Heroes.DATA[hero_id].get(field, 0.0))
		var current := float(overrides.get(field, base))
		_content.add_child(_row(spec, base, current, field in overrides, func(value: float) -> void: Tuning.set_hero_field(hero_id, field, value)))


func _build_monsters() -> void:
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(0, 46)
	picker.add_theme_font_size_override("font_size", 18)
	var selected := 0
	var index := 0
	for kind in EnemyTypes.DATA:
		picker.add_item(EnemyTypes.DATA[kind]["name"])
		picker.set_item_metadata(index, kind)
		if kind == monster_kind:
			selected = index
		index += 1
	picker.select(selected)
	picker.item_selected.connect(func(i: int) -> void:
		monster_kind = String(picker.get_item_metadata(i))
		show_tab("monsters"))
	_content.add_child(picker)
	var trait_label := Brand.make_label(EnemyTypes.DATA[monster_kind]["trait"], 14, Color("b8c9a0"))
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(trait_label)
	var overrides: Dictionary = Tuning.data["monsters"].get(monster_kind, {})
	for field in Tuning.MONSTER_FIELDS:
		var spec: Array = Tuning.MONSTER_FIELDS[field]
		var base := float(EnemyTypes.DATA[monster_kind].get(field, 0.0))
		var current := float(overrides.get(field, base))
		_content.add_child(_row(spec, base, current, field in overrides, func(value: float) -> void: Tuning.set_monster_field(monster_kind, field, value)))


func _build_drops() -> void:
	_content.add_child(Brand.make_label("Raridade dos equipamentos que caem (peso: quanto maior, mais comum; o % ao lado é a chance real, sem sorte)", 14, Color("b8c9a0")))
	for i in Item.RARITIES.size():
		var rarity: Dictionary = Item.RARITIES[i]
		var base := float(rarity["weight"])
		var current := Tuning.rarity_weight(i, base)
		var on_change := func(value: float) -> void:
			Tuning.set_rarity_weight(i, value)
			_refresh_percents()
		var row := _row([rarity["name"], 0.0, 1000.0, 0.01], base, current, Tuning.data["rarity"].has(str(i)), on_change, rarity["color"])
		var percent := Brand.make_label("", 16, rarity["color"])
		percent.custom_minimum_size = Vector2(90, 0)
		_percent_labels[i] = percent
		row.add_child(percent)
		_content.add_child(row)
	_refresh_percents()
	_content.add_child(Brand.make_label("Chance de espólio por monstro derrotado (%)", 14, Color("b8c9a0")))
	for key in Tuning.DROP_FIELDS:
		var spec: Array = Tuning.DROP_FIELDS[key]
		var base := float(spec[1]) * 100.0
		var current := Tuning.drop(key, float(spec[1])) * 100.0
		_content.add_child(_row([spec[0], 0.0, 100.0, 0.1], base, current, Tuning.data["drops"].has(key), func(value: float) -> void: Tuning.set_drop(key, value / 100.0)))


func _build_attributes() -> void:
	_content.add_child(Brand.make_label("Efeito de cada ponto e limites do herói (o padrão é o valor original do jogo)", 14, Color("b8c9a0")))
	var fields := Tuning.player_fields()
	for key in fields:
		var spec: Array = fields[key]
		var base := float(spec[4])
		var current := Tuning.player(key, base)
		_content.add_child(_row([spec[0], spec[1], spec[2], spec[3]], base, current, Tuning.data["player"].has(key), func(value: float) -> void: Tuning.set_player(key, value)))
	_content.add_child(Brand.make_label("Cada atributo: pontos iniciais (padrão), mínimo e máximo que o herói pode ter (soma de pontos, equipamento e bônus)", 14, Color("b8c9a0")))
	for stat in Tuning.ATTRIBUTES:
		_content.add_child(_attribute_row(stat))


## Uma linha por atributo, com três campos: inicial, mínimo e máximo.
func _attribute_row(stat: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var edited: bool = Tuning.data["attrs"].has(stat)
	var label := Brand.make_label(String(Tuning.ATTRIBUTE_NAMES[stat]), 17, Brand.GOLD if edited else Brand.PARCHMENT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	for field in [["base", "inicial", 0, 0, 100], ["min", "mín.", 0, 0, 100], ["max", "máx.", 100, 1, 999]]:
		var caption := Brand.make_label(String(field[1]), 13, Color("8f8a78"))
		caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(caption)
		var box := SpinBox.new()
		box.min_value = float(field[3])
		box.max_value = float(field[4])
		box.step = 1.0
		box.custom_minimum_size = Vector2(110, 42)
		box.value = float(Tuning.attr(stat, field[0], int(field[2])))
		var field_name: String = field[0]
		box.value_changed.connect(func(value: float) -> void:
			Tuning.set_attr(stat, field_name, int(value))
			label.add_theme_color_override("font_color", Brand.GOLD))
		row.add_child(box)
	return row


func _build_general() -> void:
	_content.add_child(Brand.make_label("Multiplicadores gerais (1,00 = padrão)", 14, Color("b8c9a0")))
	for key in Tuning.GLOBAL_FIELDS:
		var spec: Array = Tuning.GLOBAL_FIELDS[key]
		_content.add_child(_row(spec, 1.0, Tuning.glob(key), Tuning.data["global"].has(key), func(value: float) -> void: Tuning.set_global(key, value)))


# --- Peças --------------------------------------------------------------------------------------

## Uma linha: nome, campo numérico e o valor padrão. `spec` = [nome, mínimo, máximo, passo].
func _row(spec: Array, base: float, current: float, edited: bool, on_change: Callable, color := Brand.PARCHMENT) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Brand.make_label(String(spec[0]), 17, Brand.GOLD if edited else color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var box := SpinBox.new()
	box.min_value = float(spec[1])
	box.max_value = float(spec[2])
	box.step = float(spec[3])
	box.custom_minimum_size = Vector2(170, 42)
	box.value = current
	box.value_changed.connect(func(value: float) -> void:
		on_change.call(value)
		label.add_theme_color_override("font_color", Brand.GOLD))
	row.add_child(box)
	var default_label := Brand.make_label("padrão %s" % _format(base), 14, Color("8f8a78"))
	default_label.custom_minimum_size = Vector2(110, 0)
	default_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(default_label)
	return row


func _format(value: float) -> String:
	return str(snappedf(value, 0.001))


## Mostra a chance real de cada raridade (peso dividido pela soma dos pesos).
func _refresh_percents() -> void:
	var total := 0.0
	for i in Item.RARITIES.size():
		total += Tuning.rarity_weight(i, float(Item.RARITIES[i]["weight"]))
	for i in _percent_labels:
		var weight := Tuning.rarity_weight(i, float(Item.RARITIES[i]["weight"]))
		_percent_labels[i].text = "%.2f%%" % (weight / maxf(total, 0.0001) * 100.0)


func close() -> void:
	closed.emit()
	queue_free()
