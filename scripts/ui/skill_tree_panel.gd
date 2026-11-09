class_name SkillTreePanel
extends VBoxContainer

## Árvore de habilidades no layout clássico: à esquerda a caixa do nó escolhido com os botões + e -, no meio
## a árvore (a raiz leva a 4 ramos de 4 nós ligados por setas), à direita as caixas Mestre e Herói, e embaixo
## os pontos de habilidade, o custo e os botões Ok e Cancelar. Os + ficam pendentes até o Ok.

signal changed

const NODE := 44.0
const VIEW_SIZE := Vector2(400, 236)
const COLUMN_X := [32.0, 108.0, 180.0, 252.0, 324.0]
const ROW_Y := [30.0, 86.0, 142.0, 198.0]

var _hero := ""
var _pending := {}
var _selected := "root"
var _view: TreeView
var _preview: NodeIcon
var _master: NodeIcon
var _hero_node: NodeIcon
var _name_label: Label
var _detail_label: Label
var _plus: Button
var _minus: Button
var _points_value: Label
var _cost_value: Label
var _ok: Button
var _cancel: Button


## Desenho de um nó: moldura, o ícone na cor do atributo e o nível ("MAX" em vermelho no máximo).
static func draw_node(canvas: CanvasItem, rect: Rect2, entry: Dictionary, level: int, pending: int, unlocked: bool, selected: bool) -> void:
	var font := ThemeDB.fallback_font
	var base := SkillTree.color_of(entry)
	var tone := 1.0 if unlocked or level + pending > 0 else 0.35
	canvas.draw_rect(rect.grow(2.0), Color("e8c64a") if selected else Color("5a4122"))
	canvas.draw_rect(rect, Color("1a1510"))
	var center := rect.get_center() + Vector2(0, -3)
	canvas.draw_circle(center, rect.size.x * 0.34, Color(base.r * 0.45, base.g * 0.45, base.b * 0.45, tone))
	canvas.draw_arc(center, rect.size.x * 0.34, 0.0, TAU, 24, Color(base, tone), 2.5)
	var glyph := str(entry["name"]).substr(0, 1).to_upper()
	canvas.draw_string(font, Vector2(rect.position.x, center.y + 8), glyph, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, Color(1, 1, 1, tone))
	var maxed := level + pending >= SkillTree.MAX_LEVEL
	var label := "MAX" if maxed else "%d/%d" % [level + pending, SkillTree.MAX_LEVEL]
	var color := Color("ff5a4a") if maxed else (Color("7ee08a") if pending > 0 else Color("f4e9d8"))
	canvas.draw_string_outline(font, Vector2(rect.position.x, rect.end.y - 2), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, 4, Color("120a05"))
	canvas.draw_string(font, Vector2(rect.position.x, rect.end.y - 2), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, color)
	if not unlocked and level + pending == 0:
		canvas.draw_rect(rect, Color(0, 0, 0, 0.35))


