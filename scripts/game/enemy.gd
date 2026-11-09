class_name Enemy
extends Node2D

## Inimigo. `kind` (ver EnemyTypes) escolhe o comportamento:
## slime se divide, bat voa em zigue-zague, skeleton atira ossos, spider cospe
## teias, bomber explode em área, wolf avisa e investe, brute ignora empurrões
## e reduz o dano, ghost alterna entre sólido e etéreo, mushroom solta nuvens
## venenosas e necromancer invoca caveirinhas (skull).

const PUSH_DECAY := 1300.0
const BOMB_RADIUS := 110.0
const BOMB_FUSE := 0.8
const BOMB_TRIGGER := 85.0
const GHOST_SOLID_TIME := 2.6
const GHOST_ETHEREAL_TIME := 1.4
const WOLF_TRIGGER_DISTANCE := 300.0
const WOLF_WINDUP := 0.6
const WOLF_DASH_TIME := 0.42
const WOLF_DASH_SPEED := 520.0
const WOLF_RECOVER := 1.0
const NECRO_SUMMON_INTERVAL := 7.0
const NECRO_MAX_MINIONS := 4
const SPORE_INTERVAL := 1.4
const THIEF_FLEE_TIME := 7.0
const SHADE_VANISH := 0.45
const SHADE_TELEGRAPH := 0.6
const SHADE_STRIKE_RADIUS := 58.0
const TOTEM_INTERVAL := 3.2
const TOTEM_RADIUS := 180.0
const TOTEM_HEAL := 0.2
const TOTEM_SHIELD := 2.5
const VORTEX_RADIUS := 300.0
const VORTEX_PULL := 120.0
const MIMIC_WAKE := 88.0
const MIMIC_WINDUP := 0.45
const BOSS_SLAM_INTERVAL := 6.0
const BOSS_SLAM_TELEGRAPH := 0.8
const BOSS_SLAM_RADIUS := 150.0
## Os monstros andam um pouco mais rápido.
const ENEMY_SPEED_MULT := 1.08
## Todo golpe tira pelo menos 1% da vida do herói; os chefes, 6%; a bomba-viva, 30%.
const MIN_FRACTION := 0.01
const BOSS_MIN_FRACTION := 0.06
const BOMB_MIN_FRACTION := 0.30
## Dano base dos projéteis dos inimigos à distância (era 9): quem atira de longe obriga o herói a se mexer.
const RANGED_DAMAGE := 18.0
## Quanto maior, menos a defesa do inimigo reduz o dano (defesa = K reduz pela metade).
const DEFENSE_K := 80.0
## Chefes andam mais rápido e, além da pancada, soltam uma rajada de projéteis em anel.
const BOSS_SPEED_MULT := 1.25
const BOSS_VOLLEY_INTERVAL := 5.0
const BOSS_VOLLEY_SHOTS := 8
## Quanto do dano passa quando o inimigo bloqueia.
const BLOCK_MULT := 0.35
## Velocidade do empurrão que o golpe crítico dá no inimigo (px/s; ele desliza ~80 px).
const CRIT_KNOCKBACK := 460.0
## Quanto a barra de vida sobe para não ficar atrás de chifres, capuz ou chapéu.
const BAR_LIFT := {"bat": 0.9, "brute": 0.6, "necromancer": 0.5, "mushroom": 0.6, "thief": 0.6, "totem": 0.5, "shade": 0.5}

var kind := "slime"
var speed := 70.0
var max_health := 20.0
var contact_damage := 8.0
var xp_value := 1
var radius := 14.0
var color := Color("8b2e2e")
var target: Player
var health := 0.0
var generation := 0
var loot := true
var knockback_immune := false
var damage_taken_mult := 1.0
## Defesa: reduz o dano recebido (ver DEFENSE_K). Vem da fase (ver Game._spawn_one).
var defense := 0.0
var shot_damage := 9.0
## Chance de esquivar do golpe (nenhum dano) e de bloqueá-lo (só 35% do dano). Vêm do tipo.
var dodge_chance := 0.0
var block_chance := 0.0
var explode_damage := 22.0
var _hp_scale := 1.0
var _dmg_scale := 1.0
var _contact_cooldown := 0.0
var _hit_flash := 0.0
var _slow_factor := 1.0
var _slow_time := 0.0
var _stun_time := 0.0
var _burn_ticks := 0
var _burn_damage := 0.0
var _burn_timer := 0.0
var _poison_ticks := 0
var _poison_damage := 0.0
var _poison_timer := 0.0
## Quem causou o atordoamento atual: "stun" (golpe) ou "paralysis" (poção); muda o ícone.
var _stun_cause := "stun"
var _push := Vector2.ZERO
var _clock := randf() * 10.0
var _shot_timer := 1.2
var _fuse := -1.0
var _strafe := 1.0
var _face := 1.0
var _ethereal := false
var _phase_time := randf() * 2.0
var _wolf_state := "chase"
var _wolf_time := 1.2
var _wolf_dir := Vector2.RIGHT
var _summon_timer := 3.5
var _minions: Array = []
var _spore_timer := 0.8
## Elite e chefe: `treasure` é a quantidade de itens que soltam ao morrer.
var is_elite := false
var is_boss := false
## Mini chefe: um elite gigante que também dá a pancada em área do chefe.
var is_mini := false
var display_name := ""
var treasure := 0
var shield_time := 0.0
var stolen_gold := 0
var _thief_state := "chase"
var _thief_time := 0.0
var _shade_state := "stalk"
var _shade_time := 3.0
var _shade_alpha := 0.6
var _totem_timer := 1.5
var _totem_flash := 0.0
var _mimic_awake := false
var _mimic_windup := 0.0
var _mimic_sleep := 25.0
var _boss_timer := 5.0
var _boss_telegraph := -1.0
var _boss_power := 1.0
var _boss_volley := 3.5
## Estado das habilidades dos monstros novos (cada um usa só o que precisa).
var _ab_state := ""
var _ab_time := 2.0
var _ab_dir := Vector2.ZERO
var _ab_marks: Array = []
var _ab_gate := 3
var _burrowed := false
var _scream_push := 0.0
const GOLEM_WINDUP := 0.9
const GOLEM_RADIUS := 140.0
const STORM_DELAY := 0.9
const STORM_RADIUS := 52.0
const SCREAM_WINDUP := 0.9
const SCREAM_RADIUS := 270.0
const WORM_DIG_TIME := 1.5
const WORM_BLAST_RADIUS := 85.0
const GARGOYLE_STONE_TIME := 2.2
const GARGOYLE_DIVE_TIME := 1.6


## Aplica os atributos do tipo, escalados pelo tempo de partida (ou pelas escalas da fase).
func setup(enemy_kind: String, elapsed: float, hp_scale := -1.0, dmg_scale := -1.0) -> void:
	kind = enemy_kind
	var data := EnemyTypes.get_type(kind)
	_hp_scale = hp_scale if hp_scale > 0.0 else 1.0 + elapsed / 50.0
	_dmg_scale = dmg_scale if dmg_scale > 0.0 else 1.0 + elapsed / 160.0
	max_health = data["health"] * _hp_scale
	radius = data["radius"]
	speed = data["speed"] * ENEMY_SPEED_MULT
	color = data["color"]
	xp_value = data["xp"]
	loot = data.get("loot", true)
	contact_damage = data["damage"] * _dmg_scale
	shot_damage = RANGED_DAMAGE * _dmg_scale
	explode_damage = 22.0 * _dmg_scale
	knockback_immune = data.get("knockback_immune", false)
	damage_taken_mult = data.get("damage_taken_mult", 1.0)
	dodge_chance = data.get("dodge", 0.0)
	block_chance = data.get("block", 0.0)
	_strafe = 1.0 if randf() < 0.5 else -1.0
	_mimic_windup = 0.0
	if kind == "mimic":
		treasure = 2
		_mimic_sleep = 25.0


## Vira elite (mais forte, dourado, solta tesouro) ou chefe (enorme, com golpe em área e muito tesouro).
func promote(mode: String, hp_mult := 4.0, size := 1.35, damage_mult := 1.4, boss_name := "") -> void:
	max_health *= hp_mult
	health = max_health
	contact_damage *= damage_mult
	shot_damage *= damage_mult
	explode_damage *= damage_mult
	radius *= size
	xp_value *= {"elite": 4, "miniboss": 8}.get(mode, 12)
	is_mini = mode == "miniboss"
	is_elite = mode == "elite" or is_mini
	is_boss = mode == "boss"
	display_name = boss_name
	treasure += 4 if is_boss else (2 if is_mini else 1)
	knockback_immune = knockback_immune or is_boss or is_mini
	if is_boss:
		speed *= BOSS_SPEED_MULT
	block_chance = minf(block_chance + (0.12 if is_boss else (0.08 if is_mini else 0.05)), 0.5)
	_boss_power = size
	if kind == "slime":
		generation = 0


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_population += 1


