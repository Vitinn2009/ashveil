class_name ChoiceStrip
extends PanelContainer

## Escolha rápida de melhoria, sem pausar o jogo. Aparece no alto da tela com três cartas e uma
## barra de tempo; enquanto está aberta o jogo roda em câmera lenta. Quem toca numa carta (ou aperta
## 5, 6 ou 7) escolhe; quem não escolhe leva a sugestão (marcada com uma estrela) quando o tempo acaba.

signal chosen(option: Dictionary)

const SECONDS := 7.0
const KEYS := ["5", "6", "7"]

var _options: Array = []
var _left := 0.0
var _recommended := 0
var _row: HBoxContainer
var _bar: ProgressBar
var _title: Label


func _init() -> void:
	var style := Brand.make_box(Color(Brand.WOOD, 0.94), Brand.BRASS, 3, 8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_title = Brand.make_label("Nova melhoria! Escolha uma (ou deixe a sugestão)", 17, Color("ffe9a8"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	column.add_child(_row)
	_bar = Brand.make_bar(Brand.BRASS, 8.0)
	_bar.max_value = SECONDS
	column.add_child(_bar)
	hide()


func is_open() -> bool:
	return visible


func options() -> Array:
	return _options


func recommended_index() -> int:
	return _recommended


func open(new_options: Array, recommended := 0) -> void:
	_options = new_options
	_recommended = clampi(recommended, 0, maxi(new_options.size() - 1, 0))
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for i in _options.size():
		var option: Dictionary = _options[i]
		var star := "(sugestão) " if i == _recommended else ""
		var button := Brand.make_wood_button("%s[%s] %s\n%s" % [star, KEYS[i], option["name"], option["desc"]], Vector2(200, 72), 14)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(pick.bind(i))
		_row.add_child(button)
	_left = SECONDS
	_bar.value = _left
	show()


func pick(index: int) -> void:
	if not visible or index < 0 or index >= _options.size():
		return
	hide()
	chosen.emit(_options[index])


func _process(delta: float) -> void:
	if not visible:
		return
	# O jogo está em câmera lenta: conta o tempo real, não o do jogo.
	_left -= delta / maxf(Engine.time_scale, 0.05)
	_bar.value = maxf(_left, 0.0)
	if _left <= 0.0:
		pick(_recommended)
