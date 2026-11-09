class_name BestiaryPanel
extends VBoxContainer

## Página "Catálogo" do menu do castelo: cada espécie de monstro com os atributos-base, quantos já
## foram derrotados e as conquistas (um título a cada marca de abates, ver Achievements).


## Os 6 medalhões de conquista de uma espécie: dourado quando conquistado.
class Medals extends Control:
	var earned := 0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in Achievements.TIERS.size():
			var center := Vector2(13.0 + i * 28.0, 13.0)
			draw_circle(center, 12.0, Color("120a05"))
			draw_circle(center, 10.0, Brand.GOLD if i < earned else Color("3a2a1a"))
			if i < earned:
				draw_arc(center, 6.0, 0.4, 2.6, 8, Color("fff2a0"), 2.0)


## O retrato do monstro: o próprio inimigo (parado) numa moldura; vira silhueta até o primeiro abate.
class Portrait extends Control:
	var known := true
	var _enemy: Enemy

	func _init(kind := "slime") -> void:
		custom_minimum_size = Vector2(76, 76)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		_enemy = Enemy.new()
		_enemy.setup(kind, 0.0)
		var fit := clampf(26.0 / maxf(_enemy.radius, 1.0), 0.6, 1.8)
		_enemy.scale = Vector2(fit, fit)
		_enemy.position = Vector2(38.0, 42.0)
		add_child(_enemy)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("120a05"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("3a2a1a"), false, 2.0)

	func set_known(value: bool) -> void:
		known = value
		_enemy.modulate = Color.WHITE if value else Color(0.0, 0.0, 0.0, 0.85)


var _rows := {}
var _summary: Label


func _init() -> void:
	add_theme_constant_override("separation", 8)
	add_child(Ribbon.new("CATÁLOGO DOS MONSTROS", 40))
	_summary = Brand.make_label("", 14, Color("b8c9a0"))
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	add_child(scroll)
	for kind in EnemyTypes.DATA:
		list.add_child(_make_row(kind))


func _make_row(kind: String) -> Control:
	var data: Dictionary = EnemyTypes.DATA[kind]
	var frame := PanelContainer.new()
	var style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 6)
	style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	frame.add_child(row)
	var portrait := Portrait.new(kind)
	row.add_child(portrait)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	var title := Brand.make_label(data["name"], 18, Color("ffe9a8"))
	column.add_child(title)
	var trait_label := Brand.make_label(data["trait"], 12, Color("b8c9a0"))
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(trait_label)
	var stats := Brand.make_label(_stats_text(data), 13, Brand.PARCHMENT)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats)
	var kills := Brand.make_label("", 14, Brand.GOLD)
	column.add_child(kills)
	var bar := MedievalBar.new(14.0, 0.0)
	bar.show_ticks = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.fill_top = Color("e8c64a")
	bar.fill_bottom = Color("a8861a")
	column.add_child(bar)
	var medals := Medals.new()
	column.add_child(medals)
	_rows[kind] = {"portrait": portrait, "kills": kills, "bar": bar, "medals": medals, "title": title}
	return frame


## Atributos-base do monstro no começo da fase (eles crescem com a fase e com o tempo).
func _stats_text(data: Dictionary) -> String:
	var parts: Array = [
		"Vida %d" % int(data["health"]), "Dano %d" % int(data["damage"]),
		"Veloc. %d" % int(data["speed"]), "XP %d" % int(data["xp"]),
	]
	if float(data.get("dodge", 0.0)) > 0.0:
		parts.append("Esquiva %d%%" % int(round(float(data["dodge"]) * 100.0)))
	if float(data.get("block", 0.0)) > 0.0:
		parts.append("Bloqueio %d%%" % int(round(float(data["block"]) * 100.0)))
	return " · ".join(parts)


func refresh() -> void:
	var total := 0
	var titles := 0
	for kind in _rows:
		var kills := Session.kills_of(kind)
		var tier := Achievements.tier_for(kills)
		var goal := Achievements.next_goal(kills)
		var row: Dictionary = _rows[kind]
		total += kills
		titles += tier
		row["portrait"].set_known(kills > 0)

		row["medals"].earned = tier
		row["medals"].queue_redraw()
		var best := ("  ·  " + Achievements.title_for(kind, tier - 1)) if tier > 0 else ""
		row["kills"].text = "Derrotados: %d%s" % [kills, best]
		var bar: MedievalBar = row["bar"]
		if goal > 0:
			bar.max_value = goal
			bar.value = kills
			bar.label_text = "%d / %d abates para %s" % [kills, goal, Achievements.title_for(kind, tier)]
		else:
			bar.max_value = 1.0
			bar.value = 1.0
			bar.label_text = "Todas as conquistas!"
	_summary.text = "%d monstros derrotados · %d conquistas" % [total, titles]
