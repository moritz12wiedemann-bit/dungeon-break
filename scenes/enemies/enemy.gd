extends CharacterBody3D
## Einfacher Nahkampf-Gegner.
## Steht still, bis der Spieler in die Aggro-Reichweite kommt (und ihn sehen kann).
## Dann läuft er hin und schlägt zu. Läuft der Spieler weit genug weg,
## gibt der Gegner auf, geht zu seinem Startpunkt zurück und heilt sich.

## Wird ausgelöst, wenn der Gegner stirbt (das Level zählt damit die übrigen Gegner).
signal died

enum State { IDLE, CHASE, RETURN, DEAD }

## Laufgeschwindigkeit in Metern pro Sekunde (etwas langsamer als der Spieler).
@export var move_speed: float = 4.0
## Ab dieser Entfernung (Meter) bemerkt der Gegner den Spieler.
@export var aggro_range: float = 8.0
## Ist der Spieler weiter weg als das, gibt der Gegner die Verfolgung auf.
@export var leash_range: float = 18.0
## Auf welchen Physik-Ebenen Wände die Sicht blockieren (1 = Welt).
@export_flags_3d_physics var sight_mask: int = 1
## So viele Erfahrungspunkte bekommt der Spieler, wenn er diesen Gegner besiegt.
@export var xp_reward: int = 20
## Wie gute Beute der Gegner fallen lässt: 0 = normal, 1 = großer Gegner, 2 = Boss.
## Die Tabellen dazu stehen in scenes/items/item_generator.gd.
@export_range(0, 2) var loot_tier: int = 0
## Endlos-Modus: läuft immer auf den Spieler zu (egal wie weit weg, auch durch Wände sehend)
## und gibt nie auf.
@export var hunt_player: bool = false
## Lässt beim Tod Beute fallen (im Endlos-Modus nicht, dort gibt es die Belohnung am Ende).
@export var drops_loot: bool = true

@export_group("Aussehen")
## Das 3D-Modell des Gegners (eine Szene aus scenes/characters/). Wird beim Start in "Visual" eingesetzt.
@export var model_scene: PackedScene
## Größe des Modells (1 = Originalgröße, etwa 1,80 m).
@export var model_scale: float = 1.0

@export_group("Kampf")
@export var damage_min: int = 5
@export var damage_max: int = 9
## Wie nah der Gegner am Spieler stehen muss, um zu treffen (Meter, Mitte zu Mitte).
@export var attack_range: float = 1.5
## Sekunden zwischen zwei Schlägen.
@export var attack_cooldown: float = 1.2

@export_group("Gedränge")
## Wie viel Platz der Gegner gegenüber anderen Gegnern braucht (Meter, Radius).
## Bewusst kleiner als die Figur: Gegner drängeln sich nur leicht, und den Spieler
## blockieren sie gar nicht (er läuft durch sie hindurch).
@export var crowd_radius: float = 0.3

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: Health = $Health
@onready var health_bar: Node3D = $HealthBar
@onready var visual: Node3D = $Visual
@onready var collision: CollisionShape3D = $Collision
@onready var animator: CharacterAnimator = $Animator

var state: State = State.IDLE
var _player: Node3D = null
var _home: Vector3
var _cooldown_left: float = 0.0
## Den Weg nicht jedes Bild neu berechnen, sondern ein paar Mal pro Sekunde.
var _repath_left: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Verlangsamung durch Fähigkeiten (0.5 = halb so schnell) und wie lange noch (Sekunden).
var _slow: float = 0.0
var _slow_left: float = 0.0
## Schadensanfälligkeit (0.3 = +30 % Schaden) und wie lange noch (Sekunden).
var _vulnerable: float = 0.0
var _vulnerable_left: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	if model_scene:
		var model: Node3D = model_scene.instantiate()
		model.scale = Vector3.ONE * model_scale
		visual.add_child(model)
	_home = global_position
	nav_agent.target_position = global_position
	health.changed.connect(health_bar.set_value)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	# Kurz zufällig verzögern, damit nicht alle Gegner im selben Bild angreifen.
	_cooldown_left = randf_range(0.0, attack_cooldown)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_repath_left -= delta
	_update_effects(delta)

	match state:
		State.IDLE:
			if _can_notice_player() or (hunt_player and _player and not _player.is_dead()):
				state = State.CHASE
		State.CHASE:
			_update_chase(delta)
		State.RETURN:
			if global_position.distance_to(_home) < 0.6:
				state = State.IDLE
				health.heal(health.max_health)
			elif _can_notice_player():
				state = State.CHASE

	_move_along_path(delta)