## A árvore: a raiz, as setas e os 16 nós dos ramos, num quadro preto.
class TreeView extends Control:
	signal picked(id: String)
	var hero := ""
	var levels := {}
	var pending := {}
	var selected := ""

	func _init() -> void:
		custom_minimum_size = SkillTreePanel.VIEW_SIZE
		mouse_filter = Control.MOUSE_FILTER_STOP

	func node_rect(id: String) -> Rect2:
		var half := SkillTreePanel.NODE * 0.5
		if id == "root":
			return Rect2(Vector2(SkillTreePanel.COLUMN_X[0] - half, size.y * 0.5 - half - 6.0), Vector2.ONE * SkillTreePanel.NODE)
		var parts := id.trim_prefix("b").split("_")
		if parts.size() != 2:
			return Rect2()
		var row := int(parts[0])
		var tier := int(parts[1])
		return Rect2(Vector2(SkillTreePanel.COLUMN_X[tier] - half, SkillTreePanel.ROW_Y[row] - half - 6.0), Vector2.ONE * SkillTreePanel.NODE)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for entry in SkillTree.nodes(hero):
				if entry["branch"] >= 0 or entry["id"] == "root":
					if node_rect(entry["id"]).grow(4.0).has_point(event.position):
						picked.emit(entry["id"])
						return

	func _arrow(from: Vector2, to: Vector2) -> void:
		var color := Color("e8c64a")
		draw_line(from, to, color, 3.0)
		var direction := (to - from).normalized()
		var side := Vector2(-direction.y, direction.x)
		draw_colored_polygon(PackedVector2Array([to, to - direction * 9.0 + side * 6.0, to - direction * 9.0 - side * 6.0]), color)

	func shown_levels() -> Dictionary:
		var merged := levels.duplicate()
		for id in pending:
			merged[id] = int(merged.get(id, 0)) + int(pending[id])
		return merged

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("08060a"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("5a4122"), false, 3.0)
		if hero == "":
			return
		var root_rect := node_rect("root")
		var split_x := root_rect.end.x + 18.0
		draw_line(Vector2(root_rect.end.x, root_rect.get_center().y), Vector2(split_x, root_rect.get_center().y), Color("e8c64a"), 3.0)
		var top_y := node_rect("b0_1").get_center().y
		var bottom_y := node_rect("b3_1").get_center().y
		draw_line(Vector2(split_x, top_y), Vector2(split_x, bottom_y), Color("e8c64a"), 3.0)
		for row in SkillTree.BRANCHES:
			var first := node_rect("b%d_1" % row)
			_arrow(Vector2(split_x, first.get_center().y), Vector2(first.position.x - 2.0, first.get_center().y))
			for tier in range(1, SkillTree.TIERS):
				var from_rect := node_rect("b%d_%d" % [row, tier])
				var to_rect := node_rect("b%d_%d" % [row, tier + 1])
				_arrow(Vector2(from_rect.end.x + 2.0, from_rect.get_center().y), Vector2(to_rect.position.x - 2.0, to_rect.get_center().y))
		var shown := shown_levels()
		for entry in SkillTree.nodes(hero):
			if entry["branch"] < 0 and entry["id"] != "root":
				continue
			var id: String = entry["id"]
			SkillTreePanel.draw_node(self, node_rect(id), entry, int(levels.get(id, 0)), int(pending.get(id, 0)), SkillTree.unlocked(hero, id, shown), id == selected)


## Um nó solto (as caixas do nó escolhido, do Mestre e do Herói).
class NodeIcon extends Control:
	signal picked(id: String)
	var entry := {}
	var level := 0
	var pending := 0
	var unlocked := true
	var selected := false

	func _init(box := 64.0) -> void:
		custom_minimum_size = Vector2(box, box)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not entry.is_empty():
			picked.emit(str(entry["id"]))

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("08060a"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("5a4122"), false, 2.0)
		if entry.is_empty():
			return
		var side := size.x - 20.0
		SkillTreePanel.draw_node(self, Rect2(Vector2(10, 8), Vector2(side, side - 4.0)), entry, level, pending, unlocked, selected)


func _init() -> void:
	add_theme_constant_override("separation", 8)

	var middle := HBoxContainer.new()
	middle.add_theme_constant_override("separation", 12)
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(middle)

	# Esquerda: o nó escolhido, o + e o -.
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(116, 0)
	middle.add_child(left)
	_preview = NodeIcon.new(72.0)
	_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_preview)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	_plus = Brand.make_wood_button("+", Vector2(44, 40), 22)
	_plus.pressed.connect(_on_plus)
	buttons.add_child(_plus)
	_minus = Brand.make_wood_button("−", Vector2(44, 40), 22)
	_minus.pressed.connect(_on_minus)
	buttons.add_child(_minus)
	left.add_child(buttons)
	_name_label = Brand.make_label("", 14, Color("ffe9a8"))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.custom_minimum_size = Vector2(110, 0)
	left.add_child(_name_label)
	_detail_label = Brand.make_label("", 12, Color("b8c9a0"))
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.custom_minimum_size = Vector2(110, 0)
	left.add_child(_detail_label)

	# Meio: a árvore.
	_view = TreeView.new()
	_view.picked.connect(_select)
	middle.add_child(_view)

	# Direita: Mestre e Herói.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.custom_minimum_size = Vector2(100, 0)
	middle.add_child(right)
	right.add_child(_title_bar("Mestre"))
	_master = NodeIcon.new(72.0)
	_master.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_master.picked.connect(_select)
	right.add_child(_master)
	right.add_child(_title_bar("Herói"))
	_hero_node = NodeIcon.new(72.0)
	_hero_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero_node.picked.connect(_select)
	right.add_child(_hero_node)

	# Embaixo: pontos, custo, Ok e Cancelar.
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(bottom)
	bottom.add_child(_plate("Pontos de habilidade"))
	_points_value = _plate("0", 70.0)
	bottom.add_child(_points_value)
	bottom.add_child(_plate("Custo"))
	_cost_value = _plate("0", 56.0)
	bottom.add_child(_cost_value)
	_ok = Brand.make_wood_button("Ok", Vector2(96, 38), 16)
	_ok.pressed.connect(_on_ok)
	bottom.add_child(_ok)
	_cancel = Brand.make_wood_button("Cancelar", Vector2(110, 38), 16)
	_cancel.pressed.connect(_on_cancel)
	bottom.add_child(_cancel)


