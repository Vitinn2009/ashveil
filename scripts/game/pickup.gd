class_name Pickup
extends Node2D

## Item no chão: XP, ouro, poção ou equipamento. Salta ao cair, balança parado, brilha na cor
## da raridade (com um feixe de luz nos raros), é atraído pelo herói quando ele chega perto e
## encolhe até ele ao ser coletado. Equipamento some depois de um tempo, piscando antes.

const MAGNET_SPEED := 460.0
const COLLECT_DISTANCE := 18.0
## Enquanto salta, o drop ainda não é atraído.
const POP_TIME := 0.45
const GRAVITY := 900.0
const ITEM_LIFETIME := 60.0
const BLINK_TIME := 6.0
const COLLECT_SECONDS := 0.14

var kind := "xp"
var payload: Variant = 1
var target: Player

var _collected := false
var _age := 0.0
var _slide := Vector2.ZERO
var _height := 0.0
var _climb := 0.0
var _bounces := 0
var _phase := randf() * TAU
var _shadow: PickupLayer
var _beam: PickupLayer
var _art: PickupLayer


## Camada desenhada de um drop: sombra, feixe de luz ou o objeto.
class PickupLayer extends Node2D:
	var pickup: Pickup
	var part := "art"

	func _draw() -> void:
		pickup.draw_part(self, part)


func _ready() -> void:
	# Os drops ficam sempre visíveis, mesmo atrás de uma árvore.
	z_index = 1
	add_to_group("pickups")
	_shadow = _make_layer("shadow")
	if kind == "item" and payload is Item and payload.rarity >= 1:
		_beam = _make_layer("beam")
	_art = _make_layer("art")
	_art.position.y = -6.0
	if kind == "item":
		_art.scale = Vector2(1.15, 1.15)


func _make_layer(part: String) -> PickupLayer:
	var layer := PickupLayer.new()
	layer.pickup = self
	layer.part = part
	add_child(layer)
	return layer


## Dá o impulso do salto: sai para o lado e para cima, cai e quica uma vez.
func pop(direction := Vector2.ZERO) -> void:
	var dir := direction if direction != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
	_slide = dir.normalized() * randf_range(50.0, 110.0)
	_climb = randf_range(190.0, 260.0)


func _physics_process(delta: float) -> void:
	if _collected or target == null:
		return
	_age += delta
	_animate(delta)
	if kind == "item" and _age > ITEM_LIFETIME:
		queue_free()
		return
	if kind == "item" and payload is Item and not Session.wants_item(payload):
		modulate.a = 0.4
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if _age >= POP_TIME and distance <= target.pickup_radius:
		global_position += offset / max(distance, 0.001) * MAGNET_SPEED * delta
	if _age >= POP_TIME * 0.5 and distance <= COLLECT_DISTANCE:
		_collect()


func _animate(delta: float) -> void:
	# Salto: parábola com um quique amortecido.
	if _climb != 0.0 or _height > 0.0:
		_climb -= GRAVITY * delta
		_height += _climb * delta
		global_position += _slide * delta
		_slide = _slide.move_toward(Vector2.ZERO, 220.0 * delta)
		if _height <= 0.0:
			_height = 0.0
			if _bounces == 0:
				_bounces = 1
				_climb = absf(_climb) * 0.38
			else:
				_climb = 0.0
	var bob := sin(_age * 4.0 + _phase) * 2.0 if _height <= 0.0 else 0.0
	_art.position.y = -6.0 - _height + bob
	_shadow.scale = Vector2.ONE * clampf(1.0 - _height / 120.0, 0.5, 1.0)
	match kind:
		"gold":
			# Moeda girando.
			_art.scale.x = 0.25 + 0.75 * absf(cos(_age * 5.0 + _phase))
		"xp":
			var pulse := 1.0 + 0.12 * sin(_age * 6.0 + _phase)
			_art.scale = Vector2(pulse, pulse)
		"item":
			if _beam:
				_beam.modulate.a = 0.55 + 0.45 * sin(_age * 3.0 + _phase)
	# Pisca nos últimos segundos antes de sumir.
	if kind == "item" and _age > ITEM_LIFETIME - BLINK_TIME:
		visible = int(_age * 8.0) % 2 == 0


func is_collected() -> bool:
	return _collected


## Coleta na hora, sem esperar o herói chegar (fim da partida).
func collect_now() -> void:
	if _collected:
		return
	_collected = true
	EventBus.pickup_collected.emit(kind, payload)
	queue_free()


func _collect() -> void:
	_collected = true
	EventBus.pickup_collected.emit(kind, payload)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target.global_position, COLLECT_SECONDS)
	tween.tween_property(self, "scale", Vector2.ZERO, COLLECT_SECONDS)
	tween.chain().tween_callback(queue_free)


## Desenha uma parte do drop em `canvas` (a camada pede, para cada quadro de redesenho).
func draw_part(canvas: CanvasItem, part: String) -> void:
	match part:
		"shadow":
			canvas.draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
			canvas.draw_circle(Vector2.ZERO, 9.0 if kind != "item" else 12.0, Color(0, 0, 0, 0.3))
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"beam":
			_draw_beam(canvas)
		_:
			_draw_art(canvas)