## Wird vom Spieler aufgerufen, wenn er uns trifft.
func take_damage(amount: int) -> void:
	if _vulnerable_left > 0.0:
		amount = int(round(amount * (1.0 + _vulnerable)))
	health.take_damage(amount)
	# Wer geschlagen wird, wehrt sich, auch wenn er den Spieler noch nicht bemerkt hatte.
	if state != State.DEAD:
		state = State.CHASE


## Verlangsamt den Gegner für `seconds` Sekunden um `ratio` (0.5 = 50 %). Der stärkere Wert gilt.
func apply_slow(ratio: float, seconds: float) -> void:
	_slow = maxf(_slow, ratio) if _slow_left > 0.0 else ratio
	_slow_left = maxf(_slow_left, seconds)
	_update_tint()


## Lässt den Gegner für `seconds` Sekunden `ratio` mehr Schaden erleiden (0.3 = +30 %).
func apply_vulnerable(ratio: float, seconds: float) -> void:
	_vulnerable = maxf(_vulnerable, ratio) if _vulnerable_left > 0.0 else ratio
	_vulnerable_left = maxf(_vulnerable_left, seconds)
	_update_tint()


func _update_effects(delta: float) -> void:
	if _slow_left <= 0.0 and _vulnerable_left <= 0.0:
		return
	_slow_left = maxf(_slow_left - delta, 0.0)
	_vulnerable_left = maxf(_vulnerable_left - delta, 0.0)
	if _slow_left <= 0.0 and _vulnerable_left <= 0.0:
		_update_tint()


## Verlangsamte bzw. anfällige Gegner sind leicht violett eingefärbt (siehe _on_damaged/_clear_flash).
func _update_tint() -> void:
	_clear_flash()


func _effect_overlay() -> Material:
	if _slow_left <= 0.0 and _vulnerable_left <= 0.0:
		return null
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Color(0.55, 0.3, 1.0, 0.35)
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return tint


func is_dead() -> bool:
	return state == State.DEAD


## Macht den Gegner passend zur Dungeon-Stufe stärker. Muss vor add_child() aufgerufen werden.
## Pro Stufe: +25 % Leben, +15 % Schaden; XP wachsen mit der Stufe mit.
func apply_level(level: int) -> void:
	var steps := maxi(level, 1) - 1
	var hp: Health = get_node("Health")
	hp.max_health = int(round(hp.max_health * (1.0 + 0.25 * steps)))
	damage_min = int(round(damage_min * (1.0 + 0.15 * steps)))
	damage_max = int(round(damage_max * (1.0 + 0.15 * steps)))
	xp_reward = xp_reward * maxi(level, 1)


func _update_chase(delta: float) -> void:
	if _player == null or _player.is_dead() or (not hunt_player and _distance_to_player() > leash_range):
		state = State.RETURN
		nav_agent.target_position = _home
		return

	if _distance_to_player() <= attack_range:
		nav_agent.target_position = global_position
		_face_direction(_player.global_position - global_position, delta)
		if _cooldown_left <= 0.0:
			_attack()
	elif _repath_left <= 0.0:
		_repath_left = 0.2
		nav_agent.target_position = _player.global_position


func _move_along_path(delta: float) -> void:
	var horizontal := Vector3.ZERO
	if not nav_agent.is_navigation_finished():
		var direction := nav_agent.get_next_path_position() - global_position
		direction.y = 0.0
		if direction.length() > 0.01:
			direction = _steer_around_allies(direction.normalized())
			horizontal = direction * move_speed * (1.0 - _slow if _slow_left > 0.0 else 1.0)
			_face_direction(direction, delta)
	horizontal += _crowd_push()

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()