func _title_bar(text: String) -> Label:
	var label := Brand.make_label(text, 15, Color("ffe9a8"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var style := Brand.make_box(Color("3a2a1a"), Color("5a4122"), 2, 4)
	style.set_content_margin_all(4)
	label.add_theme_stylebox_override("normal", style)
	return label


func _plate(text: String, width := 0.0) -> Label:
	var label := Brand.make_label(text, 14, Color("ffe9a8"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var style := Brand.make_box(Color("2b1d12"), Color("5a4122"), 2, 4)
	style.set_content_margin_all(6)
	label.add_theme_stylebox_override("normal", style)
	label.custom_minimum_size = Vector2(width, 38)
	return label


# --- Dados -------------------------------------------------------------------------

func refresh(hero: String) -> void:
	if hero != _hero:
		_pending = {}
		_selected = "root"
	_hero = hero
	var saved: Dictionary = Session.tree_levels(hero)
	var shown := saved.duplicate()
	for id in _pending:
		shown[id] = int(shown.get(id, 0)) + int(_pending[id])
	_view.hero = hero
	_view.levels = saved
	_view.pending = _pending
	_view.selected = _selected
	_view.queue_redraw()
	_set_icon(_master, "master", saved, shown)
	_set_icon(_hero_node, "hero", saved, shown)
	_set_icon(_preview, _selected, saved, shown)
	var entry := SkillTree.node(hero, _selected)
	var level := int(shown.get(_selected, 0))
	_name_label.text = str(entry.get("name", ""))
	var detail := "Nível %d/%d" % [level, SkillTree.MAX_LEVEL]
	if not entry.is_empty():
		detail += "\n%s por nível" % SkillTree.bonus_text(entry)
		if not SkillTree.unlocked(hero, _selected, shown) and level == 0:
			detail += "\nBloqueado: " + _requirement_text(entry)
	_detail_label.text = detail
	var plan := Session.plan_tree(hero, _pending)
	var progress := Session.progress_for(hero)
	var left := int(progress["points"]) - int(plan["cost"])
	_points_value.text = str(left)
	var next_cost := SkillTree.cost(entry, level) if not entry.is_empty() else 0
	_cost_value.text = str(next_cost)
	var can_add: bool = not entry.is_empty() and level < SkillTree.MAX_LEVEL and SkillTree.unlocked(hero, _selected, shown) and next_cost <= left
	_plus.disabled = not can_add
	_minus.disabled = int(_pending.get(_selected, 0)) <= 0
	_ok.disabled = _pending.is_empty()
	_cancel.disabled = _pending.is_empty()


func _set_icon(icon: NodeIcon, id: String, saved: Dictionary, shown: Dictionary) -> void:
	icon.entry = SkillTree.node(_hero, id)
	icon.level = int(saved.get(id, 0))
	icon.pending = int(_pending.get(id, 0))
	icon.unlocked = SkillTree.unlocked(_hero, id, shown)
	icon.selected = id == _selected and icon != _preview
	icon.queue_redraw()


func _requirement_text(entry: Dictionary) -> String:
	if entry["id"] == "master":
		return "os 4 últimos nós dos ramos"
	if entry["id"] == "hero":
		return "Mestre no máximo"
	var previous := SkillTree.node(_hero, str(entry["requires"][0]))
	return str(previous.get("name", "nó anterior"))


func _select(id: String) -> void:
	_selected = id
	refresh(_hero)


func _on_plus() -> void:
	var trial := _pending.duplicate()
	trial[_selected] = int(trial.get(_selected, 0)) + 1
	var plan := Session.plan_tree(_hero, trial)
	if plan["ok"] and int(plan["cost"]) <= int(Session.progress_for(_hero)["points"]):
		_pending = trial
		Sound.play("coin")
	refresh(_hero)


func _on_minus() -> void:
	var trial := _pending.duplicate()
	trial[_selected] = int(trial.get(_selected, 0)) - 1
	if int(trial[_selected]) <= 0:
		trial.erase(_selected)
	if Session.plan_tree(_hero, trial)["ok"]:
		_pending = trial
	refresh(_hero)


func _on_ok() -> void:
	if Session.commit_tree(_hero, _pending):
		Sound.play("level")
	_pending = {}
	refresh(_hero)
	changed.emit()


func _on_cancel() -> void:
	_pending = {}
	refresh(_hero)
