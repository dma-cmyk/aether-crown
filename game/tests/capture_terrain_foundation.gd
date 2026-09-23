extends SceneTree
## Automated screenshot capture runner for Terrain Foundation 01
## Runs the showcase scene, cycles through all 12 camera presets,
## captures 1920x1080 screenshots to docs/screenshots/gemini_terrain_foundation/

const OUT_DIR := "res://../docs/screenshots/gemini_terrain_foundation"

var _showcase: Node = null


func _initialize() -> void:
	change_scene_to_file("res://scenes/showcase/terrain_foundation_showcase.tscn")
	_run()


func _run() -> void:
	# Wait for scene to load
	for i in range(60):
		await self.process_frame
		_showcase = root.get_node_or_null("TerrainFoundationShowcase")
		if _showcase != null:
			break

	if _showcase == null:
		push_error("Failed to load TerrainFoundationShowcase")
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for i in range(20):
		await self.process_frame

	var hud: CanvasLayer = _showcase.get_node_or_null("HUD")
	if hud != null:
		hud.visible = false

	var global_out_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(global_out_dir)

	var presets: Array = _showcase.get("PRESETS")
	print("Capturing %d presets..." % presets.size())

	for i in range(presets.size()):
		_showcase.call("apply_preset", i)
		for f in range(12):
			await self.process_frame

		var p_name: String = presets[i]["name"]
		var img := root.get_viewport().get_texture().get_image()
		var out_path := global_out_dir.path_join(p_name + ".png")
		var err := img.save_png(out_path)
		if err == OK:
			print("CAPTURE_OK: [%d/%d] %s" % [i + 1, presets.size(), p_name])
		else:
			push_error("Failed to save: " + out_path)

	print("ALL_CAPTURES_DONE to: " + global_out_dir)
	quit(0)
