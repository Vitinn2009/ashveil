class_name PetFollower
extends Node2D

## O pet do herói: anda atrás dele, flutuando de leve, e atira nos inimigos por perto (o dano vem do nível do
## pet, sem limite). Cada pet vem de um chefe ou de 1000 abates de um monstro (ver Pets).

const FOLLOW_SPEED := 4.0
const SPOT := Vector2(-46.0, -6.0)

var pet_id := ""
var target: Node2D
var _clock := randf() * 6.0
var _shot_timer := 0.8


func setup(id: String, follow: Node2D) -> void:
	pet_id = id
	target = follow
	z_index = 1
	global_position = follow.global_position + SPOT


func _process(delta: float) -> void:
	_clock += delta
	if target == null or not is_instance_valid(target):
		return
	# Fica do lado de trás do herói (a esquerda, se ele anda para a direita).
	var side := -1.0 if target.get("facing") == null or target.facing.x >= 0.0 else 1.0
	var wanted: Vector2 = target.global_position + Vector2(-SPOT.x * side, SPOT.y)
	global_position = global_position.lerp(wanted, clampf(FOLLOW_SPEED * delta, 0.0, 1.0))
	queue_redraw()
	_shot_timer -= delta
	if _shot_timer <= 0.0:
		_try_shoot()


