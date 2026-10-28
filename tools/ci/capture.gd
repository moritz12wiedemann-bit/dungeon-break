extends Node
## Nur für den automatischen Test-Build (.github/workflows/test-build.yml):
## lädt nacheinander Figuren-Galerie, Stadt und Dungeon und speichert Bildschirmfotos.
## Ordner kommt aus der Umgebungsvariable SHOT_DIR.

const PRESETS := ["hero", "puglin", "imp", "imp_boss", "smith", "merchant", "mystic", "elder"]

var _dir := ""


func _ready() -> void:
	_dir = OS.get_environment("SHOT_DIR")
	if _dir == "":
		_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(_dir)
	_run.call_deferred()


func _run() -> void:
	# Aus der aktuellen Szene lösen, damit dieser Knoten Szenenwechsel überlebt.
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)

	var gallery := _gallery()
	tree.root.add_child(gallery)
	(gallery.get_node("Camera") as Camera3D).make_current()
	await _frames(20)
	_shot("figuren_stehen")
	for figure in gallery.get_children():
		if figure.has_method("get_animation_player"):
			figure.get_animation_player().play("Jog")
	await _frames(12)
	_shot("figuren_laufen")
	for figure in gallery.get_children():
		if figure.has_method("get_animation_player"):
			figure.get_animation_player().play("Sword_Attack")
	await _frames(10)
	_shot("figuren_angriff")
	gallery.free()

	tree.change_scene_to_file("res://scenes/levels/town.tscn")
	await _frames(60)
	_shot("stadt_spieler")
	_overview(Vector3(0, 0, 0), 42.0)
	await _frames(5)
	_shot("stadt_uebersicht")
	_overview(Vector3(0, 0, -8), 16.0)
	await _frames(5)
	_shot("stadt_nah")
	# Inventar mit Schmuck: Amulett, Armschienen und zwei Ringe anziehen.
	var town_player: Node = tree.get_first_node_in_group("player")
	var inventory: Inventory = town_player.inventory
	for slot in [ItemData.Slot.AMULET, ItemData.Slot.BRACERS, ItemData.Slot.RING, ItemData.Slot.RING]:
		var item := ItemGenerator.create_item(ItemData.Rarity.RARE, 5, slot)
		inventory.add_item(item)
		inventory.equip_from_bag(inventory.bag.find(item))
	var panel: Control = tree.root.find_child("InventoryPanel", true, false)
	panel.toggle()
	await _frames(5)
	_shot("inventar_schmuck")
	# Vergleichs-Tooltip: neuer Ring in der Tasche gegen die beiden angelegten.
	var new_ring := ItemGenerator.create_item(ItemData.Rarity.LEGENDARY, 5, ItemData.Slot.RING)
	inventory.add_item(new_ring)
	var bag_slot: ItemSlot = panel._bag_slots[inventory.bag.find(new_ring)]
	var layer := CanvasLayer.new()
	layer.layer = 50
	tree.root.add_child(layer)
	var tip: Control = bag_slot._make_custom_tooltip("x")
	tip.position = Vector2(40, 120)
	layer.add_child(tip)
	await _frames(5)
	_shot("tooltip_vergleich")
	layer.free()
	panel.toggle()

	tree.change_scene_to_file("res://scenes/levels/dungeon.tscn")
	await _frames(90)
	_shot("dungeon_spieler")
	await _measure("dungeon")
	var player: Node3D = tree.current_scene.get_node("Player")
	_overview(player.global_position, 16.0)
	await _frames(5)
	_shot("dungeon_nah")
	print("CAPTURE DONE")
	tree.quit()


func _gallery() -> Node3D:
	var gallery := Node3D.new()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.35, 0.42)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	gallery.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	gallery.add_child(sun)
	for i in PRESETS.size():
		var figure: Node3D = load("res://scenes/characters/%s.tscn" % PRESETS[i]).instantiate()
		figure.position = Vector3((i - 3.5) * 1.6, 0, 0)
		gallery.add_child(figure)
	var camera := Camera3D.new()
	camera.fov = 40
	camera.name = "Camera"
	gallery.add_child(camera)
	camera.look_at_from_position(Vector3(0, 1.8, 7.5), Vector3(0, 1.0, 0))
	return gallery


func _overview(center: Vector3, distance: float) -> void:
	var camera := Camera3D.new()
	get_tree().current_scene.add_child(camera)
	camera.global_position = center + Vector3(0, distance, distance * 0.8)
	camera.look_at(center)
	camera.make_current()


## Misst ein paar Sekunden lang, wie teuer ein Bild ist, und schreibt es in leistung.txt.
## (Im Test-Build läuft alles ohne Grafikkarte, also zählen nur die Vergleichswerte.)
func _measure(label: String) -> void:
	var frames := 120
	var sums := {"process": 0.0, "physics": 0.0, "draw_calls": 0.0, "objects": 0.0, "primitives": 0.0}
	var start := Time.get_ticks_usec()
	for i in frames:
		await get_tree().process_frame
		sums["process"] += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		sums["physics"] += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		sums["draw_calls"] += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		sums["objects"] += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		sums["primitives"] += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var total_ms := (Time.get_ticks_usec() - start) / 1000.0 / frames
	var lines := ["[%s]" % label, "Bild gesamt (ms): %.2f" % total_ms]
	for key in sums:
		lines.append("%s: %.1f" % [key, sums[key] / frames])
	lines.append("Knoten: %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var text := "\n".join(lines)
	print(text)
	var file := FileAccess.open(_dir.path_join("leistung.txt"), FileAccess.READ_WRITE if FileAccess.file_exists(_dir.path_join("leistung.txt")) else FileAccess.WRITE)
	file.seek_end()
	file.store_string(text + "\n\n")
	file.close()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(_dir.path_join(shot_name + ".png"))
	print("SHOT ", shot_name)
