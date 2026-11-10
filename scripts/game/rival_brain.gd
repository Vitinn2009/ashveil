class_name RivalBrain
extends Node

## Cérebro do rival da arena PvP. O rival é um herói (Heroes) controlado pela IA que luta com as mesmas
## regras do jogador: ataque básico do estilo dele, energia, recarga e as habilidades do herói (mais a
## de nível 20 se o jogador já passou do 20). Os números vêm do poder do jogador (vida, dano, defesa,
## velocidade, esquiva, poder de habilidade), então a luta é equilibrada; a dificuldade ajusta um pouco.

const DIFFICULTY := {
	"easy": {"name": "Fácil", "hp": 0.85, "dmg": 0.85, "think": 0.55, "reward": 0.8},
	"normal": {"name": "Normal", "hp": 1.0, "dmg": 1.0, "think": 0.35, "reward": 1.0},
	"hard": {"name": "Difícil", "hp": 1.2, "dmg": 1.15, "think": 0.2, "reward": 1.5},
}
const ENERGY_REGEN := 6.0
## O rival usa defesa x3,2 para ter a mesma redução de dano que o herói (K de 25 contra 80 nos monstros).
const DEFENSE_FACTOR := 3.2
const ARENA_MARGIN := 90.0
const MELEE_MIN_MULT := 0.6
const MELEE_MAX_MULT := 2.2

var enemy: Enemy
var player: Player
var hero_id := "mage"
var hero: Dictionary
var skill_ids: Array = []
var skill_level := 0
var cooldowns := {}
var energy := 0.0
var max_energy := 100.0
var arena_radius := 700.0
var damage_mult := 1.0
var power := 1.0
var reach := 1.0
var cooldown_mult := 1.0
var haste_time := 0.0
var double_time := 0.0
var speed_value := 150.0
var accuracy := 0.8
var think_time := 0.35
var casts := 0
var last_skill := ""

var _attack_cd := 0.9
var _think := 0.6
var _strafe := 1.0
var _strafe_timer := 1.2
var _skill_gate := 1.5
var _push_time := 0.0
var _last_player_pos := Vector2.ZERO
var _player_velocity := Vector2.ZERO


## Prepara o rival com base no jogador. Chamado pelo Game depois que o herói já tem todos os bônus.
func configure(rival: Enemy, target: Player, rival_hero: String, difficulty: String, radius_limit: float) -> void:
	enemy = rival
	player = target
	hero_id = rival_hero
	hero = Heroes.get_hero(rival_hero)
	arena_radius = radius_limit
	var setting: Dictionary = DIFFICULTY.get(difficulty, DIFFICULTY["normal"])
	think_time = float(setting["think"])
	damage_mult = player.get_damage_mult() * float(setting["dmg"])
	power = player.skill_power_mult()
	reach = player.skill_range_mult()
	cooldown_mult = player.skill_cooldown_mult()
	accuracy = float(hero["accuracy"])
	max_energy = float(hero["energy"])
	energy = max_energy
	var player_level := int(Session.progress_for(player.hero_id)["level"])
	# As habilidades seguem o progresso do jogador: as da lista abrem fase a fase e a última no nível 20.
	skill_ids = []
	var position := 0
	for entry in Heroes.default_entries(hero):
		if int(entry["unlock_level"]) > 0:
			if player_level >= int(entry["unlock_level"]):
				skill_ids.append(entry["id"])
			continue
		position += 1
		if Session.highest_unlocked() + 1 > position:
			skill_ids.append(entry["id"])
	# O nível das habilidades do rival é a média das do jogador (arredondada).
	var total := 0
	var counted := 0
	for id in player.skill_levels:
		total += int(player.skill_levels[id])
		counted += 1
	skill_level = int(round(float(total) / counted)) if counted > 0 else 0
	for id in skill_ids:
		cooldowns[id] = randf_range(1.0, 3.5)
	var speed_mult := minf(1.0 + player.stat_points("speed") * Player.SPEED_PER_POINT, Player.MAX_SPEED_MULT)
	speed_value = minf(float(hero["speed"]) * speed_mult, float(hero.get("max_speed", Player.DEFAULT_MAX_SPEED)))
	enemy.max_health = player.get_max_health() * float(setting["hp"])
	enemy.health = enemy.max_health
	enemy.defense = player.get_defense() * DEFENSE_FACTOR
	enemy.dodge_chance = player.get_dodge_chance()
	enemy.speed = speed_value
	_last_player_pos = player.global_position


