class_name Skills
extends RefCounted

## Habilidades ativas. `activate` recebe o Game, que expõe player, weapon e world.
## Cada uma gasta energia (`cost`) e tem recarga (`cooldown`).
## Os atributos de habilidade do herói escalam o efeito:
## alcance (área e distância), x2 (chance de repetir), recarga e poder.

## Cada habilidade ativa tem 5 níveis; subir do nível N-1 para N custa N pontos de habilidade (1, 2, 3, 4, 5).
## Cada nível dá mais poder e alcance e menos recarga.
const MAX_LEVEL := 5
const POWER_PER_LEVEL := 0.15
const RANGE_PER_LEVEL := 0.05
const COOLDOWN_PER_LEVEL := 0.04
const ECHO_DELAY := 0.35
const SLASH_GAP := 0.18
const BOMB_RAIN_COUNT := 5

const DEFS := {
	"freeze": {
		"name": "Gelo",
		"desc": "Congela o chão: inimigos na área ficam 60% mais lentos por 5s.",
		"cooldown": 10.0, "cost": 25.0,
		"color": Color("6ec6ff"), "glyph": "G",
	},
	"fire": {
		"name": "Fogo",
		"desc": "Bola de fogo que queima o inimigo 3 vezes.",
		"cooldown": 6.0, "cost": 20.0,
		"color": Color("ff7a1a"), "glyph": "F",
	},
	"wind": {
		"name": "Vento",
		"desc": "Rajada que empurra os inimigos próximos.",
		"cooldown": 8.0, "cost": 20.0,
		"color": Color("9be8c8"), "glyph": "V",
	},
	"lightning": {
		"name": "Raio",
		"desc": "Raios caem sobre até 6 inimigos, com dano em área ao redor de cada um.",
		"cooldown": 12.0, "cost": 45.0,
		"color": Color("ffe45c"), "glyph": "R",
	},
	"double": {
		"name": "Flecha Dupla",
		"desc": "Dobra a quantidade de flechas por 6s (cada flecha causa 60% do dano).",
		"cooldown": 12.0, "cost": 25.0,
		"color": Color("f2b705"), "glyph": "2x",
	},
	"haste": {
		"name": "Velocidade",
		"desc": "+50% de movimento e +40% de ataque por 6s.",
		"cooldown": 14.0, "cost": 20.0,
		"color": Color("7bd389"), "glyph": "»",
	},
	"fire_arrows": {
		"name": "Flechas de Fogo",
		"desc": "Dispara 5 flechas em leque que queimam o que atravessam.",
		"cooldown": 12.0, "cost": 40.0,
		"color": Color("ff6a1a"), "glyph": "5",
	},
	"slash": {
		"name": "Corte Duplo",
		"desc": "Dois cortes de espada no ar, à frente, com dano x2 cada um.",
		"cooldown": 8.0, "cost": 28.0,
		"color": Color("e8edf5"), "glyph": "X",
	},
	"shield": {
		"name": "Escudo",
		"desc": "Absorve dano por 6s.",
		"cooldown": 12.0, "cost": 25.0,
		"color": Color("4aa3ff"), "glyph": "E",
	},
	"ground_slam": {
		"name": "Pancada no Chão",
		"desc": "Bate no chão e abala tudo ao redor: dano em área e atordoa por 1s.",
		"cooldown": 14.0, "cost": 40.0,
		"color": Color("c98a4a"), "glyph": "P",
	},
	"bomb": {
		"name": "Bomba de Fogo",
		"desc": "Arremessa uma bomba que explode em área e queima o dobro (6 vezes).",
		"cooldown": 7.0, "cost": 25.0,
		"color": Color("ff7a1a"), "glyph": "B",
	},
	"paralysis": {
		"name": "Poção Paralisante",
		"desc": "Arremessa uma poção que paralisa os inimigos na área por 2s.",
		"cooldown": 12.0, "cost": 25.0,
		"color": Color("7bd389"), "glyph": "Z",
	},
	"bomb_rain": {
		"name": "Chuva de Bombas",
		"desc": "Lança 5 bombas de fogo, uma sobre cada inimigo próximo.",
		"cooldown": 16.0, "cost": 45.0,
		"color": Color("ff4a1a"), "glyph": "C",
	},
}


## Habilidades que podem ser miradas arrastando o botão (as outras acontecem em volta do herói).
const AIMED := ["fire", "fire_arrows", "slash", "bomb", "paralysis"]


static func is_aimed(id: String) -> bool:
	return AIMED.has(id)


static func def(id: String) -> Dictionary:
	return DEFS[id]


static func cost_for(id: String) -> float:
	return DEFS[id]["cost"]


## Recarga total de uma habilidade, com cartas e atributos de recarga.
static func cooldown_for(id: String, game) -> float:
	return DEFS[id]["cooldown"] * game.cooldown_scale * game.player.skill_cooldown_mult() * (1.0 - COOLDOWN_PER_LEVEL * level_of(id, game))