func _physics_process(delta: float) -> void:
	_clock += delta
	_tick_status(delta)
	if is_queued_for_deletion() or target == null:
		return
	if _stun_time > 0.0:
		_stun_time -= delta
		queue_redraw()
		return
	_contact_cooldown -= delta
	var offset := target.global_position - global_position
	var distance := offset.length()
	var direction := offset / maxf(distance, 0.001)
	if absf(direction.x) > 0.15:
		_face = signf(direction.x)
	match kind:
		"bat":
			_move_bat(direction, delta)
		"skeleton":
			_move_keeping_distance(direction, distance, delta, 220.0, 330.0)
			_tick_shots(delta, distance, direction, "bone", 2.2)
		"spider":
			_move_keeping_distance(direction, distance, delta, 240.0, 340.0)
			_tick_shots(delta, distance, direction, "web", 3.0)
			queue_redraw()
		"necromancer":
			_move_keeping_distance(direction, distance, delta, 280.0, 390.0)
			_tick_summon(delta)
		"bomber":
			_move_bomber(direction, distance, delta)
		"wolf":
			_move_wolf(direction, distance, delta)
		"mushroom":
			_move_chase(direction, distance, delta)
			_tick_spores(delta)
		"thief":
			_move_thief(direction, distance, delta)
		"shade":
			_move_shade(direction, distance, delta)
		"totem":
			_move_keeping_distance(direction, distance, delta, 260.0, 380.0)
			_tick_totem(delta)
		"vortex":
			_move_vortex(direction, distance, delta)
		"mimic":
			_move_mimic(direction, distance, delta)
		"frost":
			_move_keeping_distance(direction, distance, delta, 230.0, 340.0)
			_tick_shots(delta, distance, direction, "ice", 2.8)
		"golem":
			_move_golem(direction, distance, delta)
		"imp":
			_move_chase(direction, distance, delta)
			_tick_embers(delta)
		"illusionist":
			_move_illusionist(direction, distance, delta)
		"storm":
			_move_keeping_distance(direction, distance, delta, 250.0, 380.0)
			_tick_storm(delta, distance)
		"banshee":
			_move_keeping_distance(direction, distance, delta, 200.0, 330.0)
			_tick_scream(delta, distance)
		"gargoyle":
			_move_gargoyle(direction, distance, delta)
		"worm":
			_move_worm(direction, distance, delta)
		_:
			_move_chase(direction, distance, delta)
	if shield_time > 0.0:
		shield_time -= delta
	if is_boss or is_mini:
		_tick_boss(delta)
	if is_elite or is_boss:
		queue_redraw()
	if is_queued_for_deletion():
		return
	if _is_disguised() or _burrowed or (kind == "shade" and _shade_state != "stalk"):
		return
	if contact_damage > 0.0 and distance <= target.radius + radius and _contact_cooldown <= 0.0:
		target.take_damage(contact_damage, "hit", _min_hit_fraction(), true)
		_contact_cooldown = 0.6
		if kind == "vampire":
			health = minf(max_health, health + max_health * 0.12)