func skill_power(_id: String) -> float:
	return power * (1.0 + Skills.POWER_PER_LEVEL * skill_level)


func skill_reach() -> float:
	return reach * (1.0 + Skills.RANGE_PER_LEVEL * skill_level)


func skill_cooldown(id: String) -> float:
	return float(Skills.DEFS[id]["cooldown"]) * cooldown_mult * (1.0 - Skills.COOLDOWN_PER_LEVEL * skill_level)


func basic_damage() -> float:
	return float(hero["damage"]) * damage_mult


func attack_interval() -> float:
	var speed_mult := minf(1.0 + player.stat_points("aspd") * Player.ATTACK_SPEED_PER_POINT, Player.MAX_ATTACK_SPEED_MULT)
	return float(hero["interval"]) / (speed_mult * (1.4 if haste_time > 0.0 else 1.0))


## Chamado a cada quadro de física pelo Enemy (que está vivo, sem atordoamento).
func tick(delta: float, direction: Vector2, distance: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_tick_timers(delta)
	_track_player(delta)
	_move(delta, direction, distance)
	_think -= delta
	if _think <= 0.0:
		_think = think_time * randf_range(0.7, 1.3)
		_decide_skill(direction, distance)
	_attack_cd -= delta
	if _attack_cd <= 0.0:
		_basic_attack(direction, distance)
	if _push_time > 0.0:
		_push_time -= delta
		player.add_pull((player.global_position - enemy.global_position).normalized() * 560.0)


func _tick_timers(delta: float) -> void:
	energy = minf(max_energy, energy + ENERGY_REGEN * delta)
	haste_time = maxf(0.0, haste_time - delta)
	double_time = maxf(0.0, double_time - delta)
	_skill_gate -= delta
	for id in cooldowns:
		cooldowns[id] = maxf(0.0, cooldowns[id] - delta)
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = randf_range(0.8, 2.0)
		_strafe = -_strafe if randf() < 0.6 else _strafe


## A velocidade do herói, para mirar um pouco à frente (a IA não adivinha: só estima).
func _track_player(delta: float) -> void:
	var current := (player.global_position - _last_player_pos) / maxf(delta, 0.001)
	_player_velocity = _player_velocity.lerp(current, 0.2)
	_last_player_pos = player.global_position


func _lead(from: Vector2, projectile_speed: float) -> Vector2:
	var time := from.distance_to(player.global_position) / maxf(projectile_speed, 1.0)
	return player.global_position + _player_velocity * time * 0.6


func _move(delta: float, direction: Vector2, distance: float) -> void:
	var melee: bool = hero["attack"] == "melee"
	var weapon_range := float(hero["range"])
	var far := 70.0 if melee else weapon_range * 0.8
	var near := 0.0 if melee else weapon_range * 0.45
	var side := Vector2(-direction.y, direction.x) * _strafe
	var step := Vector2.ZERO
	if distance > far:
		step = direction + side * 0.25
	elif distance < near:
		step = -direction + side * 0.5
	else:
		step = side * 0.7 if not melee else direction * 0.4 + side * 0.4
	# Perto da borda da arena, volta para o centro: a IA não fica encurralada nem sai do campo.
	var from_center := enemy.global_position.length()
	if from_center > arena_radius - ARENA_MARGIN:
		step = step.lerp(-enemy.global_position.normalized(), clampf((from_center - (arena_radius - ARENA_MARGIN)) / ARENA_MARGIN, 0.0, 1.0) * 0.9)
	var speed := speed_value * (1.5 if haste_time > 0.0 else 1.0) * enemy._slow_factor
	enemy.global_position += step.limit_length(1.0) * speed * delta
	if absf(direction.x) > 0.1:
		enemy.face_sprite(direction.x < 0.0)


# --- Ataque básico ---------------------------------------------------------------------

func _basic_attack(direction: Vector2, distance: float) -> void:
	var weapon_range := float(hero["range"])
	if distance > weapon_range:
		return
	_attack_cd = attack_interval()
	var kind: String = hero["attack"]
	var damage := basic_damage()
	var origin := enemy.global_position + Vector2(0, -14)
	var parent := enemy.get_parent()
	match kind:
		"melee":
			var proximity := 1.0 - clampf(distance / weapon_range, 0.0, 1.0)
			var slash := SlashEffect.new()
			slash.radius = weapon_range
			slash.half_arc = 0.96
			slash.color = hero["projectile_color"]
			slash.facing_angle = direction.angle()
			parent.add_child(slash)
			slash.global_position = enemy.global_position
			if randf() <= accuracy:
				player.take_damage(damage * lerpf(MELEE_MIN_MULT, MELEE_MAX_MULT, proximity), "hit", 0.0, true)
			else:
				EventBus.damage_dealt.emit(0.0, player.global_position, "miss")
		"blunderbuss":
			var aim := (_lead(origin, float(hero["projectile_speed"])) - origin).normalized()
			for i in Weapon.FRAGMENTS:
				var angle := lerpf(-Weapon.FRAGMENT_SPREAD, Weapon.FRAGMENT_SPREAD, float(i) / (Weapon.FRAGMENTS - 1))
				_shoot("fragment", aim.rotated(angle), damage, float(hero["projectile_speed"]), weapon_range * 1.15, 4.5, 0)
		"arrow":
			var aim := (_lead(origin, float(hero["projectile_speed"])) - origin).normalized()
			var count := 2 if double_time > 0.0 else 1
			var scale := Weapon.DOUBLE_ARROW_DAMAGE if double_time > 0.0 else 1.0
			for i in count:
				_shoot("arrow", aim.rotated((i - (count - 1) * 0.5) * 0.24), damage * scale, float(hero["projectile_speed"]), weapon_range * 1.5, 6.0, 1)
		_:
			var aim := (_lead(origin, float(hero["projectile_speed"])) - origin).normalized()
			_shoot("magic", aim.rotated(randf_range(-0.04, 0.04)), damage, float(hero["projectile_speed"]), weapon_range * 1.5, 6.0, 0)


func _shoot(style: String, direction: Vector2, damage: float, speed: float, max_range: float, radius: float, pierce: int, color := Color.TRANSPARENT) -> PvpProjectile:
	var shot := PvpProjectile.new()
	shot.player = player
	shot.style = style
	shot.color = hero["projectile_color"] if color == Color.TRANSPARENT else color
	shot.damage = damage
	shot.velocity = direction * speed
	shot.lifetime = max_range / maxf(speed, 1.0)
	shot.radius = radius
	shot.pierce = pierce
	shot.accuracy = accuracy
	enemy.get_parent().add_child(shot)
	shot.global_position = enemy.global_position + Vector2(0, -14) + direction * 22.0
	return shot


# --- Habilidades -----------------------------------------------------------------------

## A cada pensada, vê se vale usar alguma habilidade (energia, recarga e situação).
func _decide_skill(direction: Vector2, distance: float) -> void:
	if _skill_gate > 0.0:
		return
	var hp_ratio := enemy.health / maxf(enemy.max_health, 1.0)
	for id in skill_ids:
		if cooldowns.get(id, 0.0) > 0.0 or energy < Skills.cost_for(id):
			continue
		if not _wants(id, distance, hp_ratio):
			continue
		_cast(id, direction, distance)
		return


## Quando cada habilidade faz sentido (a mesma lógica que um jogador usaria).
func _wants(id: String, distance: float, hp_ratio: float) -> bool:
	match id:
		"freeze":
			return distance < 260.0 * skill_reach()
		"fire":
			return distance < 480.0
		"wind":
			return distance < 220.0 * skill_reach()
		"lightning":
			return distance < 440.0
		"double":
			return distance < 520.0 and double_time <= 0.0
		"haste":
			return haste_time <= 0.0 and (distance < 420.0 or hp_ratio < 0.6)
		"fire_arrows":
			return distance < 480.0
		"slash":
			return distance < 320.0
		"shield":
			return enemy.shield_time <= 0.0 and (hp_ratio < 0.75 or distance < 300.0)
		"ground_slam":
			return distance < 200.0 * skill_reach()
		"bomb":
			return distance < 540.0
		"paralysis":
			return distance < 420.0
		"bomb_rain":
			return distance < 520.0
	return false


func _cast(id: String, direction: Vector2, _distance: float) -> void:
	energy -= Skills.cost_for(id)
	cooldowns[id] = skill_cooldown(id)
	_skill_gate = 0.8
	casts += 1
	last_skill = id
	var strength := skill_power(id)
	var area := skill_reach()
	var color: Color = Skills.DEFS[id]["color"]
	var origin := enemy.global_position
	var hd := float(hero["damage"])
	match id:
		"freeze":
			var zone := PvpProjectile.PvpZone.new()
			zone.player = player
			zone.radius = 170.0 * area
			zone.duration = 5.0 * strength
			zone.slow_factor = clampf(0.4 / strength, 0.2, 0.4)
			enemy.get_parent().add_child(zone)
			zone.global_position = origin
			_ring(origin, zone.radius, color)
		"fire":
			var aim := (_lead(origin, 380.0) - origin).normalized()
			var bolt := _shoot("fire", aim, (16.0 + hd * 0.5) * damage_mult * strength, 380.0, 1.6 * area * 380.0, 11.0, 0, color)
			bolt.burn_ticks = 3
			bolt.burn_damage = 8.0 * damage_mult * strength
		"wind":
			var radius := 240.0 * area
			_ring(origin, radius, color)
			if origin.distance_to(player.global_position) <= radius:
				player.take_damage(4.0 * damage_mult * strength, "hit", 0.0)
				_push_time = 0.3
		"lightning":
			for i in 3:
				var at := player.global_position + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(70.0, 150.0))
				_blast(at, 70.0 * area, 0.8 + 0.25 * i, (30.0 + hd * 1.2) * damage_mult * strength, color, "bolt")
		"double":
			double_time = 6.0 * strength
			_ring(origin, 60.0 * area, color)
		"haste":
			haste_time = 6.0 * strength
			_ring(origin, 70.0 * area, color)
		"fire_arrows":
			var aim := (_lead(origin, 700.0) - origin).normalized()
			for i in 5:
				var arrow := _shoot("fire_arrow", aim.rotated(lerpf(-0.34, 0.34, i / 4.0)), hd * 1.4 * damage_mult * strength, 700.0, 0.9 * area * 700.0, 6.0, 1, color)
				arrow.burn_ticks = 3
				arrow.burn_damage = 6.0 * damage_mult * strength
		"slash":
			for i in 2:
				get_tree().create_timer(Skills.SLASH_GAP * i).timeout.connect(func() -> void:
					if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
						var aim := (player.global_position - enemy.global_position).normalized()
						_shoot("slash", aim, hd * 2.0 * damage_mult * strength, 520.0, 270.0 * area, 34.0, 999, color))
		"shield":
			enemy.shield_time = 6.0
			_ring(origin, 60.0 * area, color)
		"ground_slam":
			var crack := CrackEffect.new()
			crack.radius = 230.0 * area
			enemy.get_parent().add_child(crack)
			crack.global_position = origin
			var slam := _blast(origin, 230.0 * area, 0.6, hd * 3.0 * damage_mult * strength, color, "")
			slam.slow_factor = 0.25
			slam.slow_time = 1.0
		"bomb":
			var bomb := _blast(_lead(origin, 400.0), 120.0 * area, 0.55, (40.0 + hd * 1.5) * damage_mult * strength, color, "bomb")
			bomb.burn_ticks = 6
			bomb.burn_damage = 8.0 * damage_mult * strength
		"paralysis":
			var flask := _blast(_lead(origin, 400.0), 140.0 * area, 0.55, 0.0, color, "flask")
			flask.slow_factor = 0.05
			flask.slow_time = 2.0 * (1.0 + (strength - 1.0) * 0.5)
		"bomb_rain":
			for i in 5:
				var spot := player.global_position + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(60.0, 170.0))
				var rain := _blast(spot, 120.0 * area, 0.55 + 0.12 * i, (40.0 + hd * 1.5) * damage_mult * strength, color, "bomb")
				rain.burn_ticks = 6
				rain.burn_damage = 8.0 * damage_mult * strength


func _blast(at: Vector2, radius: float, delay: float, damage: float, color: Color, falling: String) -> PvpProjectile.PvpBlast:
	var blast := PvpProjectile.PvpBlast.new()
	blast.player = player
	blast.radius = radius
	blast.delay = delay
	blast.damage = damage
	blast.color = color
	blast.falling = falling
	enemy.get_parent().add_child(blast)
	blast.global_position = at
	return blast


func _ring(at: Vector2, radius: float, color: Color) -> void:
	var ring := RingEffect.new()
	ring.radius = radius
	ring.color = color
	ring.duration = 0.4
	enemy.get_parent().add_child(ring)
	ring.global_position = at
