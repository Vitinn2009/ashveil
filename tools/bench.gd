extends Node

## Mede o custo do jogo com muitos inimigos, tiros e efeitos. Uso: godot --headless --path . res://tools/bench.tscn
## Mostra o tempo médio por quadro (ms) gasto em _process e _physics_process, e quantos nós existem.

const FRAMES := 600


func _ready() -> void:
	Session.save_enabled = false
	Session.hero_id = "archer"
	Session.auto_attack = true
	Session.stage_index = 25
	var game: Node = (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in 5:
		await get_tree().process_frame
	game.player.max_health = 1.0e9
	game.player.health = 1.0e9
	game.spawning = false
	game.weapon.fire_interval = 0.12
	for i in 58:
		var kinds := ["bat", "skeleton", "wolf", "slime", "spider", "brute", "mushroom", "ghost"]
		var enemy: Enemy = game._spawn_one(kinds[i % kinds.size()], game.player.global_position + Vector2.from_angle(i * 0.9) * (170.0 + (i % 9) * 55.0))
		enemy.max_health = 1.0e9
		enemy.health = 1.0e9
	var mode := "" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
	if mode.contains("nosep"):
		game.set_physics_process(false)
	if mode.contains("noenemy"):
		for node in get_tree().get_nodes_in_group("enemies"):
			node.set_physics_process(false)
	if mode.contains("noweapon"):
		game.weapon.set_process(false)
	if mode.contains("nohud"):
		game.set_process(false)
	var process_total := 0.0
	var physics_total := 0.0
	var peak := 0.0
	var started := Time.get_ticks_usec()
	for i in FRAMES:
		await get_tree().process_frame
		var p := Performance.get_monitor(Performance.TIME_PROCESS)
		var f := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		process_total += p
		physics_total += f
		peak = maxf(peak, p + f)
	var wall := float(Time.get_ticks_usec() - started) / 1000.0 / FRAMES
	print("BENCH process=%.3f ms physics=%.3f ms peak=%.3f ms wall/frame=%.3f ms nodes=%d objects=%d" % [
		process_total / FRAMES * 1000.0, physics_total / FRAMES * 1000.0, peak * 1000.0, wall,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT))])
	get_tree().quit()