func _tick_status(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash -= delta
		queue_redraw()
	if kind == "ghost":
		_phase_time += delta
		var limit := GHOST_ETHEREAL_TIME if _ethereal else GHOST_SOLID_TIME
		if _phase_time >= limit:
			_phase_time = 0.0
			_ethereal = not _ethereal
		queue_redraw()
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow_factor = 1.0
			queue_redraw()
	if _poison_ticks > 0:
		_poison_timer -= delta
		if _poison_timer <= 0.0:
			_poison_timer += 1.0
			_poison_ticks -= 1
			take_damage(_poison_damage, "dot")
			if is_queued_for_deletion():
				return
			queue_redraw()
	if _burn_ticks > 0:
		_burn_timer -= delta
		if _burn_timer <= 0.0:
			_burn_timer += 1.0
			_burn_ticks -= 1
			take_damage(_burn_damage, "dot")
			if is_queued_for_deletion():
				return
			queue_redraw()
	if _push.length() > 1.0:
		global_position += _push * delta
		_push = _push.move_toward(Vector2.ZERO, PUSH_DECAY * delta)


# --- Movimento por tipo -----------------------------------------------------

func _move_chase(direction: Vector2, distance: float, delta: float) -> void:
	if distance > target.radius + radius:
		global_position += direction * speed * _slow_factor * delta


## Morcego: avança de lado para lado, em zigue-zague.
func _move_bat(direction: Vector2, delta: float) -> void:
	var sideways := Vector2(-direction.y, direction.x) * sin(_clock * 7.0)
	global_position += (direction * 0.8 + sideways * 0.9) * speed * _slow_factor * delta
	queue_redraw()


## Esqueleto, aranha e necromante: aproximam se estiverem longe, recuam se
## estiverem perto e, no meio, andam de lado.
func _move_keeping_distance(direction: Vector2, distance: float, delta: float, near: float, far: float) -> void:
	var step := Vector2.ZERO
	if distance > far:
		step = direction
	elif distance < near:
		step = -direction
	else:
		step = Vector2(-direction.y, direction.x) * _strafe * 0.5
	global_position += step * speed * _slow_factor * delta


## Esqueleto atira ossos; a aranha cospe teias.
func _tick_shots(delta: float, distance: float, direction: Vector2, shot_kind: String, interval: float) -> void:
	_shot_timer -= delta
	if _shot_timer <= 0.0 and distance < 560.0:
		_shot_timer = interval + randf() * 0.6
		_shoot(direction, shot_kind)


func _shoot(direction: Vector2, shot_kind: String) -> void:
	var shot := EnemyShot.new()
	shot.kind = shot_kind
	shot.target = target
	shot.min_fraction = _min_hit_fraction()
	if shot_kind == "web":
		shot.damage = RANGED_DAMAGE * 0.4 * _dmg_scale
		shot.velocity = direction * 230.0
	elif shot_kind == "ice":
		shot.damage = RANGED_DAMAGE * 0.55 * _dmg_scale
		shot.velocity = direction * 250.0
	else:
		shot.damage = shot_damage
		shot.velocity = direction * 270.0
	get_parent().add_child(shot)
	shot.global_position = global_position


## Bomba-viva: corre até o herói, para, pisca e explode em área.
func _move_bomber(direction: Vector2, distance: float, delta: float) -> void:
	if _fuse >= 0.0:
		_fuse -= delta
		queue_redraw()
		if _fuse <= 0.0:
			_explode()
		return
	if distance < BOMB_TRIGGER:
		_fuse = BOMB_FUSE
		return
	global_position += direction * speed * _slow_factor * delta


func _explode() -> void:
	if target.global_position.distance_to(global_position) <= BOMB_RADIUS + target.radius:
		target.take_damage(explode_damage, "hit", BOMB_MIN_FRACTION, true)
	var ring := RingEffect.new()
	ring.radius = BOMB_RADIUS
	ring.color = Color("ff5a3c")
	ring.duration = 0.35
	get_parent().add_child(ring)
	ring.global_position = global_position
	EventBus.impact.emit(7.0, 0.0)
	# Explodir sozinha não conta como abate e não solta nada.
	remove_from_group("enemies")
	queue_free()


## Lobo: persegue, avisa com uma linha vermelha, investe em linha reta e descansa.
func _move_wolf(direction: Vector2, distance: float, delta: float) -> void:
	_wolf_time -= delta
	match _wolf_state:
		"chase":
			if distance > target.radius + radius:
				global_position += direction * speed * _slow_factor * delta
			if _wolf_time <= 0.0 and distance < WOLF_TRIGGER_DISTANCE:
				_wolf_state = "windup"
				_wolf_time = WOLF_WINDUP
		"windup":
			_wolf_dir = direction
			queue_redraw()
			if _wolf_time <= 0.0:
				_wolf_state = "dash"
				_wolf_time = WOLF_DASH_TIME
		"dash":
			global_position += _wolf_dir * WOLF_DASH_SPEED * delta
			if _wolf_time <= 0.0:
				_wolf_state = "recover"
				_wolf_time = WOLF_RECOVER
				queue_redraw()
		"recover":
			if distance > target.radius + radius:
				global_position += direction * speed * 0.4 * _slow_factor * delta
			if _wolf_time <= 0.0:
				_wolf_state = "chase"
				_wolf_time = 1.4


## Necromante: de tempos em tempos invoca duas caveirinhas (no máximo 4 vivas).
func _tick_summon(delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = NECRO_SUMMON_INTERVAL
		summon_minions()


func summon_minions() -> void:
	_minions = _minions.filter(func(minion) -> bool:
		return is_instance_valid(minion) and not minion.is_queued_for_deletion())
	if _minions.size() >= NECRO_MAX_MINIONS:
		return
	for side in [-1.0, 1.0]:
		var skull := Enemy.new()
		skull.target = target
		skull.setup("skull", (_hp_scale - 1.0) * 50.0)
		skull.position = position + Vector2(side * 32.0, 10.0)
		_minions.append(skull)
		get_parent().add_child.call_deferred(skull)
	var ring := RingEffect.new()
	ring.radius = 60.0
	ring.color = Color("7dff7a")
	ring.duration = 0.35
	get_parent().add_child(ring)
	ring.global_position = global_position


## Cogumelo: deixa uma nuvem venenosa no chão a cada instante.
func _tick_spores(delta: float) -> void:
	_spore_timer -= delta
	if _spore_timer <= 0.0:
		_spore_timer = SPORE_INTERVAL
		_drop_cloud(52.0, 5.0, 8.0 * _dmg_scale)


func _drop_cloud(cloud_radius: float, duration: float, damage_per_second: float) -> void:
	var cloud := PoisonCloud.new()
	cloud.target = target
	cloud.radius = cloud_radius
	cloud.duration = duration
	cloud.damage_per_second = damage_per_second
	get_parent().add_child(cloud)
	cloud.global_position = global_position


# --- Inimigos novos ---------------------------------------------------------

func _is_disguised() -> bool:
	return kind == "mimic" and not _mimic_awake


func _ring(ring_radius: float, ring_color: Color, seconds := 0.35) -> void:
	var ring := RingEffect.new()
	ring.radius = ring_radius
	ring.color = ring_color
	ring.duration = seconds
	get_parent().add_child(ring)
	ring.global_position = global_position


## Ladrão: corre até o herói, rouba parte do ouro ao encostar e foge. Se escapar, o ouro se perde;
## se for morto, devolve tudo com juros.
func _move_thief(direction: Vector2, distance: float, delta: float) -> void:
	if _thief_state == "chase":
		global_position += direction * speed * _slow_factor * delta
		if distance <= target.radius + radius + 4.0:
			_steal()
		return
	_thief_time -= delta
	global_position -= direction * speed * 1.3 * _slow_factor * delta
	queue_redraw()
	if _thief_time <= 0.0:
		EventBus.thief_escaped.emit(stolen_gold)
		remove_from_group("enemies")
		queue_free()


func _steal() -> void:
	var gold: int = target.inventory.gold
	var amount := mini(gold, maxi(8, int(gold * 0.12)))
	if amount > 0:
		target.inventory.add_gold(-amount)
	stolen_gold = amount
	_thief_state = "flee"
	_thief_time = THIEF_FLEE_TIME
	EventBus.gold_stolen.emit(amount)
	queue_redraw()


## Sombra: persegue meio invisível, some, reaparece nas costas do herói, avisa e golpeia.
func _move_shade(direction: Vector2, distance: float, delta: float) -> void:
	_shade_time -= delta
	match _shade_state:
		"stalk":
			_shade_alpha = move_toward(_shade_alpha, 0.65, delta * 2.0)
			global_position += direction * speed * _slow_factor * delta
			if _shade_time <= 0.0 and distance < 420.0:
				_shade_state = "vanish"
				_shade_time = SHADE_VANISH
				_ethereal = true
		"vanish":
			_shade_alpha = maxf(_shade_alpha - delta * 4.0, 0.0)
			if _shade_time <= 0.0:
				var behind := -target.facing if target.facing != Vector2.ZERO else Vector2.LEFT
				global_position = target.global_position + behind * 85.0
				_shade_state = "telegraph"
				_shade_time = SHADE_TELEGRAPH
				_ethereal = false
		"telegraph":
			_shade_alpha = move_toward(_shade_alpha, 1.0, delta * 3.0)
			if _shade_time <= 0.0:
				_shade_strike()
				_shade_state = "recover"
				_shade_time = 0.6
		"recover":
			if _shade_time <= 0.0:
				_shade_state = "stalk"
				_shade_time = 3.2 + randf() * 1.5
	modulate.a = _shade_alpha
	queue_redraw()


func _shade_strike() -> void:
	if target.global_position.distance_to(global_position) <= SHADE_STRIKE_RADIUS + target.radius:
		target.take_damage(contact_damage * 1.6, "hit", _min_hit_fraction(), true)
	_ring(SHADE_STRIKE_RADIUS, Color("ff4ad8"), 0.25)
	EventBus.impact.emit(4.0, 0.0)


## Totem: de tempos em tempos cura e protege (metade do dano) os monstros por perto.
func _tick_totem(delta: float) -> void:
	_totem_timer -= delta
	_totem_flash = maxf(_totem_flash - delta, 0.0)
	queue_redraw()
	if _totem_timer > 0.0:
		return
	_totem_timer = TOTEM_INTERVAL
	_totem_flash = 0.5
	for node in get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		if other == null or other == self or other.is_queued_for_deletion():
			continue
		if other.global_position.distance_to(global_position) <= TOTEM_RADIUS:
			other.health = minf(other.max_health, other.health + other.max_health * TOTEM_HEAL)
			other.shield_time = TOTEM_SHIELD
			other.queue_redraw()
	_ring(TOTEM_RADIUS, Color("5fe0a0"), 0.5)


## Vórtice: flutua até perto do herói e orbita; dentro do raio, puxa o herói para si.
func _move_vortex(direction: Vector2, distance: float, delta: float) -> void:
	if distance > 170.0:
		global_position += direction * speed * _slow_factor * delta
	else:
		global_position += Vector2(-direction.y, direction.x) * _strafe * speed * 0.6 * _slow_factor * delta
	if distance < VORTEX_RADIUS:
		var strength := 0.35 + (1.0 - distance / VORTEX_RADIUS)
		target.add_pull((global_position - target.global_position).normalized() * VORTEX_PULL * strength)
	queue_redraw()


## Mímico: parado e disfarçado de tesouro até o herói chegar perto (ou passar o tempo): treme e ataca.
func _move_mimic(direction: Vector2, distance: float, delta: float) -> void:
	if not _mimic_awake:
		_mimic_sleep -= delta
		queue_redraw()
		if distance <= MIMIC_WAKE or _mimic_sleep <= 0.0:
			wake_up()
		return
	if _mimic_windup > 0.0:
		_mimic_windup -= delta
		queue_redraw()
		return
	global_position += direction * speed * _slow_factor * delta


## Acorda o mímico (chamado ao chegar perto, ao levar dano ou quando a fase pede).
func wake_up() -> void:
	if kind != "mimic" or _mimic_awake:
		return
	_mimic_awake = true
	_mimic_windup = MIMIC_WINDUP
	_ring(60.0, Color("ffb02e"), 0.3)
	queue_redraw()


## Chefe: de tempos em tempos marca o chão (círculo vermelho) e dá uma pancada em área.
func _tick_boss(delta: float) -> void:
	if is_boss:
		_boss_volley -= delta
		if _boss_volley <= 0.0:
			_boss_volley = BOSS_VOLLEY_INTERVAL * (0.7 if health < max_health * 0.5 else 1.0)
			_boss_fire_ring()
	if _boss_telegraph >= 0.0:
		_boss_telegraph -= delta
		queue_redraw()
		if _boss_telegraph < 0.0:
			_boss_slam()
		return
	_boss_timer -= delta
	if _boss_timer <= 0.0:
		_boss_timer = BOSS_SLAM_INTERVAL * (0.65 if health < max_health * 0.5 else 1.0)
		_boss_telegraph = BOSS_SLAM_TELEGRAPH


## Rajada em anel: o chefe cospe projéteis para todos os lados (mais deles com menos da metade da vida).
func _boss_fire_ring() -> void:
	var count := BOSS_VOLLEY_SHOTS + (4 if health < max_health * 0.5 else 0)
	var offset := randf() * TAU
	for i in count:
		_shoot(Vector2.from_angle(offset + TAU * float(i) / float(count)), "bone")


func _boss_reach() -> float:
	return BOSS_SLAM_RADIUS * (0.7 + _boss_power * 0.3)


func _boss_slam() -> void:
	var reach := _boss_reach()
	if target.global_position.distance_to(global_position) <= reach + target.radius:
		target.take_damage(contact_damage * 1.8, "hit", BOSS_MIN_FRACTION, true)
	_ring(reach, Color("ff5a3c"), 0.4)
	EventBus.impact.emit(12.0, 0.0)
	if kind == "necromancer":
		summon_minions()
	queue_redraw()


# --- Habilidades dos monstros novos ----------------------------------------

## Diabrete: deixa brasas no chão.
func _tick_embers(delta: float) -> void:
	_spore_timer -= delta
	if _spore_timer <= 0.0:
		_spore_timer = 0.55
		var ember := PoisonCloud.new()
		ember.target = target
		ember.radius = 30.0
		ember.duration = 3.0
		ember.damage_per_second = 9.0 * _dmg_scale
		ember.tint = Color(1.0, 0.45, 0.15)
		get_parent().add_child(ember)
		ember.global_position = global_position


## Golem: anda devagar; de tempos em tempos marca o chão e bate o punho.
func _move_golem(direction: Vector2, distance: float, delta: float) -> void:
	_ab_time -= delta
	if _ab_state == "windup":
		queue_redraw()
		if _ab_time <= 0.0:
			_ab_state = ""
			_ab_time = 4.5
			if target.global_position.distance_to(global_position) <= GOLEM_RADIUS + target.radius:
				target.take_damage(contact_damage * 1.5, "hit", _min_hit_fraction(), true)
				target.apply_slow(0.55, 2.0)
			_ring(GOLEM_RADIUS, Color("c9b48a"), 0.45)
			EventBus.impact.emit(10.0, 0.0)
		return
	_move_chase(direction, distance, delta)
	if _ab_time <= 0.0 and distance < GOLEM_RADIUS + 150.0:
		_ab_state = "windup"
		_ab_time = GOLEM_WINDUP


## Ilusionista: foge para outro ponto e deixa caveirinhas no lugar.
func _move_illusionist(direction: Vector2, distance: float, delta: float) -> void:
	_move_keeping_distance(direction, distance, delta, 200.0, 320.0)
	_ab_time -= delta
	if _ab_time <= 0.0:
		_ab_time = 5.5
		_ring(radius * 2.5, Color("d46bd8"), 0.4)
		summon_minions()
		global_position = target.global_position + Vector2.from_angle(randf() * TAU) * 260.0
		_ring(radius * 2.5, Color("d46bd8"), 0.4)


## Elemental: marca três pontos no chão (o primeiro sob o herói) e chama um raio em cada.
func _tick_storm(delta: float, distance: float) -> void:
	_ab_time -= delta
	if _ab_time <= 0.0 and distance < 620.0:
		_ab_time = 5.5
		_ab_marks.append([target.global_position, STORM_DELAY])
		for i in 2:
			_ab_marks.append([target.global_position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 130.0), STORM_DELAY + 0.35 * (i + 1)])
	if _ab_marks.is_empty():
		return
	var remaining: Array = []
	for mark in _ab_marks:
		mark[1] -= delta
		if mark[1] > 0.0:
			remaining.append(mark)
			continue
		var ring := RingEffect.new()
		ring.radius = STORM_RADIUS
		ring.color = Color("fff07a")
		ring.duration = 0.3
		get_parent().add_child(ring)
		ring.global_position = mark[0]
		if target.global_position.distance_to(mark[0]) <= STORM_RADIUS + target.radius:
			target.take_damage(shot_damage * 1.4, "hit", _min_hit_fraction())
	_ab_marks = remaining
	queue_redraw()


## Ouriço: a cada quarto da vida perdido, dispara um anel de espinhos.
func _check_spikes() -> void:
	if _ab_gate > 0 and health <= max_health * 0.25 * _ab_gate:
		_ab_gate -= 1
		var offset := randf() * TAU
		for i in 10:
			_shoot(Vector2.from_angle(offset + TAU * float(i) / 10.0), "bone")
		_ring(radius * 2.2, Color("c9a06a"), 0.35)


## Banshee: respira fundo (círculo no chão) e grita: dano, lentidão e empurrão.
func _tick_scream(delta: float, distance: float) -> void:
	if _scream_push > 0.0:
		_scream_push -= delta
		target.add_pull((target.global_position - global_position).normalized() * 520.0)
	_ab_time -= delta
	if _ab_state == "windup":
		queue_redraw()
		if _ab_time <= 0.0:
			_ab_state = ""
			_ab_time = 6.0
			_ring(SCREAM_RADIUS, Color("e6e6ff"), 0.5)
			if distance <= SCREAM_RADIUS + target.radius:
				target.take_damage(shot_damage * 0.7, "hit", _min_hit_fraction())
				target.apply_slow(0.5, 3.0)
				_scream_push = 0.35
		return
	if _ab_time <= 0.0 and distance < SCREAM_RADIUS + 80.0:
		_ab_state = "windup"
		_ab_time = SCREAM_WINDUP


## Gárgula: pedra (quase invulnerável e parada) alterna com mergulhos rápidos.
func _move_gargoyle(direction: Vector2, _distance: float, delta: float) -> void:
	_ab_time -= delta
	if _ab_state == "":
		_ab_state = "stone"
		_ab_time = GARGOYLE_STONE_TIME
	if _ab_state == "stone":
		damage_taken_mult = 0.1
		queue_redraw()
		if _ab_time <= 0.0:
			_ab_state = "dive"
			_ab_time = GARGOYLE_DIVE_TIME
			damage_taken_mult = 1.0
			_ab_dir = direction
			_ring(radius * 2.0, Color("b0b4c2"), 0.3)
		return
	if _ab_time > GARGOYLE_DIVE_TIME * 0.5:
		_ab_dir = direction
	global_position += _ab_dir * speed * 2.6 * _slow_factor * delta
	if _ab_time <= 0.0:
		_ab_state = "stone"
		_ab_time = GARGOYLE_STONE_TIME
	queue_redraw()


## Verme: caminha, mergulha (intocável, rápido) e explode da terra sob o herói.
func _move_worm(direction: Vector2, distance: float, delta: float) -> void:
	_ab_time -= delta
	if _ab_state == "":
		_ab_state = "walk"
		_ab_time = 3.2
	if _ab_state == "walk":
		_move_chase(direction, distance, delta)
		if _ab_time <= 0.0 and distance > 120.0:
			_ab_state = "dig"
			_ab_time = WORM_DIG_TIME
			_burrowed = true
			_ring(radius * 2.0, Color("c99a5a"), 0.3)
			queue_redraw()
		return
	global_position += direction * speed * 2.6 * _slow_factor * delta
	queue_redraw()
	if _ab_time <= 0.0 or distance < 40.0:
		_burrowed = false
		_ab_state = "walk"
		_ab_time = 3.4
		_ring(WORM_BLAST_RADIUS, Color("e0b878"), 0.4)
		if target.global_position.distance_to(global_position) <= WORM_BLAST_RADIUS + target.radius:
			target.take_damage(contact_damage * 1.6, "hit", _min_hit_fraction(), true)
			target.apply_slow(0.6, 1.5)
		EventBus.impact.emit(8.0, 0.0)
		queue_redraw()


# --- Desenho ----------------------------------------------------------------

## Desenho dos monstros novos: corpo simples com o traço que lembra a habilidade.
func _draw_new_kind(fill: Color) -> void:
	var r := radius
	if kind == "worm" and _burrowed:
		draw_circle(Vector2(0, 4), r * 1.1, Color("5a4630", 0.85))
		for i in 6:
			var a := TAU * i / 6.0 + _clock * 5.0
			draw_circle(Vector2.from_angle(a) * r * 0.9 + Vector2(0, 4), 3.0, Color("c99a5a"))
		return
	draw_circle(Vector2.ZERO, r + 2.0, Brand.NIGHT)
	draw_circle(Vector2.ZERO, r, fill)
	match kind:
		"frost":
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(side * r * 0.6, -r * 0.2), Vector2(side * r * 1.8, -r * 1.1), Vector2(side * r * 1.1, r * 0.4)]), Color("d8f6ff", 0.8))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -r * 1.7), Vector2(r * 0.35, -r), Vector2(-r * 0.35, -r)]), Color("d8f6ff"))
			_eyes(-r * 0.1, r * 0.4, 2.5, Color("1b5a7a"))
		"golem":
			draw_rect(Rect2(-r * 0.8, -r * 0.6, r * 1.6, r * 0.5), Color("5a564c"))
			draw_circle(Vector2(-r * 0.35, -r * 0.35), 3.0, Color("ffb02e"))
			draw_circle(Vector2(r * 0.35, -r * 0.35), 3.0, Color("ffb02e"))
			draw_line(Vector2(-r * 0.5, r * 0.3), Vector2(r * 0.2, r * 0.7), Color("5a564c"), 3.0)
			if _ab_state == "windup":
				var progress := 1.0 - _ab_time / GOLEM_WINDUP
				draw_circle(Vector2.ZERO, GOLEM_RADIUS, Color(1.0, 0.3, 0.1, 0.08 + 0.12 * progress))
				draw_arc(Vector2.ZERO, GOLEM_RADIUS * progress, 0.0, TAU, 36, Color("ff6a4a"), 3.0)
				draw_arc(Vector2.ZERO, GOLEM_RADIUS, 0.0, TAU, 36, Color("ff6a4a", 0.7), 2.0)
		"imp":
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(side * r * 0.4, -r * 0.7), Vector2(side * r * 0.9, -r * 1.6), Vector2(side * r * 1.0, -r * 0.5)]), Color("c9300e"))
			_eyes(-r * 0.1, r * 0.4, 2.5, Color("ffe85a"))
			draw_circle(Vector2(0, r * 1.1), 3.0 + sin(_clock * 12.0), Color("ffb02e"))
		"vampire":
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 1.6, r * 0.9), Vector2(-r * 0.7, -r * 0.4), Vector2(r * 0.7, -r * 0.4), Vector2(r * 1.6, r * 0.9), Vector2(0, r * 0.5)]), Color("2b0a14", 0.9))
			_eyes(-r * 0.15, r * 0.4, 2.5, Color("ff5a5a"))
			draw_line(Vector2(-r * 0.2, r * 0.25), Vector2(-r * 0.2, r * 0.55), Color.WHITE, 2.0)
			draw_line(Vector2(r * 0.2, r * 0.25), Vector2(r * 0.2, r * 0.55), Color.WHITE, 2.0)
		"illusionist":
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.8, -r * 0.5), Vector2(0, -r * 2.0), Vector2(r * 0.8, -r * 0.5)]), Color("5a1a6a"))
			draw_circle(Vector2(0, -r * 1.2), 2.5, Color("ffe85a"))
			_eyes(0.0, r * 0.4, 2.5, Color("ffffff"))
		"storm":
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.2, -r * 1.2), Vector2(r * 0.5, -r * 0.2), Vector2(0, -r * 0.1), Vector2(r * 0.3, r * 0.9), Vector2(-r * 0.5, 0.0), Vector2(0, -r * 0.05)]), Color("fffbd0"))
			for mark in _ab_marks:
				var local: Vector2 = to_local(mark[0])
				var progress := clampf(1.0 - float(mark[1]) / (STORM_DELAY + 0.7), 0.0, 1.0)
				draw_circle(local, STORM_RADIUS, Color(1.0, 0.95, 0.3, 0.1 + 0.15 * progress))
				draw_arc(local, STORM_RADIUS, 0.0, TAU, 28, Color("fff07a"), 2.5)
		"hedgehog":
			for i in 11:
				var a := PI + PI * float(i) / 10.0
				draw_line(Vector2.from_angle(a) * r * 0.8, Vector2.from_angle(a) * r * 1.5, Color("4a3a2a"), 3.0)
			_eyes(r * 0.1, r * 0.4, 2.5, Color("ffffff"))
		"banshee":
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.9, r * 0.4), Vector2(-r * 0.4, r * 1.6), Vector2(0, r * 0.9), Vector2(r * 0.4, r * 1.6), Vector2(r * 0.9, r * 0.4)]), Color(fill, 0.7))
			draw_circle(Vector2(0, r * 0.15), r * 0.28 + (r * 0.12 if _ab_state == "windup" else 0.0), Brand.NIGHT)
			draw_circle(Vector2(-r * 0.35, -r * 0.3), 2.0, Brand.NIGHT)
			draw_circle(Vector2(r * 0.35, -r * 0.3), 2.0, Brand.NIGHT)
			if _ab_state == "windup":
				var progress := 1.0 - _ab_time / SCREAM_WINDUP
				draw_arc(Vector2.ZERO, SCREAM_RADIUS * progress, 0.0, TAU, 40, Color("e6e6ff", 0.8), 3.0)
				draw_arc(Vector2.ZERO, SCREAM_RADIUS, 0.0, TAU, 40, Color("e6e6ff", 0.35), 2.0)
		"gargoyle":
			var wing := Color("4a4e5a") if _ab_state == "stone" else Color("8a90a0")
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(side * r * 0.6, -r * 0.2), Vector2(side * r * 2.0, -r * 1.0), Vector2(side * r * 1.5, r * 0.5)]), wing)
			_eyes(-r * 0.1, r * 0.4, 2.5, Color("ff6a4a") if _ab_state != "stone" else Color("2a2c34"))
		"worm":
			for i in 3:
				draw_circle(Vector2(0, r * 0.4 * (i + 1) - r), r * (0.9 - 0.15 * i), Color(fill, 0.9))
			draw_circle(Vector2.ZERO, r * 0.45, Color("3a1a0a"))

