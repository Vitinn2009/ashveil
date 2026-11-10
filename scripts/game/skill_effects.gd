class_name SkillEffects
extends RefCounted

## Efeitos em campo das habilidades novas (ver SkillsExtra): explosões com espera, orbes que giram em volta do
## herói, armadilhas, chuva de flechas e a torreta do Gnomo. Todos ferem os monstros (grupo "enemies").


static func enemies_in(tree: SceneTree, center: Vector2, radius: float) -> Array:
	var found: Array = []
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion() and enemy.global_position.distance_to(center) <= radius + enemy.radius:
			found.append(enemy)
	return found


static func nearest_enemy(tree: SceneTree, from: Vector2, max_range: float) -> Enemy:
	var best: Enemy = null
	var best_distance := max_range
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or enemy.is_intangible():
			continue
		var distance := from.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## Explosão em área depois de uma espera: marca o chão e, no fim, fere, queima e atordoa.
class Blast extends Node2D:
	var radius := 120.0
	var delay := 0.8
	var damage := 40.0
	var color := Color("ff7a1a")
	var burn_ticks := 0
	var burn_damage := 0.0
	var stun_time := 0.0
	var knock := 0.0
	## "meteor" desenha a rocha caindo do alto.
	var falling := ""
	var _time := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 4

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time >= delay and not _done:
			_done = true
			_explode()
			queue_free()
			return
		queue_redraw()

	func _explode() -> void:
		var ring := RingEffect.new()
		ring.radius = radius
		ring.color = color
		ring.duration = 0.4
		get_parent().add_child(ring)
		ring.global_position = global_position
		for enemy in SkillEffects.enemies_in(get_tree(), global_position, radius):
			enemy.take_damage(damage, "skill")
			if enemy.is_queued_for_deletion():
				continue
			if burn_ticks > 0:
				enemy.apply_burn(burn_ticks, burn_damage)
			if stun_time > 0.0:
				enemy.stun(stun_time)
			if knock > 0.0:
				var offset: Vector2 = enemy.global_position - global_position
				enemy.knockback((offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT) * knock)
		EventBus.impact.emit(6.0, 0.0)

	func _draw() -> void:
		var progress := clampf(_time / maxf(delay, 0.01), 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(color, 0.08 + 0.14 * progress))
		draw_arc(Vector2.ZERO, radius * progress, 0.0, TAU, 40, Color(color, 0.95), 3.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.6), 2.0)
		if falling == "meteor":
			var height := 320.0 * (1.0 - progress)
			draw_circle(Vector2(0, -height - 10.0), 22.0, Color("5a2a10"))
			draw_circle(Vector2(0, -height - 10.0), 15.0, color)
			draw_line(Vector2(0, -height - 10.0), Vector2(0, -height - 70.0), Color(color, 0.5), 10.0)


## Orbes (ou lâminas) que giram em volta do herói e ferem quem encostar.
class Orbit extends Node2D:
	var count := 3
	var orbit_radius := 110.0
	var contact_radius := 28.0
	var duration := 6.0
	var damage := 10.0
	var interval := 0.35
	var color := Color("b36bff")
	var spin := 3.4
	var _time := 0.0
	var _angle := 0.0
	var _cooldowns := {}

	func _ready() -> void:
		z_index = 6

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time >= duration:
			queue_free()
			return
		_angle += spin * delta
		for id in _cooldowns.keys():
			_cooldowns[id] -= delta
		for i in count:
			var spot := global_position + Vector2.from_angle(_angle + TAU * i / count) * orbit_radius
			for enemy in SkillEffects.enemies_in(get_tree(), spot, contact_radius):
				var key: int = enemy.get_instance_id()
				if _cooldowns.get(key, 0.0) > 0.0:
					continue
				_cooldowns[key] = interval
				enemy.take_damage(damage, "skill")
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(duration - _time, 0.0, 1.0)
		draw_arc(Vector2.ZERO, orbit_radius, 0.0, TAU, 48, Color(color, 0.25 * fade), 2.0)
		for i in count:
			var spot := Vector2.from_angle(_angle + TAU * i / count) * orbit_radius
			draw_circle(spot, contact_radius * 0.9, Color(color, 0.35 * fade))
			draw_circle(spot, contact_radius * 0.55, Color(color, fade))
			draw_circle(spot, contact_radius * 0.25, Color(1, 1, 1, fade))


