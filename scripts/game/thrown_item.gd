class_name ThrownItem
extends Node2D

## Bomba ou poção arremessada pelo Gnomo. Voa em arco até o destino e ali
## explode (bomba) ou se quebra (poção paralisante).

const FLIGHT_TIME := 0.55
const BOMB_RADIUS := 120.0
const FLASK_RADIUS := 140.0
const PARALYSIS_TIME := 2.0

var kind := "bomb"
var game
var power := 1.0
var reach := 1.0
var delay := 0.0
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var _time := 0.0
var _height := 0.0
var _landed := false


func _ready() -> void:
	z_index = 6
	visible = delay <= 0.0


func _process(delta: float) -> void:
	if _landed:
		return
	if delay > 0.0:
		delay -= delta
		if delay > 0.0:
			return
		visible = true
	_time += delta
	var progress := clampf(_time / FLIGHT_TIME, 0.0, 1.0)
	global_position = origin.lerp(destination, progress)
	_height = sin(progress * PI) * 70.0
	rotation = progress * TAU * 1.5
	queue_redraw()
	if progress >= 1.0:
		_land()


func _land() -> void:
	_landed = true
	rotation = 0.0
	if kind == "paralysis":
		_break_flask()
	else:
		_explode()
	queue_free()


## Bomba de Fogo: dano em área e queimadura em dobro (6 vezes, o dobro do Fogo).
func _explode() -> void:
	var player: Player = game.player
	var radius := BOMB_RADIUS * reach
	var damage: float = (40.0 + game.weapon.damage * 1.5) * player.get_damage_mult() * power
	for enemy in Skills.enemies_near(game, global_position, radius):
		enemy.take_damage(damage, "skill")
		if not enemy.is_queued_for_deletion():
			enemy.apply_burn(6, 8.0 * player.get_damage_mult() * power)
	Skills._ring(game, radius, Color("ff7a1a"), 0.4, global_position)
	Skills._ring(game, radius * 0.55, Color("ffd36b"), 0.3, global_position)


## Poção Paralisante: os inimigos na área ficam parados por 2s.
func _break_flask() -> void:
	var radius := FLASK_RADIUS * reach
	for enemy in Skills.enemies_near(game, global_position, radius):
		enemy.stun(PARALYSIS_TIME * (1.0 + (power - 1.0) * 0.5), "paralysis")
		enemy.apply_poison(3, 5.0 * game.player.get_damage_mult() * power)
	var cloud := CloudEffect.new()
	cloud.radius = radius
	game.world.add_child(cloud)
	cloud.global_position = global_position


func _draw() -> void:
	# Sombra no chão, fixa, e o objeto no ar, acima dela.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	draw_circle(Vector2(0, 0), 7.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -_height - 8.0), 0.0, Vector2.ONE)
	if kind == "paralysis":
		draw_circle(Vector2.ZERO, 9.0, Brand.NIGHT)
		draw_circle(Vector2.ZERO, 7.5, Color("7bd389"))
		draw_rect(Rect2(-3, -14, 6, 8), Brand.NIGHT)
		draw_rect(Rect2(-2, -13, 4, 6), Brand.PARCHMENT)
		draw_circle(Vector2(-2.5, -2.5), 2.2, Color("d6ffd2"))
	else:
		draw_circle(Vector2.ZERO, 10.0, Color("14101c"))
		draw_circle(Vector2.ZERO, 8.5, Color("3a3a4a"))
		draw_circle(Vector2(-3, -3), 2.6, Color("8a8a9a"))
		draw_line(Vector2(0, -9), Vector2(5, -15), Color("c9a06a"), 2.5)
		draw_circle(Vector2(5, -15), 3.5, Color("ffb02e"))