func _draw() -> void:
	_draw_shadow()
	var fill := _body_color()
	match kind:
		"bat":
			_draw_bat(fill)
		"skeleton":
			_draw_skeleton(fill)
		"spider":
			_draw_spider(fill)
		"bomber":
			_draw_bomber(fill)
		"wolf":
			_draw_wolf(fill)
		"brute":
			_draw_brute(fill)
		"ghost":
			_draw_ghost(fill)
		"mushroom":
			_draw_mushroom(fill)
		"necromancer":
			_draw_necromancer(fill)
		"skull":
			_draw_skull(fill)
		"thief":
			_draw_thief(fill)
		"shade":
			_draw_shade(fill)
		"totem":
			_draw_totem(fill)
		"vortex":
			_draw_vortex(fill)
		"mimic":
			_draw_mimic(fill)
		"frost", "golem", "imp", "vampire", "illusionist", "storm", "hedgehog", "banshee", "gargoyle", "worm":
			_draw_new_kind(fill)
		_:
			_draw_slime(fill)
	if shield_time > 0.0:
		draw_circle(Vector2.ZERO, radius * 1.3, Color("7fd8ff", 0.14))
		draw_arc(Vector2.ZERO, radius * 1.3, 0.0, TAU, 28, Color("9fe4ff", 0.85), 2.0)
	if is_elite or is_boss:
		_draw_rank()
	if _boss_telegraph >= 0.0:
		var progress := 1.0 - _boss_telegraph / BOSS_SLAM_TELEGRAPH
		draw_circle(Vector2.ZERO, _boss_reach(), Color(1.0, 0.2, 0.1, 0.1 + 0.12 * progress))
		draw_arc(Vector2.ZERO, _boss_reach() * progress, 0.0, TAU, 40, Color("ff6a4a"), 3.0)
		draw_arc(Vector2.ZERO, _boss_reach(), 0.0, TAU, 40, Color("ff6a4a", 0.7), 2.0)
	if _stun_time > 0.0:
		_draw_stun()
	if not _is_disguised() and not _burrowed:
		_draw_health_bar()
		_draw_status_icons()


