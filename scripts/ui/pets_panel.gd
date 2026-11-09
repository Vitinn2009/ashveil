class_name PetsPanel
extends VBoxContainer

## Página "Pets" do menu do castelo: os pets conquistados dos chefes (e os que faltam), com o nível,
## os atributos de cada um, o botão de ativar e a melhoria paga com ouro.

signal changed

var _list: VBoxContainer
var _summary: Label


## O retrato do pet: o mesmo desenho do pet que segue o herói, numa moldura.
class Portrait extends Control:
	var _pet: PetFollower

	func _init(pet_id := "") -> void:
		custom_minimum_size = Vector2(76, 76)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		_pet = PetFollower.new()
		_pet.pet_id = pet_id
		_pet.scale = Vector2(2.0, 2.0)
		_pet.position = Vector2(38.0, 44.0)
		add_child(_pet)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("120a05"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("3a2a1a"), false, 2.0)

	func set_known(value: bool) -> void:
		_pet.modulate = Color.WHITE if value else Color(0.0, 0.0, 0.0, 0.85)


func _init() -> void:
	add_theme_constant_override("separation", 8)
	add_child(Ribbon.new("PETS", 40))
	_summary = Brand.make_label("", 14, Color("b8c9a0"))
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size = Vector2(380, 0)
	add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	add_child(scroll)


func refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_summary.text = "Ouro: %d · %d de %d pets · o pet ativo soma atributos fixos e atira nos inimigos; o nível só aumenta o dano dele" % [
		Session.inventory.gold, Session.pets.size(), Pets.ids().size()]
	# Os conquistados primeiro, depois os que faltam (mais perto de sair primeiro).
	var owned: Array = []
	var locked: Array = []
	for id in Pets.ids():
		if Session.pets.has(id):
			owned.append(id)
		else:
			locked.append(id)
	locked.sort_custom(func(a: String, b: String) -> bool: return Session.kills_left_for(a) < Session.kills_left_for(b))
	for id in owned + locked:
		_list.add_child(_make_row(id))


func _make_row(id: String) -> Control:
	var data := Pets.get_pet(id)
	var owned := Session.pets.has(id)
	var level := Session.pet_level(id)
	var frame := PanelContainer.new()
	var style := Brand.make_box(Color("1a100a"), Brand.BRASS if Session.active_pet == id else Brand.BRASS_DARK, 2, 6)
	style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	frame.add_child(row)
	var portrait := Portrait.new(id)
	portrait.set_known(owned)
	row.add_child(portrait)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 3)
	row.add_child(column)
	if not owned:
		column.add_child(Brand.make_label("???  (%s)" % data["name"] if data.has("kind") else "???", 17, Color("8a7f6a")))
		var hint := Brand.make_label("%s para conquistar este pet." % Pets.unlock_text(id), 13, Color("b8c9a0"))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)
		if data.has("kind"):
			var done := Session.kills_of(str(data["kind"]))
			var bar := MedievalBar.new(14.0, 0.0)
			bar.max_value = Pets.KILLS_TO_UNLOCK
			bar.value = mini(done, Pets.KILLS_TO_UNLOCK)
			bar.label_text = "%d / %d abates" % [mini(done, Pets.KILLS_TO_UNLOCK), Pets.KILLS_TO_UNLOCK]
			bar.show_ticks = false
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(bar)
		var locked_stats := Brand.make_label("Atributos: %s" % Pets.stats_text(id), 12, Color("8a7f6a"))
		locked_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(locked_stats)
		return frame
	column.add_child(Brand.make_label("%s · Nível %d" % [data["name"], level], 18, Color("ffe9a8")))
	column.add_child(Brand.make_label(("Chefe: %s" % data["boss"]) if data.has("boss") else ("Monstro: %s" % data["monster"]), 12, Color("b8c9a0")))
	var stats := Brand.make_label("Atributos fixos: %s" % Pets.stats_text(id), 13, Brand.PARCHMENT)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats)
	var damage := Brand.make_label("Dano do tiro: %d  →  %d no próximo nível" % [int(Pets.attack_damage(level)), int(Pets.attack_damage(level + 1))], 12, Color("7ee08a"))
	column.add_child(damage)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	var active := Session.active_pet == id
	var activate := Brand.make_wood_button("Ativo ✓" if active else "Ativar", Vector2(100, 34), 14)
	activate.pressed.connect(_on_activate.bind(id))
	buttons.add_child(activate)
	var upgrade := Brand.make_wood_button("Melhorar · %d ouro" % Pets.upgrade_cost(level), Vector2(190, 34), 14)
	upgrade.disabled = Session.inventory.gold < Pets.upgrade_cost(level)
	upgrade.pressed.connect(_on_upgrade.bind(id))
	buttons.add_child(upgrade)
	column.add_child(buttons)
	return frame


func _on_activate(id: String) -> void:
	Session.set_active_pet("" if Session.active_pet == id else id)
	refresh()
	changed.emit()


func _on_upgrade(id: String) -> void:
	Session.upgrade_pet(id)
	refresh()
	changed.emit()
