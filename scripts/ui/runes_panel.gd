class_name RunesPanel
extends VBoxContainer

## Página "Runas" do menu do castelo: as runas (uma por atributo, raridades C a SS) são incrustadas nos equipamentos e
## nas armas vestidos (de 1 a 4 casas por peça, conforme a raridade). Cada runa soma pontos de um
## atributo àquela peça; tirar uma runa de uma casa a destrói.

signal changed

var _index := 0
var _stock: Label
var _item_label: Label
var _socket_row: HBoxContainer
var _insert_box: VBoxContainer
var _message: Label
var _fuse_all: Button


## Uma casa de runa: moldura com a gema da runa (ou vazia).
class Socket extends Control:
	var rune_id := ""

	func _init(id := "") -> void:
		rune_id = id
		custom_minimum_size = Vector2(56, 56)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("120a05"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("3a2a1a"), false, 2.0)
		if rune_id == "":
			return
		var color: Color = Runes.DATA[rune_id]["color"]
		var c := size * 0.5
		draw_circle(c, 21.0, Color(color, 0.25))
		var points := PackedVector2Array([c + Vector2(0, -19), c + Vector2(15, -6), c + Vector2(10, 15), c + Vector2(-10, 15), c + Vector2(-15, -6)])
		draw_colored_polygon(points, color.darkened(0.35))
		draw_polyline(points + PackedVector2Array([points[0]]), color.lightened(0.4), 2.0)
		draw_string(get_theme_default_font(), Vector2(0, c.y + 8), str(Runes.DATA[rune_id]["glyph"]), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, color.lightened(0.7))


func _init() -> void:
	add_theme_constant_override("separation", 8)
	add_child(Ribbon.new("RUNAS", 40))
	var help := Brand.make_label("Incruste runas nos equipamentos e nas armas. Comum tem 1 casa, raro 2, épico 3 e lendário 4. Tirar uma runa a destrói.", 13, Color("b8c9a0"))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(380, 0)
	add_child(help)
	_stock = Brand.make_label("", 14, Color("ffe9a8"))
	_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stock.custom_minimum_size = Vector2(380, 0)
	add_child(_stock)
	_fuse_all = Brand.make_wood_button("Fundir todas", Vector2(0, 38), 14)
	_fuse_all.pressed.connect(_on_fuse_all)
	add_child(_fuse_all)

	var card := PanelContainer.new()
	var style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var previous := Brand.make_wood_button("<", Vector2(44, 52), 20)
	previous.pressed.connect(_step.bind(-1))
	row.add_child(previous)
	_item_label = Brand.make_label("", 15, Color("ffe9a8"))
	_item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_item_label)
	var next := Brand.make_wood_button(">", Vector2(44, 52), 20)
	next.pressed.connect(_step.bind(1))
	row.add_child(next)
	column.add_child(row)
	_socket_row = HBoxContainer.new()
	_socket_row.add_theme_constant_override("separation", 12)
	_socket_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_socket_row)
	_insert_box = VBoxContainer.new()
	_insert_box.add_theme_constant_override("separation", 6)
	column.add_child(_insert_box)
	add_child(card)
	_message = Brand.make_label("", 14, Color("ffe9a8"))
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_message)


func _keys() -> Array:
	var keys: Array = []
	for key in Item.EQUIP_KEYS:
		if Session.inventory.equipped.has(key):
			keys.append(key)
	return keys


func _step(step: int) -> void:
	var keys := _keys()
	if not keys.is_empty():
		_index = posmod(_index + step, keys.size())
	refresh()