## Dispara a habilidade. Com a chance de x2, repete o efeito logo depois.
static func activate(id: String, game) -> void:
	cast(id, game, false)
	if randf() < game.player.skill_echo_chance():
		game.get_tree().create_timer(ECHO_DELAY).timeout.connect(func() -> void:
			if is_instance_valid(game) and not game.game_over:
				cast(id, game, true))


## `repeat` é true na segunda vez (x2): efeitos de duração se somam.
static func cast(id: String, game, repeat := false) -> void:
	var player: Player = game.player
	var level := level_of(id, game)
	var power := player.skill_power_mult() * (1.0 + POWER_PER_LEVEL * level)
	var reach := player.skill_range_mult() * (1.0 + RANGE_PER_LEVEL * level)
	match id:
		"freeze":
			_freeze(game, power, reach)
		"fire":
			_fire(game, power, reach)
		"wind":
			_wind(game, power, reach)
		"lightning":
			_lightning(game, power, reach)
		"slash":
			_slash(game, power, reach)
		"fire_arrows":
			_fire_arrows(game, power, reach)
		"ground_slam":
			_ground_slam(game, power, reach)
		"bomb":
			_throw(game, "bomb", power, reach)
		"paralysis":
			_throw(game, "paralysis", power, reach)
		"bomb_rain":
			_bomb_rain(game, power, reach)
		"double":
			player.double_time = (player.double_time if repeat else 0.0) + 6.0 * power
			_ring(game, 60.0 * reach, DEFS["double"]["color"], 0.4)
		"haste":
			player.haste_time = (player.haste_time if repeat else 0.0) + 6.0 * power
			_ring(game, 70.0 * reach, DEFS["haste"]["color"], 0.4)
		"shield":
			var absorb := (50.0 + player.get_defense() * 3.0) * power
			if repeat and player.shield_hp > 0.0:
				absorb += player.shield_hp
			player.activate_shield(6.0, absorb)
			_ring(game, 60.0 * reach, DEFS["shield"]["color"], 0.4)


static func _ring(game, radius: float, color: Color, duration: float, at := Vector2.INF) -> void:
	var ring := RingEffect.new()
	ring.radius = radius
	ring.color = color
	ring.duration = duration
	game.world.add_child(ring)
	ring.global_position = game.player.global_position if at == Vector2.INF else at


## Inimigos vivos num raio. Devolve uma cópia: matar um deles não estraga o laço.
static func enemies_near(game, center: Vector2, radius: float) -> Array:
	var found: Array = []
	for node in game.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion() and enemy.global_position.distance_to(center) <= radius + enemy.radius:
			found.append(enemy)
	return found


static func _freeze(game, power: float, reach: float) -> void:
	var zone := SkillZone.new()
	zone.radius = 170.0 * reach
	zone.duration = 5.0 * power
	zone.slow_factor = clampf(0.4 / power, 0.2, 0.4)
	game.world.add_child(zone)
	zone.global_position = game.player.global_position
	_ring(game, zone.radius, DEFS["freeze"]["color"], 0.45)


## Direção do disparo: a mira escolhida pelo jogador ou, sem ela, o inimigo mais próximo (ou a frente).
static func _aim_direction(game, search_range: float) -> Vector2:
	if game.aim_dir != Vector2.ZERO:
		return game.aim_dir
	var targets: Array = game.weapon.find_targets(search_range)
	if not targets.is_empty():
		return (targets[0].global_position - game.player.global_position).normalized()
	return game.player.facing


