class_name DiamondShopPanel
extends VBoxContainer

## Página "Diamantes" do castelo: a loja premium. Em cima, o saldo; abaixo, abas com os pacotes de diamantes
## (dinheiro de verdade, via Billing), os heróis pagos, os pets, os equipamentos e os pacotes de itens
## (todos comprados com diamantes). Os preços vêm de Premium e podem ser mudados no painel admin.

signal changed

const TABS := [
	{"id": "packs", "name": "Diamantes"},
	{"id": "hero", "name": "Heróis"},
	{"id": "pet", "name": "Pets"},
	{"id": "gear", "name": "Equipamentos"},
	{"id": "item", "name": "Itens"},
]
const DIAMOND_COLOR := Color("7ad0ff")

var tab := "packs"
var _balance: Label
var _message: Label
var _tab_buttons := {}
var _list: VBoxContainer
var _test_check: CheckBox


func _init() -> void:
	add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	add_child(head)
	head.add_child(DiamondIcon.new())
	_balance = Brand.make_label("", 22, DIAMOND_COLOR)
	_balance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_balance.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_balance)
	_test_check = CheckBox.new()
	_test_check.text = "Modo teste (admin): compras grátis"
	_test_check.add_theme_font_size_override("font_size", 12)
	_test_check.visible = false
	_test_check.toggled.connect(func(on: bool) -> void: Tuning.test_purchases = on)
	head.add_child(_test_check)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	add_child(tabs)
	for entry in TABS:
		var button := Brand.make_wood_button(entry["name"], Vector2(0, 38), 13)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(show_tab.bind(entry["id"]))
		_tab_buttons[entry["id"]] = button
		tabs.add_child(button)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame := PanelContainer.new()
	var style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 4)
	style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", style)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	frame.add_child(scroll)
	add_child(frame)

	_message = Brand.make_label("", 15, Color("ffe9a8"))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_message)


func refresh() -> void:
	_balance.text = "Diamantes: %d" % Session.diamonds
	_test_check.visible = Tuning.unlocked
	_test_check.set_pressed_no_signal(Tuning.test_purchases)
	for tab_id in _tab_buttons:
		_tab_buttons[tab_id].set_pressed_no_signal(tab_id == tab)
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	if tab == "packs":
		_list.add_child(_note("Os pacotes são comprados com dinheiro de verdade pelo Google Play."))
		for pack in Premium.PACKS:
			_list.add_child(_pack_row(Premium.pack(pack["id"])))
	else:
		for entry in Premium.entries_of(tab):
			_list.add_child(_entry_row(entry))


func show_tab(id: String) -> void:
	tab = id
	_message.text = ""
	refresh()


func _note(text: String) -> Label:
	var label := Brand.make_label(text, 13, Color("b8c9a0"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _frame() -> Array:
	var frame := PanelContainer.new()
	var style := Brand.make_box(Color("241810"), Brand.BRASS_DARK, 2, 6)
	style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	frame.add_child(row)
	return [frame, row]


func _texts(row: HBoxContainer, title: String, description: String, title_color := Color("ffe9a8")) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 1)
	row.add_child(column)
	column.add_child(Brand.make_label(title, 16, title_color))
	var text := Brand.make_label(description, 12, Brand.PARCHMENT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(240, 0)
	column.add_child(text)


func _pack_row(pack: Dictionary) -> Control:
	var parts := _frame()
	var row: HBoxContainer = parts[1]
	row.add_child(DiamondIcon.new())
	_texts(row, "%s · %d diamantes" % [pack["name"], pack["diamonds"]], "Cada diamante compra produtos premium na loja.", DIAMOND_COLOR)
	var price := ("R$ %.2f" % float(pack["brl"])).replace(".", ",")
	var button := Brand.make_button(price, Vector2(150, 48))
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_on_pack_pressed.bind(String(pack["id"])))
	row.add_child(button)
	return parts[0]


func _entry_row(entry: Dictionary) -> Control:
	var parts := _frame()
	var row: HBoxContainer = parts[1]
	var id: String = entry["id"]
	row.add_child(_entry_icon(entry))
	var color := Color("ffe9a8")
	if entry["kind"] == "gear":
		color = Item.RARITIES[int(entry["rarity"])]["color"]
	_texts(row, String(entry["name"]), String(entry["desc"]), color)
	var owned := Premium.owned(id)
	var cost := Premium.price(id)
	var button: Button
	if owned:
		button = Brand.make_wood_button("Comprado", Vector2(150, 44), 16)
		button.disabled = true
	else:
		button = Brand.make_button("%d diamantes" % cost, Vector2(150, 44))
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_on_buy_pressed.bind(id))
	row.add_child(button)
	return parts[0]


## O quadradinho da esquerda: o retrato do herói, a cor do pet ou a raridade do equipamento.
func _entry_icon(entry: Dictionary) -> Control:
	var holder := PanelContainer.new()
	var border := Brand.BRASS
	if entry["kind"] == "gear":
		border = Item.RARITIES[int(entry["rarity"])]["color"]
	var style := Brand.make_box(Color("120a05"), border, 3, 8)
	style.set_content_margin_all(4)
	holder.add_theme_stylebox_override("panel", style)
	holder.custom_minimum_size = Vector2(60, 60)
	match entry["kind"]:
		"hero":
			var art := TextureRect.new()
			art.texture = load(Heroes.get_hero(String(entry["hero"]))["art"])
			art.custom_minimum_size = Vector2(52, 52)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			holder.add_child(art)
		"pet":
			var follower := PetFollower.new()
			follower.pet_id = String(entry["pet"])
			follower.position = Vector2(30, 34)
			follower.scale = Vector2(1.5, 1.5)
			holder.add_child(follower)
		_:
			var label := Brand.make_label(String(entry["name"]).substr(0, 2).to_upper(), 20, border)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			holder.add_child(label)
	return holder


func _on_buy_pressed(id: String) -> void:
	var error := Premium.buy(id)
	if error == "":
		_message.text = "Comprado: %s!" % Premium.entry(id)["name"]
		Sound.play("level")
	else:
		_message.text = error
	refresh()
	changed.emit()


func _on_pack_pressed(id: String) -> void:
	var error := Premium.buy_pack(id)
	if error == "":
		_message.text = "Diamantes recebidos! Saldo: %d" % Session.diamonds
		Sound.play("level")
	else:
		_message.text = error
	refresh()
	changed.emit()


## Ícone de diamante desenhado (a fonte do jogo não tem o símbolo).
class DiamondIcon extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(32, 32)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var gem := PackedVector2Array([c + Vector2(0, -13), c + Vector2(11, -3), c + Vector2(0, 13), c + Vector2(-11, -3)])
		draw_colored_polygon(gem, Brand.NIGHT)
		var inner := PackedVector2Array([c + Vector2(0, -11), c + Vector2(9, -3), c + Vector2(0, 11), c + Vector2(-9, -3)])
		draw_colored_polygon(inner, Color("7ad0ff"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11), c + Vector2(9, -3), c + Vector2(0, -2), c + Vector2(-9, -3)]), Color("c4ecff"))
		draw_line(c + Vector2(-9, -3), c + Vector2(0, -2), Color("3f9acb"), 1.5)
		draw_line(c + Vector2(9, -3), c + Vector2(0, -2), Color("3f9acb"), 1.5)
