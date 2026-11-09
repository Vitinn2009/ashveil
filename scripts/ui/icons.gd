class_name Icons
extends RefCounted

## Ícones desenhados por código, sem imagens: armas, armaduras, poções, comidas
## e símbolos de interface. Cada um cabe no retângulo dado.

const OUTLINE := Color("120a05")


## Desenha o ícone `kind` centralizado em `rect`, na cor `color`.
static func draw(canvas: CanvasItem, kind: String, rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) * 0.5
	match kind:
		"weapon":
			_sword(canvas, center, s, color)
		"armor":
			_armor(canvas, center, s, color)
		"boots":
			_boots(canvas, center, s, color)
		"ring":
			_ring(canvas, center, s, color)
		"helmet":
			_helmet(canvas, center, s, color)
		"offhand":
			_shield(canvas, center, s, color)
		"gloves":
			_gloves(canvas, center, s, color)
		"cloak":
			_cloak(canvas, center, s, color)
		"mask":
			_mask(canvas, center, s, color)
		"necklace":
			_necklace(canvas, center, s, color)
		"potion":
			_potion(canvas, center, s, color)
		"bread":
			_bread(canvas, center, s, color)
		"meat":
			_meat(canvas, center, s, color)
		"stew":
			_stew(canvas, center, s, color)
		"coin":
			_coin(canvas, center, s, color)
		"heart":
			_heart(canvas, center, s, color)
		"bolt":
			_bolt(canvas, center, s, color)
		"lock":
			_lock(canvas, center, s, color)
		"star":
			_star(canvas, center, s, color)


static func _p(center: Vector2, s: float, x: float, y: float) -> Vector2:
	return center + Vector2(x, y) * s


static func _poly(canvas: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= points.size()
	var outline := PackedVector2Array()
	for point in points:
		outline.append(center + (point - center) * 1.14)
	canvas.draw_colored_polygon(outline, OUTLINE)
	canvas.draw_colored_polygon(points, color)


static func _sword(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_line(_p(c, s, -0.5, 0.5), _p(c, s, 0.78, -0.78), OUTLINE, s * 0.36)
	canvas.draw_line(_p(c, s, -0.5, 0.5), _p(c, s, 0.78, -0.78), color, s * 0.2)
	canvas.draw_line(_p(c, s, -0.62, 0.12), _p(c, s, -0.12, 0.62), OUTLINE, s * 0.32)
	canvas.draw_line(_p(c, s, -0.62, 0.12), _p(c, s, -0.12, 0.62), Brand.BRASS, s * 0.18)
	canvas.draw_line(_p(c, s, -0.4, 0.4), _p(c, s, -0.8, 0.8), Color("7a4a24"), s * 0.2)
	canvas.draw_circle(_p(c, s, -0.84, 0.84), s * 0.15, Brand.BRASS)


static func _armor(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, -0.85, -0.55), _p(c, s, -0.4, -0.8), _p(c, s, -0.22, -0.5), _p(c, s, 0.22, -0.5),
		_p(c, s, 0.4, -0.8), _p(c, s, 0.85, -0.55), _p(c, s, 0.68, 0.12), _p(c, s, 0.46, 0.82),
		_p(c, s, 0.0, 0.92), _p(c, s, -0.46, 0.82), _p(c, s, -0.68, 0.12)]), color)
	canvas.draw_line(_p(c, s, 0, -0.45), _p(c, s, 0, 0.8), color.darkened(0.35), s * 0.1)
	canvas.draw_line(_p(c, s, -0.45, 0.05), _p(c, s, 0.45, 0.05), color.darkened(0.35), s * 0.1)


static func _boots(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, -0.45, -0.85), _p(c, s, 0.15, -0.85), _p(c, s, 0.15, 0.05), _p(c, s, 0.85, 0.3),
		_p(c, s, 0.85, 0.85), _p(c, s, -0.45, 0.85)]), color)
	canvas.draw_line(_p(c, s, -0.45, 0.55), _p(c, s, 0.85, 0.55), color.darkened(0.4), s * 0.1)
	canvas.draw_line(_p(c, s, -0.45, -0.55), _p(c, s, 0.15, -0.55), Brand.BRASS, s * 0.12)


