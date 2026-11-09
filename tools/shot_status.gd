extends Node

## Captura da partida com inimigos sob vários efeitos. Uso: godot --path . res://tools/shot_status.tscn -- <arquivo.png>


func _ready() -> void:
	Session.save_enabled = false
	var game: Node = (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	add_child(game)
	for i in 5:
		await get_tree().process_frame
	game.spawning = false
	var kinds := ["slime", "bat", "skeleton", "wolf"]
	for i in kinds.size():
		var enemy: Enemy = game._spawn_one(kinds[i], game.player.global_position + Vector2(-190 + i * 120, -90))
		enemy.target = null
		if i == 0:
			enemy.stun(5.0)
			enemy.apply_burn(5, 0.0)
		elif i == 1:
			enemy.apply_slow(0.5, 5.0)
			enemy.apply_poison(5, 0.0)
		elif i == 2:
			enemy.stun(5.0, "paralysis")
			enemy.apply_poison(5, 0.0)
		else:
			enemy.apply_burn(5, 0.0)
			enemy.apply_slow(0.5, 5.0)
			enemy.shield_time = 5.0
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