## Steht ein anderer Gegner im Weg (z. B. weil er schon vorne am Spieler zuschlägt),
## seitlich an ihm vorbeilaufen, damit auch hintere Gegner an den Spieler herankommen.
func _steer_around_allies(direction: Vector3) -> Vector3:
	var steer := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var offset: Vector3 = other.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		var reach: float = crowd_radius + other.crowd_radius + 0.8
		if distance < 0.01 or distance > reach:
			continue
		var ahead := offset.dot(direction)
		if ahead <= 0.0:
			continue
		# Seitlicher Abstand zur eigenen Laufrichtung: liegt der andere nicht im Weg, egal.
		var side := direction.cross(Vector3.UP)
		var lateral := offset.dot(side)
		if absf(lateral) > crowd_radius + other.crowd_radius + 0.15:
			continue
		# Zur Seite ausweichen, auf der weniger vom anderen ist. Liegt er genau mittig,
		# entscheidet die eigene Nummer, damit nicht alle zur selben Seite gehen.
		var away := -signf(lateral) if absf(lateral) > 0.05 else (1.0 if get_instance_id() % 2 == 0 else -1.0)
		steer += side * away * (1.0 - distance / reach) * 2.5
	if steer == Vector3.ZERO:
		return direction
	return (direction + steer).normalized()


## Leichtes Auseinanderschieben, wenn sich zwei Gegner überlappen (kleine "Hitbox" untereinander).
func _crowd_push() -> Vector3:
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var offset: Vector3 = global_position - other.global_position
		offset.y = 0.0
		var distance := offset.length()
		var min_distance: float = crowd_radius + other.crowd_radius
		if distance >= min_distance:
			continue
		if distance < 0.01:
			offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			distance = 0.01
		push += offset.normalized() * (min_distance - distance) / min_distance * move_speed
	return push.limit_length(move_speed)


## Bemerkt den Spieler, wenn er nah genug ist und keine Wand dazwischen steht.
func _can_notice_player() -> bool:
	if _player == null or _player.is_dead():
		return false
	if _distance_to_player() > aggro_range:
		return false
	var eye := Vector3(0, 1.2, 0)
	var query := PhysicsRayQueryParameters3D.create(
		global_position + eye, _player.global_position + eye, sight_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _distance_to_player() -> float:
	var offset := _player.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _attack() -> void:
	_cooldown_left = attack_cooldown
	_player.take_damage(randi_range(damage_min, damage_max))
	animator.play_attack(attack_cooldown)


func _on_damaged(amount: int) -> void:
	DamageNumber.spawn(self, amount, Color(1.0, 0.95, 0.6))
	animator.play_hit()
	# Kurz weiß aufblitzen.
	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color(1, 1, 1, 0.7)
	flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for child in visual.find_children("*", "GeometryInstance3D", true, false):
		child.material_overlay = flash
	get_tree().create_timer(0.1).timeout.connect(_clear_flash)


func _clear_flash() -> void:
	if not is_instance_valid(visual):
		return
	var overlay := _effect_overlay()
	for child in visual.find_children("*", "GeometryInstance3D", true, false):
		child.material_overlay = overlay


func _on_died() -> void:
	state = State.DEAD
	remove_from_group("enemies")
	velocity = Vector3.ZERO
	# Keine Kollision mehr: man kann über die Leiche laufen und nicht mehr draufklicken.
	collision.set_deferred("disabled", true)
	health_bar.hide()
	if _player and _player.has_method("gain_xp"):
		_player.gain_xp(xp_reward)
	if drops_loot:
		_drop_loot()
	died.emit()
	# Umfallen, eine Weile liegen bleiben, im Boden versinken, dann verschwinden.
	animator.play_death()
	var tween := create_tween()
	tween.tween_property(visual, "position:y", -1.5, 1.5).set_delay(2.5)
	tween.tween_callback(queue_free)


## Würfelt Beute (Gegenstände, Gold, Orbs) aus und verteilt sie um die Leiche herum.
func _drop_loot() -> void:
	var item_level: int = GameState.dungeon_level
	Loot.drop_extras(loot_tier, item_level, global_position, get_tree())
	var items := ItemGenerator.roll_drops(loot_tier, item_level)
	for i in items.size():
		var angle := TAU * i / items.size() + randf() * 0.5
		var offset := Vector3(cos(angle), 0, sin(angle)) * randf_range(0.6, 1.4)
		GroundItem.drop(items[i], global_position + offset, get_tree())


## Dreht die Figur weich in die angegebene Richtung.
func _face_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var target_angle := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, clampf(12.0 * delta, 0.0, 1.0))