static func _ring(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_arc(_p(c, s, 0, 0.2), s * 0.55, 0.0, TAU, 28, OUTLINE, s * 0.36)
	canvas.draw_arc(_p(c, s, 0, 0.2), s * 0.55, 0.0, TAU, 28, Brand.BRASS, s * 0.2)
	_poly(canvas, PackedVector2Array([
		_p(c, s, 0, -0.85), _p(c, s, 0.3, -0.5), _p(c, s, 0, -0.2), _p(c, s, -0.3, -0.5)]), color)
	canvas.draw_circle(_p(c, s, -0.07, -0.55), s * 0.06, Color(1, 1, 1, 0.8))


static func _helmet(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, -0.8, 0.7), _p(c, s, -0.8, -0.1), _p(c, s, -0.45, -0.7), _p(c, s, 0.0, -0.9),
		_p(c, s, 0.45, -0.7), _p(c, s, 0.8, -0.1), _p(c, s, 0.8, 0.7), _p(c, s, 0.35, 0.7),
		_p(c, s, 0.35, 0.1), _p(c, s, -0.35, 0.1), _p(c, s, -0.35, 0.7)]), color)
	canvas.draw_line(_p(c, s, 0, -0.9), _p(c, s, 0, 0.1), color.darkened(0.35), s * 0.1)
	canvas.draw_line(_p(c, s, -0.8, 0.1), _p(c, s, 0.8, 0.1), Brand.BRASS, s * 0.1)


static func _shield(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, -0.75, -0.8), _p(c, s, 0.75, -0.8), _p(c, s, 0.75, 0.1), _p(c, s, 0.4, 0.62),
		_p(c, s, 0.0, 0.95), _p(c, s, -0.4, 0.62), _p(c, s, -0.75, 0.1)]), color)
	canvas.draw_line(_p(c, s, 0, -0.75), _p(c, s, 0, 0.85), color.darkened(0.35), s * 0.1)
	canvas.draw_line(_p(c, s, -0.7, -0.15), _p(c, s, 0.7, -0.15), color.darkened(0.35), s * 0.1)
	canvas.draw_circle(_p(c, s, 0, -0.15), s * 0.16, Brand.BRASS)


static func _gloves(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, -0.6, 0.9), _p(c, s, -0.6, 0.0), _p(c, s, -0.75, -0.45), _p(c, s, -0.45, -0.6),
		_p(c, s, -0.3, -0.85), _p(c, s, -0.05, -0.9), _p(c, s, 0.2, -0.8), _p(c, s, 0.45, -0.5),
		_p(c, s, 0.7, -0.1), _p(c, s, 0.55, 0.9)]), color)
	canvas.draw_line(_p(c, s, -0.6, 0.55), _p(c, s, 0.55, 0.55), Brand.BRASS, s * 0.14)


static func _cloak(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, -0.45, -0.85), _p(c, s, 0.45, -0.85), _p(c, s, 0.9, 0.85), _p(c, s, 0.3, 0.7),
		_p(c, s, 0.0, 0.9), _p(c, s, -0.3, 0.7), _p(c, s, -0.9, 0.85)]), color)
	canvas.draw_line(_p(c, s, -0.45, -0.7), _p(c, s, 0.45, -0.7), Brand.BRASS, s * 0.14)
	canvas.draw_circle(_p(c, s, 0, -0.7), s * 0.14, Brand.RUBY)


