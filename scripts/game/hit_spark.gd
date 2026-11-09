class_name HitSpark
extends Node2D

## Faísca de impacto no ponto do golpe: raios curtos que abrem e somem. O crítico é maior e dourado,
## com um anel; o bloqueio solta fagulhas cinza; a queimadura, brasas pequenas.

const LIFETIME := 0.28

var kind := "hit"
var _age := 0.0
var _rays: Array = []
var _color := Color.WHITE
var _length := 16.0


func setup(at: Vector2, spark_kind: String) -> void:
	global_position = at
	kind = spark_kind
	add_to_group("sparks")
	z_index = 15
	var count := 7
	match kind:
		"crit":
			_color = Color("ffd93a")
			_length = 34.0
			count = 12
		"block":
			_color = Color("c3cad6")
			_length = 20.0
			count = 6
		"dot":
			_color = Color("ff8a3a")
			_length = 10.0
			count = 4
		_:
			_color = Color("fff3c4")
			_length = 18.0
	var base := randf() * TAU
	for i in count:
		var angle := base + TAU * float(i) / float(count) + randf_range(-0.2, 0.2)
		_rays.append({"angle": angle, "length": _length * randf_range(0.6, 1.1)})


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	var fade := 1.0 - t
	var reach := ease(t, 0.35)
	for ray in _rays:
		var direction := Vector2.from_angle(ray["angle"])
		var start := direction * float(ray["length"]) * (0.25 + reach * 0.9)
		var end := direction * float(ray["length"]) * (0.7 + reach * 1.2)
		draw_line(start, end, Color(_color, fade), 3.0 if kind == "crit" else 2.0)
	draw_circle(Vector2.ZERO, (1.0 - t) * (11.0 if kind == "crit" else 6.0), Color(1, 1, 1, fade))
	if kind == "crit":
		draw_arc(Vector2.ZERO, 8.0 + reach * 30.0, 0.0, TAU, 24, Color(_color, fade * 0.8), 3.0)
	elif kind == "block":
		draw_arc(Vector2.ZERO, 6.0 + reach * 16.0, -PI * 0.8, -PI * 0.2, 10, Color(_color, fade), 3.0)
