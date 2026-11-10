extends Node

## Prints dos cenários: tools/shot_biomes.tscn -- <pasta>
func _ready() -> void:
	Session.save_enabled = false
	var out := OS.get_cmdline_user_args()[0]
	Session.hero_id = "warrior"
	Session.set_progress("warrior", 30, 0.0, 0, 30)
	for stage_number in [11, 21, 31, 41, 51]:
		Session.stage_index = stage_number - 1
		var game: Node = (load("res://scenes/Game.tscn") as PackedScene).instantiate()
		add_child(game)
		await get_tree().create_timer(1.6).timeout
		get_viewport().get_texture().get_image().save_png("%s/biome_%d.png" % [out, stage_number])
		game.queue_free()
		await get_tree().process_frame
	get_tree().quit()