## Elite e chefe: anel dourado pulsando e uma coroa sobre a barra de vida.
func _draw_rank() -> void:
	var pulse := radius * 1.3 + sin(_clock * 4.0) * 2.0
	draw_arc(Vector2.ZERO, pulse, 0.0, TAU, 36, Color("ffd24a", 0.9), 3.0 if is_boss else 2.0)
	var top := -radius - 30.0
	var s := 9.0 if is_boss else 6.5
	var crown := PackedVector2Array([
		Vector2(-s, top), Vector2(-s, top - s * 1.1), Vector2(-s * 0.5, top - s * 0.5), Vector2(0, top - s * 1.4),
		Vector2(s * 0.5, top - s * 0.5), Vector2(s, top - s * 1.1), Vector2(s, top)])
	draw_colored_polygon(crown, Color("ffd24a"))
	draw_polyline(crown + PackedVector2Array([crown[0]]), Brand.NIGHT, 1.5)
	if is_mini and display_name != "":
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 15).x
		var origin := Vector2(-width * 0.5, top - s * 1.6 - 4.0)
		draw_string_outline(font, origin, display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Brand.NIGHT)
		draw_string(font, origin, display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffb06a"))


func _draw_thief(fill: Color) -> void:
	draw_colored_polygon(_blob(1.14), Brand.NIGHT)
	draw_colored_polygon(_blob(1.0), fill)
	var hood := PackedVector2Array([
		Vector2(-radius * 0.95, -radius * 0.1), Vector2(0, -radius * 1.5), Vector2(radius * 0.95, -radius * 0.1)])
	draw_colored_polygon(hood, Color("5a3a1a"))
	draw_rect(Rect2(-radius * 0.75, -radius * 0.25, radius * 1.5, radius * 0.3), Color(Brand.NIGHT, 0.9))
	_eyes(-radius * 0.1, radius * 0.32, radius * 0.17, Brand.NIGHT)
	var bag := Vector2(-_face * radius * 0.95, radius * 0.35)
	draw_circle(bag, radius * 0.5, Brand.NIGHT)
	draw_circle(bag, radius * 0.4, Color("8a5a2a"))
	if stolen_gold > 0 or _thief_state == "flee":
		draw_circle(bag + Vector2(0, -radius * 0.55), radius * 0.28, Brand.GOLD)
		draw_arc(Vector2(0, -radius * 1.9), radius * 0.5, 0.0, TAU, 12, Color(Brand.GOLD, 0.8), 2.0)


func _draw_shade(fill: Color) -> void:
	var cloak := PackedVector2Array()
	for i in 7:
		var angle := PI + PI * i / 6.0
		cloak.append(Vector2(cos(angle), sin(angle)) * radius)
	for i in 5:
		var x := radius - i * radius * 0.5
		cloak.append(Vector2(x, radius * (1.25 if i % 2 == 0 else 0.7) + sin(_clock * 6.0 + i) * 2.0))
	var outline := PackedVector2Array()
	for point in cloak:
		outline.append(point * 1.14)
	draw_colored_polygon(outline, Color("120a22"))
	draw_colored_polygon(cloak, fill)
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(side * radius * 0.4 - 3.0, -radius * 0.3, 6.0, 3.5), Color("ff4ad8"))
	if _shade_state == "telegraph":
		var progress := 1.0 - _shade_time / SHADE_TELEGRAPH
		draw_circle(Vector2.ZERO, SHADE_STRIKE_RADIUS, Color(1.0, 0.2, 0.7, 0.12 + 0.12 * progress))
		draw_arc(Vector2.ZERO, SHADE_STRIKE_RADIUS * progress, 0.0, TAU, 28, Color("ff4ad8"), 3.0)


func _draw_totem(fill: Color) -> void:
	var pillar := Rect2(-radius * 0.7, -radius * 1.1, radius * 1.4, radius * 2.1)
	draw_rect(pillar.grow(2.5), Brand.NIGHT)
	draw_rect(pillar, fill.darkened(0.45))
	draw_rect(Rect2(pillar.position, Vector2(pillar.size.x, pillar.size.y * 0.3)), fill.darkened(0.2))
	var glow := 0.5 + 0.5 * sin(_clock * 3.0) + _totem_flash * 2.0
	for i in 3:
		var y := -radius * 0.5 + i * radius * 0.55
		draw_line(Vector2(-radius * 0.35, y), Vector2(radius * 0.35, y), Color("9fffd0", clampf(0.35 + glow * 0.4, 0.0, 1.0)), 2.5)
	draw_circle(Vector2(0, -radius * 1.35), radius * 0.4, Brand.NIGHT)
	draw_circle(Vector2(0, -radius * 1.35), radius * 0.3, Color("7dffb8").lerp(Color.WHITE, clampf(_totem_flash * 2.0, 0.0, 1.0)))
	if _totem_flash > 0.0:
		draw_arc(Vector2.ZERO, TOTEM_RADIUS * (1.0 - _totem_flash * 2.0), 0.0, TAU, 40, Color("5fe0a0", 0.5), 2.0)


func _draw_vortex(fill: Color) -> void:
	draw_arc(Vector2.ZERO, VORTEX_RADIUS, 0.0, TAU, 56, Color(fill, 0.12), 2.0)
	draw_circle(Vector2.ZERO, radius * 1.1, Color("120a22"))
	for arm in 3:
		var points := PackedVector2Array()
		for step in 14:
			var t := float(step) / 13.0
			var angle := _clock * 3.0 + arm * TAU / 3.0 + t * 3.2
			points.append(Vector2(cos(angle), sin(angle)) * radius * (0.25 + t * 0.95))
		draw_polyline(points, fill.lightened(0.2 + 0.15 * arm), 3.5)
	draw_circle(Vector2.ZERO, radius * 0.28, Color("e8d8ff"))