## Armadilha ou mina: fica armada no chão e explode quando o primeiro monstro chega perto.
class Trap extends Node2D:
	var trigger_radius := 55.0
	var blast_radius := 110.0
	var duration := 12.0
	var damage := 50.0
	var stun_time := 0.0
	var color := Color("7bd389")
	var _time := 0.0

	func _ready() -> void:
		z_index = -10

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time >= duration:
			queue_free()
			return
		if not SkillEffects.enemies_in(get_tree(), global_position, trigger_radius).is_empty():
			_explode()
			queue_free()
			return
		queue_redraw()

	func _explode() -> void:
		var ring := RingEffect.new()
		ring.radius = blast_radius
		ring.color = color
		ring.duration = 0.4
		get_parent().add_child(ring)
		ring.global_position = global_position
		for enemy in SkillEffects.enemies_in(get_tree(), global_position, blast_radius):
			enemy.take_damage(damage, "skill")
			if stun_time > 0.0 and not enemy.is_queued_for_deletion():
				enemy.stun(stun_time)
		EventBus.impact.emit(5.0, 0.0)

	func _draw() -> void:
		var blink := 0.5 + 0.5 * sin(_time * 6.0)
		draw_circle(Vector2.ZERO, 14.0, Color("2a2218"))
		draw_circle(Vector2.ZERO, 9.0, Color(color, 0.5 + 0.4 * blink))
		for i in 8:
			var direction := Vector2.from_angle(TAU * i / 8.0)
			draw_line(direction * 12.0, direction * 20.0, Color("c9c2b0"), 2.0)
		draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 32, Color(color, 0.18), 1.5)


## Chuva de flechas: uma área que leva dano de tempos em tempos enquanto durar.
class Rain extends Node2D:
	var radius := 150.0
	var duration := 3.0
	var interval := 0.35
	var damage := 14.0
	var color := Color("f2b705")
	var _time := 0.0
	var _tick := 0.0

	func _ready() -> void:
		z_index = 3

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time >= duration:
			queue_free()
			return
		_tick -= delta
		if _tick <= 0.0:
			_tick = interval
			for enemy in SkillEffects.enemies_in(get_tree(), global_position, radius):
				enemy.take_damage(damage, "skill")
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(duration - _time, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(color, 0.1 * fade))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 0.7 * fade), 2.5)
		for i in 14:
			var seed_angle := float(i) * 2.399 + floorf(_time * 5.0) * 0.7
			var spot := Vector2.from_angle(seed_angle) * radius * fmod(float(i) * 0.37 + _time, 1.0) * 0.95
			draw_line(spot + Vector2(-6, -34), spot, Color(0.95, 0.9, 0.7, 0.9 * fade), 2.0)
			draw_colored_polygon(PackedVector2Array([spot + Vector2(-3, -4), spot + Vector2(3, -4), spot]), Color(color, fade))


## Torreta do Gnomo: atira no monstro mais perto enquanto durar.
class Turret extends Node2D:
	var duration := 8.0
	var interval := 0.45
	var damage := 10.0
	var shoot_range := 420.0
	var color := Color("f4d58a")
	var _time := 0.0
	var _tick := 0.2
	var _aim := Vector2.RIGHT

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time >= duration:
			queue_free()
			return
		_tick -= delta
		if _tick <= 0.0:
			_tick = interval
			var target := SkillEffects.nearest_enemy(get_tree(), global_position, shoot_range)
			if target != null:
				_aim = (target.global_position - global_position).normalized()
				var shot := Projectile.new()
				shot.style = "fragment"
				shot.color = color
				shot.radius = 4.5
				shot.damage = damage
				shot.velocity = _aim * 560.0
				shot.lifetime = shoot_range / 560.0
				get_parent().add_child(shot)
				shot.global_position = global_position + Vector2(0, -16) + _aim * 14.0
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(duration - _time, 0.0, 1.0)
		draw_circle(Vector2(0, 2), 14.0, Color(0, 0, 0, 0.3 * fade))
		draw_rect(Rect2(-12, -12, 24, 16), Color("3a3a4a"))
		draw_rect(Rect2(-12, -12, 24, 16), Color("c9962c"), false, 2.0)
		draw_line(Vector2(0, -8), _aim * 22.0 + Vector2(0, -8), Color("c9962c"), 6.0)
		draw_circle(Vector2(0, -8), 6.0, Color("8a8a9a"))
