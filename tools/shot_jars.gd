extends Node

func _ready() -> void:
	Session.save_enabled = false
	Session.auto_attack = true
	var game: Node = (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in 5:
		await get_tree().process_frame
	game.spawning = false
	for node in get_tree().get_nodes_in_group("jars"):
		node.queue_free()
	for offset in [Vector2(-160, -80), Vector2(170, -60), Vector2(10, 120)]:
		var jar := HealJar.new()
		jar.target = game.player
		game.world.add_child(jar)
		jar.global_position = game.player.global_position + offset
	game.player.health = game.player.max_health
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