func _draw_mimic(fill: Color) -> void:
	if _is_disguised():
		# Parece um item de equipamento no chão: brilho dourado e o ícone de um anel.
		var bob := sin(_clock * 4.0) * 2.0
		draw_circle(Vector2(0, bob - 6.0), 15.0, Color(Brand.GOLD, 0.22 + 0.1 * sin(_clock * 3.0)))
		draw_circle(Vector2(0, bob - 6.0), 11.5, Brand.NIGHT)
		draw_circle(Vector2(0, bob - 6.0), 10.0, Color("3a2a10"))
		Icons.draw(self, "ring", Rect2(-9, bob - 15.0, 18, 18), Color("ffd24a"))
		return
	var shake := Vector2(sin(_clock * 60.0), 0.0) * 2.0 if _mimic_windup > 0.0 else Vector2.ZERO
	var body := Rect2(-radius + shake.x, -radius * 0.2, radius * 2.0, radius * 1.2)
	draw_rect(body.grow(3.0), Brand.NIGHT)
	draw_rect(body, fill)
	draw_rect(Rect2(body.position.x, body.position.y + radius * 0.35, body.size.x, 4.0), Brand.BRASS_DARK)
	var open := 0.5 + 0.5 * sin(_clock * 9.0)
	var lid := PackedVector2Array([
		Vector2(-radius, -radius * 0.2) + shake, Vector2(radius, -radius * 0.2) + shake,
		Vector2(radius * 0.9, -radius * (0.7 + open * 0.5)) + shake, Vector2(-radius * 0.9, -radius * (0.7 + open * 0.5)) + shake])
	draw_colored_polygon(lid, fill.darkened(0.15))
	draw_polyline(lid + PackedVector2Array([lid[0]]), Brand.NIGHT, 2.5)
	draw_rect(Rect2(-radius * 0.8 + shake.x, -radius * 0.2, radius * 1.6, radius * 0.25), Color("7a1a22"))
	for i in 5:
		var x := -radius * 0.7 + i * radius * 0.35
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, -radius * 0.2) + shake, Vector2(x + radius * 0.18, -radius * 0.2) + shake,
			Vector2(x + radius * 0.09, radius * 0.05) + shake]), Color("f4e9d8"))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.4, -radius * 0.55) + shake, radius * 0.14, Color("ffe45c"))


## Sombra no chão. O morcego e o fantasma flutuam, então a sombra fica mais longe.
func _draw_shadow() -> void:
	var drop := radius * (2.3 if kind == "bat" else (1.5 if kind == "ghost" else 0.95))
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(Vector2(cos(angle) * radius * 1.15, sin(angle) * radius * 0.4 + drop))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.3))


func _body_color() -> Color:
	var fill := color
	if _burn_ticks > 0:
		fill = color.lerp(Color("ff7a1a"), 0.55)
	elif _slow_time > 0.0:
		fill = color.lerp(Color("6ec6ff"), 0.55)
	return fill.lerp(Color.WHITE, clampf(_hit_flash * 8.0, 0.0, 1.0))


func _eyes(offset_y: float, spacing: float, size: float, iris: Color) -> void:
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * spacing, offset_y), size, Color.WHITE)
		draw_circle(Vector2(side * spacing, offset_y), size * 0.5, iris)


func _blob(scale_factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * i / 20.0
		var wobble := 1.0 + 0.07 * sin(angle * 3.0)
		points.append(Vector2(cos(angle) * wobble, sin(angle) * 0.88 * wobble) * radius * scale_factor)
	return points


func _draw_slime(fill: Color) -> void:
	draw_colored_polygon(_blob(1.14), Brand.NIGHT)
	draw_colored_polygon(_blob(1.0), fill)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.45), radius * 0.2, fill.lightened(0.45))
	_eyes(-radius * 0.05, radius * 0.32, radius * 0.2, Brand.NIGHT)


func _draw_bat(fill: Color) -> void:
	var flap := sin(_clock * 18.0)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(side * radius * 0.5, -radius * 0.2),
			Vector2(side * radius * 2.3, -radius * (0.2 + 0.9 * flap)),
			Vector2(side * radius * 1.6, radius * 0.8)])
		draw_colored_polygon(wing, fill.darkened(0.3))
		var ear := PackedVector2Array([
			Vector2(side * radius * 0.7, -radius * 0.6),
			Vector2(side * radius * 0.9, -radius * 1.4),
			Vector2(side * radius * 0.1, -radius * 0.9)])
		draw_colored_polygon(ear, fill)
	draw_circle(Vector2.ZERO, radius + 1.5, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.35, -radius * 0.1), radius * 0.2, Color("ff4d4d"))


func _draw_skull(fill: Color) -> void:
	draw_circle(Vector2.ZERO, radius + 1.5, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.38, -radius * 0.1), radius * 0.28, Brand.NIGHT)
	for i in 3:
		var x := -radius * 0.4 + i * radius * 0.4
		draw_line(Vector2(x, radius * 0.5), Vector2(x, radius * 0.85), Brand.NIGHT, 1.2)


func _draw_skeleton(fill: Color) -> void:
	draw_arc(Vector2(radius * 1.15, 0), radius * 0.95, -1.1, 1.1, 10, Color("a8692f"), 3.5)
	draw_line(Vector2(radius * 1.15 + radius * 0.95 * cos(1.1), radius * 0.95 * sin(-1.1)),
		Vector2(radius * 1.15 + radius * 0.95 * cos(1.1), radius * 0.95 * sin(1.1)), Brand.PARCHMENT, 1.5)
	draw_circle(Vector2.ZERO, radius + 2.0, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.38, -radius * 0.1), radius * 0.28, Brand.NIGHT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, radius * 0.1), Vector2(-radius * 0.12, radius * 0.38), Vector2(radius * 0.12, radius * 0.38)]), Brand.NIGHT)
	for i in 4:
		var x := -radius * 0.45 + i * radius * 0.3
		draw_line(Vector2(x, radius * 0.55), Vector2(x, radius * 0.85), Brand.NIGHT, 1.5)


func _draw_spider(fill: Color) -> void:
	var leg_color := fill.darkened(0.4)
	for side in [-1.0, 1.0]:
		for i in 4:
			var wiggle := sin(_clock * 9.0 + i * 1.4 + side) * radius * 0.12
			var start := Vector2(side * radius * 0.5, radius * (-0.3 + i * 0.28))
			var knee := Vector2(side * radius * 1.5, radius * (-0.9 + i * 0.4) + wiggle)
			var foot := Vector2(side * radius * 2.0, radius * (-0.1 + i * 0.5) - wiggle)
			draw_polyline(PackedVector2Array([start, knee, foot]), Brand.NIGHT, 4.0)
			draw_polyline(PackedVector2Array([start, knee, foot]), leg_color, 2.2)
	draw_circle(Vector2(0, radius * 0.3), radius * 0.95 + 1.5, Brand.NIGHT)
	draw_circle(Vector2(0, radius * 0.3), radius * 0.95, fill)
	draw_circle(Vector2(0, -radius * 0.55), radius * 0.6 + 1.5, Brand.NIGHT)
	draw_circle(Vector2(0, -radius * 0.55), radius * 0.6, fill.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-radius * 0.22, radius * 0.1), Vector2(radius * 0.22, radius * 0.1), Vector2(0, radius * 0.42)]), Color("d8452e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-radius * 0.22, radius * 0.75), Vector2(radius * 0.22, radius * 0.75), Vector2(0, radius * 0.43)]), Color("d8452e"))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.22, -radius * 0.72), radius * 0.12, Color("ff3b30"))
		draw_circle(Vector2(side * radius * 0.4, -radius * 0.5), radius * 0.09, Color("ff3b30"))


func _draw_bomber(fill: Color) -> void:
	var pulse := 0.0
	if _fuse >= 0.0:
		pulse = 0.5 + 0.5 * sin(_fuse * 40.0)
		fill = fill.lerp(Color("ff3b30"), pulse)
		draw_circle(Vector2.ZERO, BOMB_RADIUS, Color(1.0, 0.3, 0.2, 0.08 + 0.08 * pulse))
		draw_arc(Vector2.ZERO, BOMB_RADIUS, 0.0, TAU, 48, Color(1.0, 0.3, 0.2, 0.7), 2.0)
	draw_circle(Vector2.ZERO, radius + 2.0, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.4), radius * 0.2, fill.lightened(0.4))
	draw_line(Vector2(0, -radius), Vector2(radius * 0.5, -radius * 1.5), Color("c9a06a"), 3.0)
	draw_circle(Vector2(radius * 0.5, -radius * 1.5), 3.5 + 1.5 * sin(_clock * 20.0), Color("ffb02e"))
	_eyes(radius * 0.05, radius * 0.32, radius * 0.18, Color("ff3b30"))