static func _necklace(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_arc(_p(c, s, 0, -0.3), s * 0.75, 0.15, PI - 0.15, 20, OUTLINE, s * 0.3)
	canvas.draw_arc(_p(c, s, 0, -0.3), s * 0.75, 0.15, PI - 0.15, 20, Brand.BRASS, s * 0.14)
	_poly(canvas, PackedVector2Array([
		_p(c, s, 0, 0.35), _p(c, s, 0.3, 0.7), _p(c, s, 0, 1.0), _p(c, s, -0.3, 0.7)]), color)
	canvas.draw_circle(_p(c, s, -0.07, 0.65), s * 0.06, Color(1, 1, 1, 0.8))


static func _potion(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_circle(_p(c, s, 0, 0.3), s * 0.66, OUTLINE)
	canvas.draw_rect(Rect2(_p(c, s, -0.2, -0.75), Vector2(s * 0.4, s * 0.6)), OUTLINE)
	canvas.draw_circle(_p(c, s, 0, 0.3), s * 0.55, color)
	canvas.draw_rect(Rect2(_p(c, s, -0.12, -0.7), Vector2(s * 0.24, s * 0.5)), Color("d8e8f0"))
	canvas.draw_rect(Rect2(_p(c, s, -0.22, -0.95), Vector2(s * 0.44, s * 0.24)), Color("a8744a"))
	canvas.draw_circle(_p(c, s, -0.22, 0.12), s * 0.14, Color(1, 1, 1, 0.55))


static func _bread(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var loaf := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		loaf.append(_p(c, s, cos(angle) * 0.9, sin(angle) * 0.55 + 0.1))
	_poly(canvas, loaf, color)
	for x in [-0.4, 0.0, 0.4]:
		canvas.draw_line(_p(c, s, x - 0.12, -0.12), _p(c, s, x + 0.12, 0.32), color.darkened(0.35), s * 0.1)


static func _meat(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_line(_p(c, s, 0.1, 0.1), _p(c, s, 0.7, 0.7), OUTLINE, s * 0.3)
	canvas.draw_line(_p(c, s, 0.1, 0.1), _p(c, s, 0.7, 0.7), Color("efe2c8"), s * 0.16)
	canvas.draw_circle(_p(c, s, 0.78, 0.62), s * 0.14, Color("efe2c8"))
	canvas.draw_circle(_p(c, s, 0.62, 0.8), s * 0.14, Color("efe2c8"))
	canvas.draw_circle(_p(c, s, -0.15, -0.2), s * 0.66, OUTLINE)
	canvas.draw_circle(_p(c, s, -0.15, -0.2), s * 0.55, color)
	canvas.draw_circle(_p(c, s, -0.32, -0.38), s * 0.16, color.lightened(0.35))


static func _stew(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var bowl := PackedVector2Array()
	for i in 13:
		var angle := PI * i / 12.0
		bowl.append(_p(c, s, cos(angle) * 0.85, sin(angle) * 0.6 + 0.05))
	_poly(canvas, bowl, Color("8a5a34"))
	canvas.draw_rect(Rect2(_p(c, s, -0.85, -0.02), Vector2(s * 1.7, s * 0.14)), color)
	for x in [-0.35, 0.05, 0.45]:
		canvas.draw_arc(_p(c, s, x, -0.4), s * 0.16, -2.2, 0.6, 8, Color(1, 1, 1, 0.75), s * 0.08)


static func _coin(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_circle(c, s * 0.9, OUTLINE)
	canvas.draw_circle(c, s * 0.78, Brand.BRASS_DARK)
	canvas.draw_circle(c, s * 0.66, color)
	canvas.draw_arc(c, s * 0.46, 0.0, TAU, 20, Brand.BRASS_DARK, s * 0.1)
	canvas.draw_arc(c, s * 0.66, -2.5, -1.0, 8, Color(1, 1, 1, 0.55), s * 0.08)


static func _heart(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_circle(_p(c, s, -0.38, -0.2), s * 0.52, OUTLINE)
	canvas.draw_circle(_p(c, s, 0.38, -0.2), s * 0.52, OUTLINE)
	canvas.draw_colored_polygon(PackedVector2Array([
		_p(c, s, -0.95, -0.05), _p(c, s, 0.95, -0.05), _p(c, s, 0, 0.98)]), OUTLINE)
	canvas.draw_circle(_p(c, s, -0.38, -0.2), s * 0.42, color)
	canvas.draw_circle(_p(c, s, 0.38, -0.2), s * 0.42, color)
	canvas.draw_colored_polygon(PackedVector2Array([
		_p(c, s, -0.82, -0.04), _p(c, s, 0.82, -0.04), _p(c, s, 0, 0.85)]), color)
	canvas.draw_circle(_p(c, s, -0.5, -0.38), s * 0.12, Color(1, 1, 1, 0.6))


static func _bolt(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, 0.2, -0.95), _p(c, s, -0.55, 0.12), _p(c, s, -0.05, 0.12), _p(c, s, -0.25, 0.95),
		_p(c, s, 0.6, -0.2), _p(c, s, 0.08, -0.2)]), color)


static func _lock(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_arc(_p(c, s, 0, -0.2), s * 0.42, PI, TAU, 14, OUTLINE, s * 0.34)
	canvas.draw_arc(_p(c, s, 0, -0.2), s * 0.42, PI, TAU, 14, color.darkened(0.2), s * 0.18)
	canvas.draw_rect(Rect2(_p(c, s, -0.62, -0.2), Vector2(s * 1.24, s * 1.0)), OUTLINE)
	canvas.draw_rect(Rect2(_p(c, s, -0.52, -0.1), Vector2(s * 1.04, s * 0.8)), color)
	canvas.draw_circle(_p(c, s, 0, 0.25), s * 0.12, OUTLINE)
	canvas.draw_rect(Rect2(_p(c, s, -0.04, 0.25), Vector2(s * 0.08, s * 0.3)), OUTLINE)


static func _star(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + TAU * i / 10.0
		var length := 0.95 if i % 2 == 0 else 0.4
		points.append(_p(c, s, cos(angle) * length, sin(angle) * length))
	_poly(canvas, points, color)


static func _mask(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(canvas, PackedVector2Array([
		_p(c, s, -0.9, -0.3), _p(c, s, -0.5, -0.5), _p(c, s, 0.0, -0.35), _p(c, s, 0.5, -0.5),
		_p(c, s, 0.9, -0.3), _p(c, s, 0.7, 0.35), _p(c, s, 0.25, 0.3), _p(c, s, 0.0, 0.1),
		_p(c, s, -0.25, 0.3), _p(c, s, -0.7, 0.35)]), color)
	canvas.draw_circle(_p(c, s, -0.45, -0.05), s * 0.17, OUTLINE)
	canvas.draw_circle(_p(c, s, 0.45, -0.05), s * 0.17, OUTLINE)