func _draw_beam(canvas: CanvasItem) -> void:
	var color: Color = payload.color()
	var rarity: int = payload.rarity
	var width := 5.0 + rarity * 1.5
	var height := 44.0 + rarity * 14.0
	var points := PackedVector2Array([
		Vector2(-width, 0), Vector2(width, 0), Vector2(width * 0.35, -height), Vector2(-width * 0.35, -height)])
	var colors := PackedColorArray([
		Color(color, 0.42), Color(color, 0.42), Color(color, 0.0), Color(color, 0.0)])
	canvas.draw_polygon(points, colors)


func _draw_art(canvas: CanvasItem) -> void:
	match kind:
		"gold":
			canvas.draw_circle(Vector2.ZERO, 7.0, Brand.NIGHT)
			canvas.draw_circle(Vector2.ZERO, 5.5, Brand.GOLD)
			canvas.draw_arc(Vector2.ZERO, 3.0, 0.4, 2.6, 8, Color("fff2a0"), 1.5)
		"potion":
			canvas.draw_circle(Vector2(0, 3), 8.5, Brand.NIGHT)
			canvas.draw_circle(Vector2(0, 3), 7.0, Color("e0452d"))
			canvas.draw_rect(Rect2(-4, -10, 8, 8), Brand.NIGHT)
			canvas.draw_rect(Rect2(-2.5, -8.5, 5, 6), Brand.PARCHMENT)
		"stone":
			var rock := PackedVector2Array([Vector2(-7, 4), Vector2(-5, -5), Vector2(2, -7), Vector2(7, -1), Vector2(5, 5)])
			var rim := PackedVector2Array()
			for point in rock:
				rim.append(point * 1.2)
			canvas.draw_colored_polygon(rim, Brand.NIGHT)
			canvas.draw_colored_polygon(rock, Color("9aa0a8"))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4, -3), Vector2(1, -5), Vector2(0, -1)]), Color("d0d6dc"))
		"moonstone":
			canvas.draw_circle(Vector2.ZERO, 12.0, Color("8ec6ff", 0.22))
			canvas.draw_circle(Vector2.ZERO, 8.5, Brand.NIGHT)
			canvas.draw_circle(Vector2.ZERO, 7.0, Color("b9d8ff"))
			canvas.draw_circle(Vector2(2.5, -1.0), 5.5, Color("3a5aa0"))
			canvas.draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, Color("e8f4ff"), 1.2)
		"rune":
			var rune_color: Color = Runes.DATA[str(payload)]["color"]
			canvas.draw_circle(Vector2.ZERO, 13.0, Color(rune_color, 0.25))
			var gem := PackedVector2Array([Vector2(0, -9), Vector2(7, -3), Vector2(5, 7), Vector2(-5, 7), Vector2(-7, -3)])
			var gem_rim := PackedVector2Array()
			for point in gem:
				gem_rim.append(point * 1.2)
			canvas.draw_colored_polygon(gem_rim, Brand.NIGHT)
			canvas.draw_colored_polygon(gem, rune_color.darkened(0.3))
			canvas.draw_line(Vector2(-3, 1), Vector2(0, -5), rune_color.lightened(0.6), 2.0)
			canvas.draw_line(Vector2(0, -5), Vector2(3, 1), rune_color.lightened(0.6), 2.0)
			canvas.draw_line(Vector2(0, -1), Vector2(0, 5), rune_color.lightened(0.6), 2.0)
		"key":
			canvas.draw_circle(Vector2(-4, 0), 6.5, Brand.NIGHT)
			canvas.draw_circle(Vector2(-4, 0), 5.0, Color("ffd24a"))
			canvas.draw_circle(Vector2(-4, 0), 2.0, Brand.NIGHT)
			canvas.draw_rect(Rect2(0, -2.5, 11, 5), Brand.NIGHT)
			canvas.draw_rect(Rect2(0, -1.5, 10, 3), Color("ffd24a"))
			canvas.draw_rect(Rect2(7, 1, 2.5, 4), Color("ffd24a"))
		"scroll":
			canvas.draw_rect(Rect2(-8, -6, 16, 12), Brand.NIGHT)
			canvas.draw_rect(Rect2(-6.5, -4.5, 13, 9), Brand.PARCHMENT)
			canvas.draw_circle(Vector2(-8, 0), 3.5, Color("c9a050"))
			canvas.draw_circle(Vector2(8, 0), 3.5, Color("c9a050"))
			canvas.draw_circle(Vector2.ZERO, 2.5, Color("b36bff"))
		"item":
			var item_color: Color = payload.color()
			canvas.draw_circle(Vector2.ZERO, 15.0, Color(item_color, 0.22))
			canvas.draw_circle(Vector2.ZERO, 11.5, Brand.NIGHT)
			canvas.draw_circle(Vector2.ZERO, 10.0, Color(item_color.darkened(0.55), 1.0))
			Icons.draw(canvas, payload.slot, Rect2(-9, -9, 18, 18), item_color.lightened(0.2))
			canvas.draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, item_color, 1.5)
		_:
			var diamond := PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
			canvas.draw_colored_polygon(diamond, Color("7bd389"))