func _draw_wolf(fill: Color) -> void:
	# O aviso da investida é desenhado sem espelhar, apontando para o herói.
	if _wolf_state == "windup":
		var alpha := 0.35 + 0.35 * sin(_clock * 24.0)
		draw_line(Vector2.ZERO, _wolf_dir * 230.0, Color(1.0, 0.2, 0.15, alpha), radius * 1.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_face, 1.0))
	var body := PackedVector2Array()
	for i in 14:
		var angle := TAU * i / 14.0
		body.append(Vector2(cos(angle) * radius * 1.25, sin(angle) * radius * 0.75))
	var outline := PackedVector2Array()
	for point in body:
		outline.append(point * 1.12)
	draw_colored_polygon(outline, Brand.NIGHT)
	draw_colored_polygon(body, fill)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-radius * 1.1, -radius * 0.1), Vector2(-radius * 1.9, -radius * 0.7), Vector2(-radius * 1.2, radius * 0.3)]), fill.darkened(0.15))
	draw_circle(Vector2(radius * 1.05, -radius * 0.2), radius * 0.72 + 1.5, Brand.NIGHT)
	draw_circle(Vector2(radius * 1.05, -radius * 0.2), radius * 0.72, fill.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(radius * 1.55, -radius * 0.3), Vector2(radius * 2.1, -radius * 0.05), Vector2(radius * 1.55, radius * 0.2)]), fill.darkened(0.2))
	draw_circle(Vector2(radius * 2.05, -radius * 0.05), radius * 0.13, Brand.NIGHT)
	for ear_x in [0.75, 1.2]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(radius * ear_x, -radius * 0.75), Vector2(radius * (ear_x + 0.1), -radius * 1.35), Vector2(radius * (ear_x + 0.35), -radius * 0.75)]), fill.darkened(0.1))
	draw_circle(Vector2(radius * 1.35, -radius * 0.35), radius * 0.15, Color("ffd34d"))
	draw_circle(Vector2(radius * 1.38, -radius * 0.35), radius * 0.07, Brand.NIGHT)
	for leg_x in [-0.7, -0.2, 0.5, 1.0]:
		draw_line(Vector2(radius * leg_x, radius * 0.55), Vector2(radius * leg_x, radius * 0.95), Brand.NIGHT, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_brute(fill: Color) -> void:
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * radius * 0.6, -radius * 0.6),
			Vector2(side * radius * 1.2, -radius * 1.4),
			Vector2(side * radius * 0.15, -radius * 0.95)]), Brand.PARCHMENT)
	draw_circle(Vector2.ZERO, radius + 2.5, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_circle(Vector2(0, radius * 0.3), radius * 0.55, fill.darkened(0.2))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.38, -radius * 0.2), radius * 0.16, Color("ffd34d"))
		draw_line(Vector2(side * radius * 0.65, -radius * 0.5), Vector2(side * radius * 0.12, -radius * 0.3), Brand.NIGHT, 3.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * radius * 0.35, radius * 0.45),
			Vector2(side * radius * 0.55, radius * 0.45),
			Vector2(side * radius * 0.45, radius * 0.8)]), Brand.PARCHMENT)


## Fantasma: sólido ele é pálido e opaco; etéreo fica transparente e azulado.
func _draw_ghost(fill: Color) -> void:
	var alpha := 0.32 if _ethereal else 0.93
	var body := Color(fill, alpha)
	var tail := PackedVector2Array([Vector2(-radius, -radius * 0.2)])
	for i in 7:
		var x := -radius + i * (radius * 2.0 / 6.0)
		var y := radius * 1.0 + sin(_clock * 5.0 + i * 1.3) * radius * 0.2 * (1.0 if i % 2 == 0 else -1.0)
		tail.append(Vector2(x, y))
	tail.append(Vector2(radius, -radius * 0.2))
	draw_colored_polygon(tail, body)
	draw_circle(Vector2(0, -radius * 0.2), radius, body)
	if _ethereal:
		draw_arc(Vector2(0, -radius * 0.2), radius + 2.0, 0.0, TAU, 28, Color(0.55, 0.8, 1.0, 0.7), 2.0)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.35, -radius * 0.35), radius * 0.17, Color(Brand.NIGHT, 0.4 + alpha * 0.6))
	draw_circle(Vector2(0, radius * 0.1), radius * 0.15, Color(Brand.NIGHT, 0.4 + alpha * 0.6))


func _draw_mushroom(fill: Color) -> void:
	draw_rect(Rect2(-radius * 0.5 - 1.5, -radius * 0.1 - 1.5, radius + 3.0, radius * 1.2 + 3.0), Brand.NIGHT)
	draw_rect(Rect2(-radius * 0.5, -radius * 0.1, radius, radius * 1.2), Color("efe2c8"))
	var cap := PackedVector2Array()
	var cap_outline := PackedVector2Array()
	for i in 13:
		var angle := PI + PI * i / 12.0
		var point := Vector2(cos(angle) * radius * 1.35, sin(angle) * radius * 1.0 - radius * 0.1)
		cap.append(point)
		cap_outline.append(Vector2(cos(angle) * (radius * 1.35 + 2.5), sin(angle) * (radius * 1.0 + 2.5) - radius * 0.1))
	draw_colored_polygon(cap_outline, Brand.NIGHT)
	draw_colored_polygon(cap, fill)
	for spot in [Vector2(-0.6, -0.6), Vector2(0.1, -0.85), Vector2(0.7, -0.5), Vector2(-0.1, -0.35)]:
		draw_circle(Vector2(spot.x * radius, spot.y * radius), radius * 0.16, Color("c9f58a"))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.2, radius * 0.4), radius * 0.13, Color.WHITE)
		draw_circle(Vector2(side * radius * 0.2, radius * 0.42), radius * 0.06, Brand.NIGHT)
		draw_line(Vector2(side * radius * 0.4, radius * 0.18), Vector2(side * radius * 0.08, radius * 0.3), Brand.NIGHT, 2.0)
	for drip in [-0.9, -0.3, 0.5]:
		draw_circle(Vector2(drip * radius, radius * 0.1 + sin(_clock * 3.0 + drip) * 2.0), radius * 0.1, Color("8ae34a"))


func _draw_necromancer(fill: Color) -> void:
	var robe := PackedVector2Array([
		Vector2(-radius * 1.15, radius * 1.05), Vector2(-radius * 0.5, -radius * 0.4),
		Vector2(radius * 0.5, -radius * 0.4), Vector2(radius * 1.15, radius * 1.05)])
	var robe_outline := PackedVector2Array()
	for point in robe:
		robe_outline.append(point * 1.12 + Vector2(0, 1))
	draw_colored_polygon(robe_outline, Brand.NIGHT)
	draw_colored_polygon(robe, fill)
	draw_line(Vector2(-radius * 0.7, radius * 0.5), Vector2(radius * 0.7, radius * 0.5), fill.lightened(0.25), 3.0)
	draw_circle(Vector2(0, -radius * 0.5), radius * 0.8 + 2.0, Brand.NIGHT)
	draw_circle(Vector2(0, -radius * 0.5), radius * 0.8, fill.darkened(0.1))
	draw_circle(Vector2(0, -radius * 0.45), radius * 0.52, Color("0d0818"))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.22, -radius * 0.45), radius * 0.11, Color("7dff7a"))
		draw_circle(Vector2(side * radius * 0.22, -radius * 0.45), radius * 0.2, Color(0.49, 1.0, 0.48, 0.25))
	draw_line(Vector2(radius * 1.35, radius * 1.0), Vector2(radius * 1.35, -radius * 1.0), Color("6a4a2a"), 3.5)
	draw_circle(Vector2(radius * 1.35, -radius * 1.15), radius * 0.38, Color(0.49, 1.0, 0.48, 0.3))
	draw_circle(Vector2(radius * 1.35, -radius * 1.15), radius * 0.24, Color("7dff7a"))


## Estrelinhas girando sobre a cabeça de quem está paralisado.
func _draw_stun() -> void:
	for i in 3:
		var angle := _clock * 6.0 + i * TAU / 3.0
		var center := Vector2(cos(angle) * radius * 0.9, -radius * 1.5 + sin(angle) * radius * 0.25)
		var star := PackedVector2Array([
			center + Vector2(0, -5), center + Vector2(2, -1.5), center + Vector2(5, 0), center + Vector2(2, 1.5),
			center + Vector2(0, 5), center + Vector2(-2, 1.5), center + Vector2(-5, 0), center + Vector2(-2, -1.5)])
		draw_colored_polygon(star, Color("ffe45c"))


func _draw_health_bar() -> void:
	var width := maxf(radius * 2.4, 24.0)
	var lift: float = BAR_LIFT.get(kind, 0.0)
	var top := -radius - 11.0 - radius * lift
	var ratio := clampf(health / max_health, 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5 - 1.0, top - 1.0, width + 2.0, 6.0), Brand.NIGHT)
	draw_rect(Rect2(-width * 0.5, top, width, 4.0), Color("4a1f1f"))
	draw_rect(Rect2(-width * 0.5, top, width * ratio, 4.0), Color("e0452d").lerp(Color("7bd389"), ratio))


# --- Efeitos recebidos e morte ----------------------------------------------

func apply_slow(factor: float, duration: float) -> void:
	if _slow_time <= 0.0:
		queue_redraw()
	_slow_factor = factor
	_slow_time = max(_slow_time, duration)


func apply_burn(ticks: int, damage: float) -> void:
	_burn_ticks = ticks
	_burn_damage = damage
	_burn_timer = 1.0
	queue_redraw()


