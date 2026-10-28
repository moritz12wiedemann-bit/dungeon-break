extends CharacterBody3D
## Spielerfigur mit Click-to-Move und Nahkampf.
## Linke Maustaste auf den Boden: die Figur läuft dorthin.
## Linke Maustaste auf einen Gegner: die Figur läuft hin und schlägt zu, bis er tot ist.
## Gedrückt halten funktioniert wie in Diablo: das Ziel folgt dem Mauszeiger.
## Den Weg um Hindernisse herum berechnet der NavigationAgent3D.

## Wird ausgelöst, wenn der Spieler stirbt (die Benutzeroberfläche zeigt dann "Gestorben").
signal died
## Wird ausgelöst, wenn der Spieler wiederbelebt wurde.
signal revived

## Laufgeschwindigkeit in Metern pro Sekunde.
@export var move_speed: float = 6.0
## Wie schnell sich die Figur in Laufrichtung dreht.
@export var turn_speed: float = 12.0
## Auf welchen Physik-Ebenen ein Mausklick etwas treffen darf (1 = Welt, 3 = Gegner, 4 = Objekte wie Gegenstände, Altar, Portal).
@export_flags_3d_physics var click_mask: int = 1 | 4 | 8
## Aus dieser Entfernung (Meter) kann man Gegenstände aufheben.
@export var pickup_range: float = 1.5

@export_group("Kampf")
## Schaden pro Schlag (zufällig zwischen den beiden Werten).
@export var damage_min: int = 8
@export var damage_max: int = 14
## Wie nah die Figur am Gegner stehen muss, um zu treffen (Meter, von Mitte zu Mitte).
@export var attack_range: float = 1.6
## Sekunden zwischen zwei Schlägen.
@export var attack_cooldown: float = 0.6

@export_group("Stufenaufstieg")
## So viele maximale Lebenspunkte kommen pro Stufe dazu.
@export var health_per_level: int = 10
## So viel Schaden kommt pro Stufe dazu.
@export var damage_per_level: int = 1

@export_group("Heiltrank")
## Anteil der maximalen Lebenspunkte, den ein Trank heilt (0.4 = 40 %).
@export var potion_heal_ratio: float = 0.4
## Abklingzeit des Tranks in Sekunden.
@export var potion_cooldown: float = 20.0

@export_group("Mana")
## Maximales Mana. Wird noch nicht benutzt (kommt mit den Fähigkeiten).
@export var max_mana: int = 100
## So viel Mana kommt pro Sekunde zurück.
@export var mana_regen: float = 4.0

@export_group("Wiederbeleben")
## Mit welchem Anteil der maximalen Lebenspunkte man wiederbelebt wird.
@export var revive_health_ratio: float = 0.25
## So lange (Sekunden) ist man nach dem Wiederbeleben unverwundbar.
@export var revive_protection: float = 3.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: Health = $Health
@onready var experience: Experience = $Experience
@onready var inventory: Inventory = $Inventory
@onready var animator: CharacterAnimator = $Animator

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Der Gegner, den wir gerade angreifen (null = keiner).
var _attack_target: Node3D = null
## Gegenstand am Boden oder Objekt (Altar, Portal), zu dem wir laufen, um es zu benutzen (null = keins).
var _interact_target: Node3D = null
## Grundwerte ohne Stufe und Ausrüstung (aus dem Inspektor beim Start gemerkt).
var _base_max_health: int
var _base_regen: float
var _base_move_speed: float
## Rüstung aus der Ausrüstung. Verringert erlittenen Schaden: Schaden × 100 / (100 + Rüstung).
var armor: float = 0.0
## Zusätzlicher Schaden aus Stufe und Ausrüstung.
var bonus_damage: int = 0
var _cooldown_left: float = 0.0
## Sekunden, bis der Heiltrank wieder benutzt werden kann (0 = bereit).
var potion_cooldown_left: float = 0.0
var _protection_left: float = 0.0
## Aktuelles Mana (0 bis max_mana).
var mana: float = 0.0