static func _fire(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var direction := _aim_direction(game, 520.0 * reach)
	var bolt := Projectile.new()
	bolt.style = "fire"
	bolt.color = DEFS["fire"]["color"]
	bolt.radius = 11.0 * (1.0 + (reach - 1.0) * 0.5)
	bolt.damage = (16.0 + game.weapon.damage * 0.5) * player.get_damage_mult() * power
	bolt.velocity = direction * 380.0
	bolt.lifetime = 1.6 * reach
	bolt.burn_ticks = 3
	bolt.burn_damage = 8.0 * player.get_damage_mult() * power
	game.world.add_child(bolt)
	bolt.global_position = player.global_position


static func _wind(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var radius := 240.0 * reach
	_ring(game, radius, DEFS["wind"]["color"], 0.4)
	for enemy in enemies_near(game, player.global_position, radius):
		var offset: Vector2 = enemy.global_position - player.global_position
		if offset.length() <= radius:
			var direction := offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT
			enemy.knockback(direction * 560.0 * power)
			enemy.take_damage(4.0 * player.get_damage_mult() * power, "skill")


## Raio (nível 20 do Mago): cai sobre os inimigos mais próximos e abala os vizinhos.
static func _lightning(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var strike_radius := 70.0 * reach
	var strikes: Array = game.weapon.find_targets(440.0 * reach).slice(0, 6)
	var damage: float = (30.0 + game.weapon.damage * 1.2) * player.get_damage_mult() * power
	var points: Array = []
	for enemy in strikes:
		points.append(enemy.global_position)
	if points.is_empty():
		points.append(player.global_position + player.facing * 220.0)
	for point in points:
		var bolt := LightningBolt.new()
		bolt.radius = strike_radius
		game.world.add_child(bolt)
		bolt.global_position = point
		for enemy in enemies_near(game, point, strike_radius):
			var splash: bool = enemy.global_position.distance_to(point) > 8.0
			enemy.take_damage(damage * (0.4 if splash else 1.0), "skill")


## Corte Duplo: duas ondas de espada à frente, uma logo depois da outra.
static func _slash(game, power: float, reach: float) -> void:
	_wave(game, power, reach)
	game.get_tree().create_timer(SLASH_GAP).timeout.connect(func() -> void:
		if is_instance_valid(game) and not game.game_over:
			_wave(game, power, reach))


static func _wave(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var direction: Vector2 = game.aim_dir if game.aim_dir != Vector2.ZERO else player.facing
	var wave := Projectile.new()
	wave.style = "slash"
	wave.color = DEFS["slash"]["color"]
	wave.radius = 34.0 * (1.0 + (reach - 1.0) * 0.5)
	wave.damage = game.weapon.damage * 2.0 * player.get_damage_mult() * power
	wave.velocity = direction * 520.0
	wave.lifetime = 270.0 * reach / 520.0
	wave.pierce = 999
	game.world.add_child(wave)
	wave.global_position = player.global_position + direction * 24.0


## Flechas de Fogo (nível 20 do Arqueiro): 5 flechas em leque que queimam.
static func _fire_arrows(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var direction := _aim_direction(game, 520.0 * reach)
	for i in 5:
		var arrow := Projectile.new()
		arrow.style = "fire_arrow"
		arrow.color = DEFS["fire_arrows"]["color"]
		arrow.damage = game.weapon.damage * 1.4 * player.get_damage_mult() * power
		arrow.velocity = direction.rotated(lerpf(-0.34, 0.34, i / 4.0)) * 700.0
		arrow.lifetime = 0.9 * reach
		arrow.pierce = 1
		arrow.burn_ticks = 3
		arrow.burn_damage = 6.0 * player.get_damage_mult() * power
		game.world.add_child(arrow)
		arrow.global_position = player.global_position + Vector2(0, -14)


## Pancada no Chão (nível 20 do Guerreiro): dano em área, atordoa e afasta.
static func _ground_slam(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var radius := 230.0 * reach
	var damage: float = game.weapon.damage * 3.0 * player.get_damage_mult() * power
	var crack := CrackEffect.new()
	crack.radius = radius
	game.world.add_child(crack)
	crack.global_position = player.global_position
	for enemy in enemies_near(game, player.global_position, radius):
		var offset: Vector2 = enemy.global_position - player.global_position
		enemy.take_damage(damage, "skill")
		if not enemy.is_queued_for_deletion():
			enemy.stun(1.0 * (1.0 + (power - 1.0) * 0.5))
			enemy.knockback((offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT) * 260.0)


## Onde o Gnomo mira: o inimigo mais próximo ou, sem ninguém, à frente do herói.
static func _aim_point(game, reach: float) -> Vector2:
	var player: Player = game.player
	if game.aim_dir != Vector2.ZERO:
		return player.global_position + game.aim_dir * game.aim_dist
	var targets: Array = game.weapon.find_targets(620.0 * reach)
	if not targets.is_empty():
		return targets[0].global_position
	return player.global_position + player.facing * 260.0


static func _throw(game, kind: String, power: float, reach: float, delay := 0.0, at := Vector2.INF) -> void:
	var item := ThrownItem.new()
	item.kind = kind
	item.game = game
	item.power = power
	item.reach = reach
	item.delay = delay
	item.origin = game.player.global_position
	item.destination = _aim_point(game, reach) if at == Vector2.INF else at
	game.world.add_child(item)
	item.global_position = item.origin


## Chuva de Bombas (nível 20 do Gnomo): uma bomba sobre cada inimigo próximo.
static func _bomb_rain(game, power: float, reach: float) -> void:
	var targets: Array = game.weapon.find_targets(620.0 * reach).slice(0, BOMB_RAIN_COUNT)
	var points: Array = []
	for enemy in targets:
		points.append(enemy.global_position)
	var player: Player = game.player
	while points.size() < BOMB_RAIN_COUNT:
		points.append(player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 320.0))
	for i in points.size():
		_throw(game, "bomb", power, reach, i * 0.12, points[i])


## Pontos para levar uma habilidade do nível `level` ao seguinte (1, 2, 3, 4, 5).
static func upgrade_cost(level: int) -> int:
	return level + 1


static func level_of(id: String, game) -> int:
	return int(game.player.skill_levels.get(id, 0))


## O que o nível da habilidade dá, em texto ("+45% de poder, +15% de alcance, -12% de recarga").
static func level_effect_text(level: int) -> String:
	if level <= 0:
		return "sem melhorias"
	return "+%d%% de poder, +%d%% de alcance, -%d%% de recarga" % [
		int(round(POWER_PER_LEVEL * level * 100.0)), int(round(RANGE_PER_LEVEL * level * 100.0)), int(round(COOLDOWN_PER_LEVEL * level * 100.0))]