## Paralisa: o inimigo não anda, ataca nem usa habilidades por `duration` segundos.
func stun(duration: float, cause := "stun") -> void:
	_stun_cause = cause
	_stun_time = maxf(_stun_time, duration)
	queue_redraw()


func is_stunned() -> bool:
	return _stun_time > 0.0


## Fantasma etéreo: não pode ser alvo e ignora todo dano.
func is_intangible() -> bool:
	return _ethereal or _burrowed


func knockback(velocity: Vector2) -> void:
	if knockback_immune:
		return
	_push = velocity


## Golpe do herói. Ordem: acerto (o golpe básico pode errar; Destreza ajuda), esquiva do inimigo,
## crítico (o herói pode multiplicar o dano) e bloqueio (reduz o dano a BLOCK_MULT). `hit_kind`:
## "hit" golpe básico; "skill" habilidade (não erra); "dot" queimadura (ignora tudo isso).
func take_damage(amount: float, hit_kind := "hit") -> void:
	if is_queued_for_deletion() or _ethereal or _burrowed:
		return
	if _is_disguised():
		wake_up()
	var result := "hit" if hit_kind == "skill" else hit_kind
	if hit_kind == "hit" or hit_kind == "skill":
		if hit_kind == "hit" and target != null and randf() > target.get_accuracy():
			EventBus.damage_dealt.emit(0.0, global_position, "miss")
			return
		if randf() < dodge_chance:
			EventBus.damage_dealt.emit(0.0, global_position, "dodge")
			return
		if target != null and randf() < target.get_crit_chance():
			amount *= target.crit_multiplier()
			result = "crit"
		if randf() < block_chance:
			amount *= BLOCK_MULT
			result = "block"
	var dealt := amount * damage_taken_mult * (0.5 if shield_time > 0.0 else 1.0)
	if amount < 1.0e8:
		var effective_defense := defense * (1.0 - (target.get_penetration() if target != null else 0.0))
		dealt *= 1.0 - effective_defense / (effective_defense + DEFENSE_K)
	health -= dealt
	if result == "crit" and target != null and not knockback_immune:
		# Só o crítico empurra o inimigo para trás.
		knockback((global_position - target.global_position).normalized() * CRIT_KNOCKBACK)
	EventBus.damage_dealt.emit(dealt + minf(health, 0.0), global_position, result)
	_hit_flash = 0.1
	queue_redraw()
	if health <= 0.0:
		die()
	elif kind == "hedgehog":
		_check_spikes()


func _death_burst() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var burst := DeathBurst.new()
	parent.add_child(burst)
	burst.setup(global_position, color, radius, is_elite or is_boss)
	if is_boss:
		EventBus.impact.emit(14.0, 0.15)
	elif is_elite:
		EventBus.impact.emit(8.0, 0.08)


func die() -> void:
	_death_burst()
	remove_from_group("enemies")
	EventBus.enemy_killed.emit(global_position, xp_value, loot)
	EventBus.monster_defeated.emit(kind)
	if stolen_gold > 0:
		EventBus.gold_recovered.emit(global_position, int(stolen_gold * 1.5))
	if treasure > 0:
		EventBus.treasure_dropped.emit(global_position, treasure, 2 if (is_boss or is_mini) else (1 if is_elite else 0))
	if is_boss:
		EventBus.boss_died.emit(display_name)
	if kind == "slime" and generation == 0:
		_split()
	elif kind == "mushroom":
		_drop_cloud(90.0, 3.0, 8.0 * _dmg_scale)
	queue_free()


## Gosma: ao morrer, deixa quatro gosminhas, mais rápidas e frágeis.
func _split() -> void:
	for offset in [Vector2(-1.0, -0.4), Vector2(1.0, -0.4), Vector2(-0.55, 0.6), Vector2(0.55, 0.6)]:
		var mini := Enemy.new()
		mini.kind = "slime"
		mini.generation = 1
		mini.loot = false
		mini.target = target
		mini.color = color
		mini.radius = radius * 0.5
		mini.max_health = max_health * 0.2
		mini.speed = speed * 1.3
		mini.contact_damage = contact_damage * 0.6
		mini.xp_value = 1
		mini.position = position + offset * radius * 0.8
		get_parent().add_child.call_deferred(mini)


## Envenena: dano de veneno a cada segundo por `ticks` segundos.
func apply_poison(ticks: int, damage: float) -> void:
	_poison_ticks = maxi(_poison_ticks, ticks)
	_poison_damage = maxf(_poison_damage, damage)
	_poison_timer = 1.0
	queue_redraw()


## Os efeitos que o inimigo sofre agora, na ordem em que os ícones aparecem sobre ele.
func status_effects() -> Array:
	var list: Array = []
	if _stun_time > 0.0:
		list.append(_stun_cause)
	if _burn_ticks > 0:
		list.append("burn")
	if _poison_ticks > 0:
		list.append("poison")
	if _slow_time > 0.0:
		list.append("freeze")
	if shield_time > 0.0:
		list.append("shield")
	return list


## Um ícone pequeno por efeito, em fila sobre a barra de vida.
func _draw_status_icons() -> void:
	var effects := status_effects()
	if effects.is_empty():
		return
	var lift: float = BAR_LIFT.get(kind, 0.0)
	var y := -radius - 11.0 - radius * lift - 13.0
	var spacing := 15.0
	var x := -spacing * 0.5 * (effects.size() - 1)
	for effect in effects:
		var c := Vector2(x, y)
		draw_circle(c, 7.5, Color("120a05", 0.85))
		match effect:
			"stun":
				var star := PackedVector2Array([c + Vector2(0, -5), c + Vector2(1.6, -1.6), c + Vector2(5, 0), c + Vector2(1.6, 1.6), c + Vector2(0, 5), c + Vector2(-1.6, 1.6), c + Vector2(-5, 0), c + Vector2(-1.6, -1.6)])
				draw_colored_polygon(star, Color("ffe45c"))
			"paralysis":
				draw_colored_polygon(PackedVector2Array([c + Vector2(1, -6), c + Vector2(-3.5, 0.5), c + Vector2(-0.5, 0.5), c + Vector2(-1.5, 6), c + Vector2(3.5, -1), c + Vector2(0.5, -1)]), Color("9cff6a"))
			"burn":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(3.5, -1), c + Vector2(4, 2.5), c + Vector2(0, 6), c + Vector2(-4, 2.5), c + Vector2(-3, -1.5), c + Vector2(-1, 0)]), Color("ff7a1a"))
				draw_circle(c + Vector2(0, 2.5), 1.8, Color("ffe08a"))
			"poison":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(3.8, 0.5), c + Vector2(3.0, 3.8), c + Vector2(0, 5.5), c + Vector2(-3.0, 3.8), c + Vector2(-3.8, 0.5)]), Color("7bd34a"))
				draw_circle(c + Vector2(-1.2, 0.8), 1.2, Color("d6ffd2"))
			"freeze":
				for i in 3:
					var direction := Vector2.from_angle(i * PI / 3.0) * 5.5
					draw_line(c - direction, c + direction, Color("9fe4ff"), 1.6)
				draw_circle(c, 1.4, Color.WHITE)
			"shield":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4.5, -4.5), c + Vector2(4.5, -4.5), c + Vector2(4.5, 1), c + Vector2(0, 6), c + Vector2(-4.5, 1)]), Color("4aa3ff"))
		x += spacing


## A fração mínima da vida do herói que um golpe deste inimigo tira (chefes tiram mais).
func _min_hit_fraction() -> float:
	return BOSS_MIN_FRACTION if is_boss else MIN_FRACTION


## Lista dos inimigos vivos, calculada uma vez por quadro de física e compartilhada (projéteis, separação...).
## Evita pedir o grupo "enemies" (e copiar o array) a cada projétil.
static var _alive_cache: Array = []
static var _alive_frame := -1
## Sobe sempre que um inimigo entra ou sai da cena: invalida as listas guardadas.
static var _population := 0
static var _alive_population := -1


static func alive(tree: SceneTree) -> Array:
	var frame := Engine.get_physics_frames()
	if frame != _alive_frame or _alive_population != _population:
		_alive_population = _population
		_alive_frame = frame
		_alive_cache = tree.get_nodes_in_group("enemies")
	return _alive_cache


## Fotografia dos inimigos vivos neste quadro de física: posições e raios em arrays simples, que os projéteis
## percorrem sem tocar nos nós (ler global_position de cada nó, vezes cada projétil, era o que mais pesava).
static var _snap_positions := PackedVector2Array()
static var _snap_radii := PackedFloat32Array()
static var _snap_nodes: Array = []
static var _snap_frame := -1
static var _snap_population := -1


static func snapshot(tree: SceneTree) -> Array:
	var frame := Engine.get_physics_frames()
	if frame != _snap_frame or _snap_population != _population:
		_snap_population = _population
		_snap_frame = frame
		_snap_positions.clear()
		_snap_radii.clear()
		_snap_nodes = []
		for node in alive(tree):
			var enemy := node as Enemy
			if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
				continue
			_snap_nodes.append(enemy)
			_snap_positions.append(enemy.global_position)
			_snap_radii.append(enemy.radius)
	return _snap_nodes


static func snapshot_positions() -> PackedVector2Array:
	return _snap_positions


static func snapshot_radii() -> PackedFloat32Array:
	return _snap_radii


func _exit_tree() -> void:
	_population += 1