func _ready() -> void:
	add_to_group("player")
	# Am Anfang steht die Figur still: das Ziel ist ihr eigener Standort.
	nav_agent.target_position = global_position
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	experience.leveled_up.connect(_on_leveled_up)
	_base_max_health = health.max_health
	_base_regen = health.regen_per_second
	_base_move_speed = move_speed
	mana = max_mana
	inventory.changed.connect(recalculate_stats)
	# Kommt der Spieler aus der Stadt oder einem Dungeon, bekommt er seine Werte zurück.
	GameState.restore_player(self)


func _unhandled_input(event: InputEvent) -> void:
	# Ein einzelner Klick setzt sofort ein neues Ziel und zeigt eine kleine Markierung am Boden.
	if event.is_action_pressed("move"):
		_pick_target_from_mouse(true)
	elif event.is_action_pressed("potion"):
		drink_potion()
	elif event.is_action_pressed("town_portal"):
		teleport_to_town()


func _process(delta: float) -> void:
	potion_cooldown_left = maxf(potion_cooldown_left - delta, 0.0)
	_protection_left = maxf(_protection_left - delta, 0.0)
	if not health.is_dead():
		mana = minf(mana + mana_regen * delta, max_mana)


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	# Maustaste gedrückt halten = Ziel folgt laufend dem Mauszeiger (wie in Diablo).
	# Nicht, wenn die Maus gerade über einem Fenster (z. B. Inventar) steht.
	if Input.is_action_pressed("move") and get_viewport().gui_get_hovered_control() == null:
		_pick_target_from_mouse()

	# Ist der angegriffene Gegner inzwischen tot oder verschwunden, vergessen wir ihn.
	if _attack_target and (not is_instance_valid(_attack_target) or _attack_target.is_dead()):
		_attack_target = null
		nav_agent.target_position = global_position
	if _interact_target and not is_instance_valid(_interact_target):
		_interact_target = null

	var horizontal := Vector3.ZERO
	if _interact_target and _flat_distance(_interact_target) <= _interact_range(_interact_target):
		var target := _interact_target
		_interact_target = null
		nav_agent.target_position = global_position
		if target is GroundItem:
			animator.play_gesture("PickUp")
			_try_pickup(target)
		else:
			animator.play_gesture("Interact")
			target.interact(self)
	elif _attack_target and _in_attack_range(_attack_target):
		# Nah genug: stehen bleiben, zum Gegner drehen, zuschlagen.
		nav_agent.target_position = global_position
		_face_direction(_attack_target.global_position - global_position, delta)
		if _cooldown_left <= 0.0:
			_attack(_attack_target)
	else:
		if _attack_target:
			# Noch zu weit weg: zum Gegner hinlaufen.
			nav_agent.target_position = _attack_target.global_position
		elif _interact_target:
			nav_agent.target_position = _interact_target.global_position
		if not nav_agent.is_navigation_finished():
			var next_point := nav_agent.get_next_path_position()
			var direction := next_point - global_position
			direction.y = 0.0
			if direction.length() > 0.01:
				horizontal = direction.normalized() * move_speed
				_face_direction(direction, delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	move_and_slide()


## Wird von Gegnern aufgerufen, wenn sie uns treffen.
func take_damage(amount: int) -> void:
	if _protection_left > 0.0:
		return
	var reduced := int(round(amount * 100.0 / (100.0 + armor)))
	health.take_damage(maxi(reduced, 1))


## Wird von Gegnern aufgerufen, wenn sie sterben.
func gain_xp(amount: int) -> void:
	if experience.is_max_level():
		return
	experience.add_xp(amount)
	DamageNumber.spawn_text(self, "+%d XP" % amount, Color(0.75, 0.55, 1.0))


## Trinkt einen Heiltrank, falls die Abklingzeit vorbei ist. Gibt true zurück, wenn es geklappt hat.
func drink_potion() -> bool:
	if health.is_dead() or potion_cooldown_left > 0.0:
		return false
	potion_cooldown_left = potion_cooldown
	var amount := int(round(health.max_health * potion_heal_ratio))
	health.heal(amount)
	animator.play_gesture("Use_Item")
	DamageNumber.spawn_text(self, "+%d" % amount, Color(0.4, 1.0, 0.4))
	return true


## Teleportiert in die Stadt (Taste T). Geht nicht, wenn man tot oder schon in der Stadt ist.
func teleport_to_town() -> void:
	if health.is_dead():
		return
	if get_tree().current_scene.scene_file_path == GameState.TOWN_SCENE:
		DamageNumber.spawn_text(self, "Du bist schon in der Stadt", Color(0.7, 0.8, 1.0))
		return
	GameState.go_to_town(self)


## Holt den toten Spieler an derselben Stelle zurück, mit wenig Leben und kurzem Schutz.
func revive() -> void:
	if not health.is_dead():
		return
	health.revive(int(round(health.max_health * revive_health_ratio)))
	_protection_left = revive_protection
	nav_agent.target_position = global_position
	animator.revive()
	revived.emit()


## Bringt den toten Spieler mit vollem Leben zurück in die Stadt.
func restart_in_town() -> void:
	GameState.go_to_town(self, true)


func is_dead() -> bool:
	return health.is_dead()


## Schickt einen Strahl von der Kamera durch den Mauszeiger in die Welt.
## Trifft er einen Gegner, wird der angegriffen. Trifft er den Boden, laufen wir dorthin.
## `show_marker`: bei einem Klick auf den Boden die kleine Klick-Markierung zeigen.
func _pick_target_from_mouse(show_marker: bool = false) -> void:
	if health.is_dead():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to, click_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.collider
	if collider is GroundItem or collider is Interactable:
		# Aufheben/Benutzen nur mit einem einzelnen Klick, nicht beim Gedrückthalten.
		if Input.is_action_just_pressed("move"):
			_attack_target = null
			_interact_target = collider
		return
	_interact_target = null
	if collider is Node and collider.is_in_group("enemies") and not collider.is_dead():
		_attack_target = collider
	else:
		_attack_target = null
		nav_agent.target_position = hit.position
		if show_marker:
			ClickMarker.spawn(get_tree(), hit.position)


func _in_attack_range(target: Node3D) -> bool:
	return _flat_distance(target) <= attack_range


func _interact_range(target: Node3D) -> float:
	return target.interact_range if target is Interactable else pickup_range


func _flat_distance(target: Node3D) -> float:
	var offset := target.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _try_pickup(ground_item: GroundItem) -> void:
	if inventory.add_item(ground_item.item):
		ground_item.queue_free()
	else:
		DamageNumber.spawn_text(self, "Inventar voll!", Color(1, 0.4, 0.4))


## Wirft den Gegenstand aus Platz `index` der Tasche neben dem Spieler auf den Boden.
func drop_item_from_bag(index: int) -> void:
	var item := inventory.remove_item(index)
	if item == null:
		return
	var offset := Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized() * 1.2
	GroundItem.drop(item, global_position + offset, get_tree())


## Berechnet Leben, Regeneration, Tempo, Rüstung und Schaden aus Grundwert + Stufe + Ausrüstung neu.
func recalculate_stats() -> void:
	var level_bonus := experience.level - 1
	health.set_max_health(_base_max_health + level_bonus * health_per_level
		+ int(inventory.get_stat_total("health")))
	health.regen_per_second = _base_regen + inventory.get_stat_total("regen")
	# Höchstens +25 % Laufgeschwindigkeit aus Ausrüstung.
	move_speed = _base_move_speed * (1.0 + minf(inventory.get_stat_total("move_speed"), 25.0) / 100.0)
	armor = inventory.get_stat_total("armor")
	bonus_damage = level_bonus * damage_per_level + int(inventory.get_stat_total("damage"))


func _attack(target: Node3D) -> void:
	_cooldown_left = attack_cooldown
	target.take_damage(randi_range(damage_min, damage_max) + bonus_damage)
	animator.play_attack(attack_cooldown)


func _on_damaged(amount: int) -> void:
	DamageNumber.spawn(self, amount, Color(1.0, 0.35, 0.3))


func _on_leveled_up(new_level: int) -> void:
	recalculate_stats()
	health.heal(health.max_health)
	DamageNumber.spawn_text(self, "Stufe %d!" % new_level, Color(1.0, 0.85, 0.2))


func _on_died() -> void:
	_attack_target = null
	velocity = Vector3.ZERO
	animator.play_death()
	died.emit()


## Dreht die Figur weich in die angegebene Richtung.
func _face_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var target_angle := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, clampf(turn_speed * delta, 0.0, 1.0))