func _draw() -> void:
	var bob := sin(_clock * 4.0) * 3.0
	var data := Pets.get_pet(pet_id)
	var color: Color = data.get("color", Color.WHITE)
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	match pet_id:
		"slime_king":
			var body := PackedVector2Array()
			for i in 16:
				var angle := TAU * i / 16.0
				body.append(Vector2(cos(angle) * 12.0, sin(angle) * 10.0 * (1.0 + 0.06 * sin(_clock * 6.0))) + Vector2(0, bob))
			var outline := PackedVector2Array()
			for point in body:
				outline.append(point * 1.18)
			draw_colored_polygon(outline, Brand.NIGHT)
			draw_colored_polygon(body, color)
			draw_circle(Vector2(-4, -3 + bob), 4.5, Color.WHITE)
			draw_circle(Vector2(4, -3 + bob), 4.5, Color.WHITE)
			draw_circle(Vector2(-3, -3 + bob), 2.0, Brand.NIGHT)
			draw_circle(Vector2(5, -3 + bob), 2.0, Brand.NIGHT)
			var crown := PackedVector2Array([Vector2(-6, -9 + bob), Vector2(-6, -15 + bob), Vector2(-3, -12 + bob), Vector2(0, -16 + bob), Vector2(3, -12 + bob), Vector2(6, -15 + bob), Vector2(6, -9 + bob)])
			draw_colored_polygon(crown, Brand.GOLD)
		"ash_lord":
			# Fagulha: uma chama com olhos.
			var flame := PackedVector2Array([
				Vector2(0, -18 + bob), Vector2(8, -6 + bob), Vector2(10, 4 + bob), Vector2(0, 11 + bob),
				Vector2(-10, 4 + bob), Vector2(-8, -6 + bob)])
			var halo := PackedVector2Array()
			for point in flame:
				halo.append(point * 1.2)
			draw_colored_polygon(halo, Brand.NIGHT)
			draw_colored_polygon(flame, color)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -8 + bob), Vector2(4, 0 + bob), Vector2(0, 7 + bob), Vector2(-4, 0 + bob)]), color.lightened(0.5))
			draw_circle(Vector2(-3, -1 + bob), 1.8, Brand.NIGHT)
			draw_circle(Vector2(3, -1 + bob), 1.8, Brand.NIGHT)
		"dire_wolf":
			# Lobo sombrio: pelo cinza-azulado, orelhas pontudas, olhos vermelhos e cauda cheia.
			var step := sin(_clock * 8.0) * 1.5
			var tail := PackedVector2Array([Vector2(-11, -1 + bob), Vector2(-21, -9 + bob + step), Vector2(-24, -3 + bob + step), Vector2(-12, 5 + bob)])
			draw_colored_polygon(tail, Brand.NIGHT)
			draw_colored_polygon(PackedVector2Array([Vector2(-12, 0 + bob), Vector2(-20, -7 + bob + step), Vector2(-22, -3 + bob + step), Vector2(-12, 4 + bob)]), color.lightened(0.15))
			for leg_x in [-8.0, -2.0, 4.0, 9.0]:
				draw_rect(Rect2(leg_x - 1.5, 6 + bob, 3.5, 7), Brand.NIGHT)
			var body_wolf := PackedVector2Array([Vector2(-12, 2 + bob), Vector2(-8, -6 + bob), Vector2(6, -6 + bob), Vector2(13, -1 + bob), Vector2(11, 8 + bob), Vector2(-10, 8 + bob)])
			var outline_wolf := PackedVector2Array()
			for point in body_wolf:
				outline_wolf.append(point * 1.12)
			draw_colored_polygon(outline_wolf, Brand.NIGHT)
			draw_colored_polygon(body_wolf, color)
			draw_colored_polygon(PackedVector2Array([Vector2(-6, 3 + bob), Vector2(8, 3 + bob), Vector2(9, 7 + bob), Vector2(-6, 7 + bob)]), color.lightened(0.3))
			var head_wolf := PackedVector2Array([Vector2(8, -9 + bob), Vector2(18, -7 + bob), Vector2(23, 0 + bob), Vector2(18, 4 + bob), Vector2(9, 3 + bob)])
			draw_colored_polygon(PackedVector2Array([Vector2(7, -10 + bob), Vector2(10, -18 + bob), Vector2(14, -9 + bob)]), Brand.NIGHT)
			draw_colored_polygon(PackedVector2Array([Vector2(13, -10 + bob), Vector2(17, -17 + bob), Vector2(19, -8 + bob)]), Brand.NIGHT)
			draw_colored_polygon(head_wolf, color.darkened(0.1))
			draw_polyline(head_wolf + PackedVector2Array([head_wolf[0]]), Brand.NIGHT, 1.6)
			draw_circle(Vector2(16, -3 + bob), 2.0, Color("ff3030"))
			draw_circle(Vector2(23, 0 + bob), 1.8, Brand.NIGHT)
			draw_line(Vector2(21, 3 + bob), Vector2(17, 3 + bob), Color("f4e9d8"), 1.4)
		_:
			# Pet de monstro: um bichinho na cor do monstro, com olhos, e uma marca que muda de um para outro.
			var shape := PackedVector2Array()
			for i in 18:
				var angle := TAU * i / 18.0
				shape.append(Vector2(cos(angle) * 11.0, sin(angle) * 9.5 * (1.0 + 0.05 * sin(_clock * 5.0))) + Vector2(0, bob))
			var edge := PackedVector2Array()
			for point in shape:
				edge.append(point * 1.18)
			draw_colored_polygon(edge, Brand.NIGHT)
			var accent := hash(pet_id) % 3
			if accent == 0:
				draw_colored_polygon(PackedVector2Array([Vector2(-9, -6 + bob), Vector2(-6, -16 + bob), Vector2(-2, -8 + bob)]), color.lightened(0.25))
				draw_colored_polygon(PackedVector2Array([Vector2(9, -6 + bob), Vector2(6, -16 + bob), Vector2(2, -8 + bob)]), color.lightened(0.25))
			elif accent == 1:
				draw_colored_polygon(PackedVector2Array([Vector2(-3, -9 + bob), Vector2(0, -17 + bob), Vector2(3, -9 + bob)]), color.lightened(0.4))
			draw_colored_polygon(shape, color)
			draw_circle(Vector2(-4, -2 + bob), 3.6, Color.WHITE)
			draw_circle(Vector2(4, -2 + bob), 3.6, Color.WHITE)
			draw_circle(Vector2(-3.4, -2 + bob), 1.7, Brand.NIGHT)
			draw_circle(Vector2(4.6, -2 + bob), 1.7, Brand.NIGHT)
			draw_arc(Vector2(0, 3 + bob), 3.0, 0.2, PI - 0.2, 8, Brand.NIGHT, 1.4)


## Atira no inimigo mais perto, se houver algum ao alcance.
func _try_shoot() -> void:
	var nearest: Enemy = null
	var best := Pets.SHOT_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or enemy.is_intangible():
			continue
		var distance := enemy.global_position.distance_to(global_position)
		if distance < best:
			best = distance
			nearest = enemy
	if nearest == null or get_parent() == null:
		_shot_timer = 0.3
		return
	_shot_timer = Pets.SHOT_INTERVAL
	var shot := Projectile.new()
	shot.style = "magic"
	shot.color = Pets.get_pet(pet_id).get("color", Color.WHITE)
	shot.damage = Pets.attack_damage(Session.pet_level(pet_id))
	shot.radius = 5.0
	shot.hit_kind = "skill"
	shot.velocity = (nearest.global_position - global_position).normalized() * 430.0
	shot.lifetime = Pets.SHOT_RANGE * 1.4 / 430.0
	get_parent().add_child(shot)
	shot.global_position = global_position
