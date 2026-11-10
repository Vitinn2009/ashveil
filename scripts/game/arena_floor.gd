class_name ArenaFloor
extends Node2D

## O cenário da Arena PvP: um coliseu visto de cima. Piso de areia com marcas de rastelo e um emblema no
## centro, muro de pedra com colunas, tochas e dois portões, e as arquibancadas em volta, cheias de gente.
## Tudo fica desenhado uma vez só (as tochas piscam num nó à parte).

const SAND := Color("d8bf86")
const SAND_DARK := Color("b99d62")
const STONE := Color("8d7e68")
const STONE_DARK := Color("5e5142")
const STONE_LIGHT := Color("b3a48c")
const CROWD_COLORS := [Color("c0392b"), Color("2f6fd0"), Color("f2b705"), Color("3e8f5a"), Color("f4e9d8"), Color("8a5fc9"), Color("e67e22")]

## Raio do piso de luta (o muro começa logo depois).
var radius := 640.0
var _crowd: Array = []
var _torch_spots: Array = []


func _ready() -> void:
	z_index = -100
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260
	for tier in 4:
		var inner := radius + 96.0 + tier * 72.0
		var count := 120 + tier * 60
		for i in count:
			var angle := rng.randf() * TAU
			var distance := inner + rng.randf_range(10.0, 58.0)
			_crowd.append([Vector2.from_angle(angle) * distance, CROWD_COLORS[rng.randi() % CROWD_COLORS.size()], rng.randf_range(5.5, 8.0)])
	for i in 24:
		_torch_spots.append(Vector2.from_angle(TAU * (i + 0.5) / 24.0) * (radius + 14.0))
	var torches := Torches.new()
	torches.spots = _torch_spots
	add_child(torches)
	queue_redraw()


func _draw() -> void:
	# Fora do estádio: pedra escura.
	draw_rect(Rect2(-3200, -3200, 6400, 6400), Color("1c1620"))
	# Arquibancadas: degraus de pedra em anéis, cada um mais alto e escuro que o anterior.
	for tier in 4:
		var inner := radius + 80.0 + tier * 72.0
		var band := STONE.darkened(0.12 * tier)
		draw_arc(Vector2.ZERO, inner + 36.0, 0.0, TAU, 180, band, 72.0)
		draw_arc(Vector2.ZERO, inner + 2.0, 0.0, TAU, 180, STONE_LIGHT.darkened(0.15 * tier), 4.0)
	for person in _crowd:
		var spot: Vector2 = person[0]
		draw_circle(spot, person[2], Color("1a1218"))
		draw_circle(spot, person[2] - 1.5, person[1])
		draw_circle(spot + Vector2(0, -person[2] * 0.7), person[2] * 0.45, Color("e8c9a0"))
	# Muro de pedra em volta do piso.
	draw_arc(Vector2.ZERO, radius + 40.0, 0.0, TAU, 180, STONE_DARK, 80.0)
	draw_arc(Vector2.ZERO, radius + 40.0, 0.0, TAU, 180, STONE, 64.0)
	draw_arc(Vector2.ZERO, radius + 12.0, 0.0, TAU, 180, STONE_LIGHT, 5.0)
	draw_arc(Vector2.ZERO, radius + 76.0, 0.0, TAU, 180, STONE_LIGHT.darkened(0.2), 4.0)
	# Colunas ao longo do muro.
	for i in 24:
		var angle := TAU * i / 24.0
		var direction := Vector2.from_angle(angle)
		var side := Vector2(-direction.y, direction.x)
		var base := direction * (radius + 6.0)
		var top := direction * (radius + 78.0)
		draw_colored_polygon(PackedVector2Array([base - side * 15.0, base + side * 15.0, top + side * 15.0, top - side * 15.0]), STONE_DARK)
		draw_colored_polygon(PackedVector2Array([base - side * 12.0, base + side * 12.0, top + side * 12.0, top - side * 12.0]), STONE_LIGHT)
		draw_line(base - side * 12.0, top - side * 12.0, STONE_DARK, 2.0)
	# Os dois portões, à esquerda e à direita: boca escura com grade.
	for gate_angle in [0.0, PI]:
		var direction := Vector2.from_angle(gate_angle)
		var side := Vector2(-direction.y, direction.x)
		var base := direction * (radius + 2.0)
		var top := direction * (radius + 82.0)
		draw_colored_polygon(PackedVector2Array([base - side * 46.0, base + side * 46.0, top + side * 46.0, top - side * 46.0]), Color("120c10"))
		for j in range(-3, 4):
			draw_line(base + side * (j * 12.0), top + side * (j * 12.0), Color("6a5a48"), 3.0)
		for j in 4:
			var row := base.lerp(top, (j + 0.5) / 4.0)
			draw_line(row - side * 46.0, row + side * 46.0, Color("6a5a48"), 3.0)
		draw_arc(base.lerp(top, 0.5), 52.0, 0.0, TAU, 24, STONE_LIGHT, 4.0)
	# Piso de areia.
	draw_circle(Vector2.ZERO, radius + 6.0, SAND_DARK)
	draw_circle(Vector2.ZERO, radius - 4.0, SAND)
	# Anéis e rastelo na areia.
	for ring in 5:
		draw_arc(Vector2.ZERO, 120.0 * (ring + 1), 0.0, TAU, 96, Color(SAND_DARK, 0.5), 3.0)
	for i in 48:
		var direction := Vector2.from_angle(TAU * i / 48.0)
		draw_line(direction * 90.0, direction * (radius - 24.0), Color(SAND_DARK, 0.22), 2.0)
	# Emblema no centro: círculo e espadas cruzadas.
	draw_circle(Vector2.ZERO, 84.0, Color(SAND_DARK, 0.55))
	draw_arc(Vector2.ZERO, 84.0, 0.0, TAU, 64, Color("8a6a3a"), 5.0)
	draw_arc(Vector2.ZERO, 66.0, 0.0, TAU, 64, Color("8a6a3a"), 2.0)
	for flip in [-1.0, 1.0]:
		draw_line(Vector2(-48, -48 * flip), Vector2(48, 48 * flip), Color("6a4a22"), 7.0)
		draw_line(Vector2(-48, -48 * flip), Vector2(48, 48 * flip), Color("b8a070"), 3.0)
	draw_circle(Vector2.ZERO, 14.0, Color("6a4a22"))
	draw_circle(Vector2.ZERO, 8.0, Color("d2aa4e"))
	# Manchas e pedrinhas no chão.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 90:
		var spot := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40.0, radius - 30.0)
		draw_circle(spot, rng.randf_range(2.0, 6.0), Color(SAND_DARK, 0.5))


## Tochas no muro: a chama pisca uns 8 vezes por segundo.
class Torches extends Node2D:
	var spots: Array = []
	var _clock := 0.0
	var _next := 0.0

	func _ready() -> void:
		z_index = -99

	func _process(delta: float) -> void:
		_clock += delta
		if _clock >= _next:
			_next = _clock + 0.12
			queue_redraw()

	func _draw() -> void:
		for i in spots.size():
			var spot: Vector2 = spots[i]
			var flicker := 0.75 + 0.25 * sin(_clock * 11.0 + i * 1.7)
			draw_circle(spot, 22.0 * flicker, Color(1.0, 0.55, 0.15, 0.16))
			draw_circle(spot, 8.0, Color("3a2a1a"))
			draw_circle(spot + Vector2(0, -3), 6.0 * flicker, Color("ff8a2a"))
			draw_circle(spot + Vector2(0, -4), 3.2 * flicker, Color("ffe08a"))