func refresh() -> void:
	var inventory := Session.inventory
	var keys := _keys()
	_index = clampi(_index, 0, maxi(keys.size() - 1, 0))
	var owned: Array = []
	var total := 0
	for id in Runes.ids():
		var count := int(inventory.runes.get(id, 0))
		if count > 0:
			owned.append(id)
			total += count
	# Das mais raras para as mais comuns.
	owned.sort_custom(func(a: String, b: String) -> bool:
		if Runes.tier_of(a) != Runes.tier_of(b):
			return Runes.tier_of(a) > Runes.tier_of(b)
		return a < b)
	_stock.text = "%d runas guardadas (%d tipos). Três iguais se fundem numa da raridade seguinte." % [total, owned.size()]
	var can_fuse := false
	for rune_id in owned:
		can_fuse = can_fuse or (Runes.next_tier_id(rune_id) != "" and int(inventory.runes.get(rune_id, 0)) >= Runes.FUSE_COST)
	_fuse_all.disabled = not can_fuse
	for container in [_socket_row, _insert_box]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	var key := ""
	var item: Item = null
	if keys.is_empty():
		_item_label.text = "Nenhum equipamento vestido"
	else:
		key = keys[_index]
		item = inventory.equipped[key]
		_item_label.text = "%s · %s\n%s" % [item.display_name(), Item.SLOT_NAMES[key], item.stats_text()]
		_item_label.add_theme_color_override("font_color", item.color())
		for i in item.socket_count():
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", 4)
			cell.add_child(Socket.new(item.rune_in(i)))
			if item.rune_in(i) != "":
				var remove := Brand.make_wood_button("Tirar", Vector2(56, 26), 12)
				remove.pressed.connect(_on_remove.bind(key, i))
				cell.add_child(remove)
			_socket_row.add_child(cell)
	if owned.is_empty():
		_insert_box.add_child(Brand.make_label("Você ainda não tem runas. Elas caem dos monstros (chefes soltam as melhores) e são vendidas no Mercado.", 13, Color("a89a80")))
	for id in owned:
		_insert_box.add_child(_make_rune_row(id, key, item))


## Uma runa guardada: gema, nome, efeito, quantidade e os botões Incrustar e Fundir.
func _make_rune_row(id: String, key: String, item: Item) -> Control:
	var inventory := Session.inventory
	var data: Dictionary = Runes.DATA[id]
	var count := int(inventory.runes.get(id, 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var gem := Socket.new(id)
	gem.custom_minimum_size = Vector2(44, 44)
	row.add_child(gem)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	text.add_child(Brand.make_label("%s  x%d" % [data["name"], count], 14, data["color"]))
	text.add_child(Brand.make_label(Runes.effect_text(id), 12, Brand.PARCHMENT))
	row.add_child(text)
	var insert := Brand.make_wood_button("Incrustar", Vector2(96, 36), 13)
	insert.disabled = item == null or item.rune_in_free() < 0
	if item != null:
		insert.pressed.connect(_on_insert.bind(key, id))
	row.add_child(insert)
	var next := Runes.next_tier_id(id)
	var fuse := Brand.make_wood_button("Fundir 3 → %s" % (Runes.TIERS[Runes.tier_of(id) + 1] if next != "" else "-"), Vector2(112, 36), 13)
	fuse.disabled = next == "" or count < Runes.FUSE_COST
	fuse.pressed.connect(_on_fuse.bind(id))
	row.add_child(fuse)
	return row


func _on_fuse(id: String) -> void:
	var error := Session.inventory.fuse_rune(id)
	var next := Runes.next_tier_id(id)
	_say(error if error != "" else "3 runas viraram %s!" % Runes.DATA[next]["name"], Color("ff7a6a") if error != "" else Runes.DATA[next]["color"])
	if error == "":
		Sound.play("level")
	refresh()
	changed.emit()


func _on_insert(key: String, id: String) -> void:
	var error := Session.inventory.socket_rune(key, id)
	_say(error if error != "" else "%s incrustada!" % Runes.DATA[id]["name"], Color("ff7a6a") if error != "" else Runes.DATA[id]["color"])
	if error == "":
		Sound.play("level")
	refresh()
	changed.emit()


func _on_remove(key: String, index: int) -> void:
	Session.inventory.remove_rune_from(key, index)
	_say("Runa removida (perdida).", Color("ff7a6a"))
	refresh()
	changed.emit()


func _say(text: String, color: Color) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)


## Funde tudo o que dá, de uma vez: três runas iguais viram uma da raridade seguinte, da C para cima.
func _on_fuse_all() -> void:
	var fusions := Session.inventory.fuse_all_runes()
	if fusions > 0:
		_say("%d fusões feitas!" % fusions, Color("ffd24a"))
		Sound.play("level")
	else:
		_say("Não há três runas iguais para fundir.", Color("ff7a6a"))
	refresh()
	changed.emit()
