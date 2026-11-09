extends Node

## Prints do painel admin: tools/shot_admin.tscn -- <pasta>
func _ready() -> void:
	Session.save_enabled = false
	Tuning.save_enabled = false
	var out := OS.get_cmdline_user_args()[0]
	var menu: Node = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	add_child(menu)
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/menu_gear.png" % out)
	var panel: AdminPanel = menu.open_admin()
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/admin_login.png" % out)
	panel._password.text = "admin"
	panel.submit_password()
	for tab_id in ["heroes", "drops"]:
		panel.show_tab(tab_id)
		for i in 4:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("%s/admin_%s.png" % [out, tab_id])
	get_tree().quit()
