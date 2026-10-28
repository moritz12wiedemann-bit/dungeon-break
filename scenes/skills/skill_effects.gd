class_name SkillEffects
extends RefCounted
## Bausteine für Fähigkeiten: wen trifft ein Hieb, und kurze Leucht-Effekte
## (Hiebbogen, Stich, Auflade-Ring).


## Alle lebenden Gegner im Bogen vor `origin`: höchstens `radius` Meter weit und höchstens
## `half_angle` (Bogenmaß) neben der Richtung `direction`.
static func enemies_in_arc(origin: Node3D, direction: Vector3, radius: float, half_angle: float) -> Array[Node3D]:
	var hits: Array[Node3D] = []
	direction.y = 0.0
	direction = direction.normalized()
	for enemy in origin.get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node3D or enemy.is_dead():
			continue
		var offset: Vector3 = enemy.global_position - origin.global_position
		offset.y = 0.0
		# Die Figur ist breiter als ihr Mittelpunkt: ein Stück Gegner-Radius dazurechnen.
		var size: float = enemy.get("crowd_radius") if enemy.get("crowd_radius") != null else 0.3
		var distance := offset.length()
		if distance > radius + size:
			continue
		if distance > 0.5 and direction.angle_to(offset) > half_angle:
			continue
		hits.append(enemy)
	return hits


## Alle lebenden Gegner in einem geraden Streifen vor `origin`: `length` Meter lang,
## `half_width` Meter zu jeder Seite (plus Gegner-Radius).
static func enemies_in_line(origin: Node3D, direction: Vector3, length: float, half_width: float) -> Array[Node3D]:
	var hits: Array[Node3D] = []
	direction.y = 0.0
	direction = direction.normalized()
	var side := direction.cross(Vector3.UP)
	for enemy in origin.get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node3D or enemy.is_dead():
			continue
		var offset: Vector3 = enemy.global_position - origin.global_position
		offset.y = 0.0
		var size: float = enemy.get("crowd_radius") if enemy.get("crowd_radius") != null else 0.3
		var along := offset.dot(direction)
		if along < -size or along > length + size:
			continue
		if absf(offset.dot(side)) > half_width + size + 0.2:
			continue
		hits.append(enemy)
	return hits


## Alle lebenden Gegner höchstens `radius` Meter um den Punkt `center` (ohne `except`).
static func enemies_around(tree: SceneTree, center: Vector3, radius: float, except: Node3D = null) -> Array[Node3D]:
	var hits: Array[Node3D] = []
	for enemy in tree.get_nodes_in_group("enemies"):
		if not enemy is Node3D or enemy == except or enemy.is_dead():
			continue
		var offset: Vector3 = enemy.global_position - center
		offset.y = 0.0
		if offset.length() <= radius:
			hits.append(enemy)
	return hits


## Der nächste lebende Gegner höchstens `reach` Meter weit und höchstens `half_angle` neben `direction`.
static func nearest_enemy_in_cone(origin: Node3D, direction: Vector3, reach: float, half_angle: float) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for enemy in enemies_in_arc(origin, direction, reach, half_angle):
		var distance := origin.global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## Leuchtender Hiebbogen vor `origin` in Richtung `direction`, verblasst schnell.
static func slash_arc(origin: Node3D, direction: Vector3, radius: float, half_angle: float, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 24
	var inner := radius * 0.62
	for i in steps:
		var a0 := lerpf(-half_angle, half_angle, float(i) / steps)
		var a1 := lerpf(-half_angle, half_angle, float(i + 1) / steps)
		# Zur Mitte des Bogens hin heller.
		var c0 := Color(color, 0.9 * (1.0 - absf(a0) / half_angle * 0.7))
		var c1 := Color(color, 0.9 * (1.0 - absf(a1) / half_angle * 0.7))
		var in_color := Color(color, 0.0)
		var p0 := Vector3(sin(a0), 0, cos(a0))
		var p1 := Vector3(sin(a1), 0, cos(a1))
		for vertex in [[p0 * inner, in_color], [p0 * radius, c0], [p1 * radius, c1],
				[p0 * inner, in_color], [p1 * radius, c1], [p1 * inner, in_color]]:
			tool.set_color(vertex[1])
			tool.add_vertex(vertex[0])
	_spawn_flash(origin, tool.commit(), direction, 0.28, 0.8)


## Leuchtender Stich von `origin` aus, `length` Meter lang in Richtung `direction`.
static func thrust(origin: Node3D, direction: Vector3, length: float, width: float, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := Color(color, 0.0)
	var mid := Color(color, 0.9)
	for vertex in [[Vector3(-width, 0, 0.3), base], [Vector3(width, 0, 0.3), base], [Vector3(0, 0, length), mid],
			[Vector3(-width * 0.4, 0, 0.3), mid], [Vector3(width * 0.4, 0, 0.3), mid], [Vector3(0, 0, length * 1.08), Color.WHITE]]:
		tool.set_color(vertex[1])
		tool.add_vertex(vertex[0])
	_spawn_flash(origin, tool.commit(), direction, 0.22, 1.1)


## Leuchtender Ring am Boden um `player`, solange eine Fähigkeit aufgeladen wird.
## Der Aufrufer vergrößert ihn (scale) und entfernt ihn wieder.
static func charge_ring(player: Node3D) -> Node3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.75
	torus.outer_radius = 0.9
	ring.mesh = torus
	ring.material_override = _glow_material(Color(1.0, 0.8, 0.3, 0.8))
	ring.scale = Vector3.ONE * 0.5
	player.add_child(ring)
	ring.position = Vector3(0, 0.08, 0)
	return ring


static func _spawn_flash(origin: Node3D, mesh: Mesh, direction: Vector3, seconds: float, height: float) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := _glow_material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	node.material_override = material
	origin.get_tree().current_scene.add_child(node)
	node.global_position = origin.global_position + Vector3(0, height, 0)
	node.rotation.y = atan2(direction.x, direction.z)
	node.scale = Vector3(0.85, 1, 0.85)
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "scale", Vector3.ONE, seconds).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, seconds)
	tween.chain().tween_callback(node.queue_free)


static func _glow_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	return material
