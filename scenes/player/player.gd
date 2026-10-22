extends CharacterBody3D
## Spielerfigur mit Click-to-Move und Nahkampf.
## Linke Maustaste auf den Boden: die Figur läuft dorthin.
## Linke Maustaste auf einen Gegner: die Figur läuft hin und schlägt zu, bis er tot ist.
## Gedrückt halten funktioniert wie in Diablo: das Ziel folgt dem Mauszeiger.
## Den Weg um Hindernisse herum berechnet der NavigationAgent3D.

## Wird ausgelöst, wenn der Spieler stirbt (die Benutzeroberfläche zeigt dann "Gestorben").
signal died

## Laufgeschwindigkeit in Metern pro Sekunde.
@export var move_speed: float = 6.0
## Wie schnell sich die Figur in Laufrichtung dreht.
@export var turn_speed: float = 12.0
## Auf welchen Physik-Ebenen ein Mausklick etwas treffen darf (1 = Welt, 3 = Gegner).
@export_flags_3d_physics var click_mask: int = 1 | 4

@export_group("Kampf")
## Schaden pro Schlag (zufällig zwischen den beiden Werten).
@export var damage_min: int = 8
@export var damage_max: int = 14
## Wie nah die Figur am Gegner stehen muss, um zu treffen (Meter, von Mitte zu Mitte).
@export var attack_range: float = 1.6
## Sekunden zwischen zwei Schlägen.
@export var attack_cooldown: float = 0.6

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: Health = $Health
@onready var visual: Node3D = $Visual

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Der Gegner, den wir gerade angreifen (null = keiner).
var _attack_target: Node3D = null
var _cooldown_left: float = 0.0


func _ready() -> void:
	add_to_group("player")
	# Am Anfang steht die Figur still: das Ziel ist ihr eigener Standort.
	nav_agent.target_position = global_position
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _unhandled_input(event: InputEvent) -> void:
	# Ein einzelner Klick setzt sofort ein neues Ziel.
	if event.is_action_pressed("move"):
		_pick_target_from_mouse()


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	# Maustaste gedrückt halten = Ziel folgt laufend dem Mauszeiger (wie in Diablo).
	if Input.is_action_pressed("move"):
		_pick_target_from_mouse()

	# Ist der angegriffene Gegner inzwischen tot oder verschwunden, vergessen wir ihn.
	if _attack_target and (not is_instance_valid(_attack_target) or _attack_target.is_dead()):
		_attack_target = null
		nav_agent.target_position = global_position

	var horizontal := Vector3.ZERO
	if _attack_target and _in_attack_range(_attack_target):
		# Nah genug: stehen bleiben, zum Gegner drehen, zuschlagen.
		nav_agent.target_position = global_position
		_face_direction(_attack_target.global_position - global_position, delta)
		if _cooldown_left <= 0.0:
			_attack(_attack_target)
	else:
		if _attack_target:
			# Noch zu weit weg: zum Gegner hinlaufen.
			nav_agent.target_position = _attack_target.global_position
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
	health.take_damage(amount)


func is_dead() -> bool:
	return health.is_dead()


## Schickt einen Strahl von der Kamera durch den Mauszeiger in die Welt.
## Trifft er einen Gegner, wird der angegriffen. Trifft er den Boden, laufen wir dorthin.
func _pick_target_from_mouse() -> void:
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
	if collider is Node and collider.is_in_group("enemies") and not collider.is_dead():
		_attack_target = collider
	else:
		_attack_target = null
		nav_agent.target_position = hit.position


func _in_attack_range(target: Node3D) -> bool:
	var offset := target.global_position - global_position
	offset.y = 0.0
	return offset.length() <= attack_range


func _attack(target: Node3D) -> void:
	_cooldown_left = attack_cooldown
	target.take_damage(randi_range(damage_min, damage_max))
	_play_lunge()


## Kleiner Ausfallschritt nach vorn, damit man sieht, dass geschlagen wird.
func _play_lunge() -> void:
	var tween := create_tween()
	tween.tween_property(visual, "position:z", 0.35, 0.08)
	tween.tween_property(visual, "position:z", 0.0, 0.15)


func _on_damaged(amount: int) -> void:
	DamageNumber.spawn(self, amount, Color(1.0, 0.35, 0.3))


func _on_died() -> void:
	_attack_target = null
	velocity = Vector3.ZERO
	# Figur kippt um.
	var tween := create_tween()
	tween.tween_property(visual, "rotation:x", -PI / 2.0, 0.4)
	died.emit()


## Dreht die Figur weich in die angegebene Richtung.
func _face_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var target_angle := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, clampf(turn_speed * delta, 0.0, 1.0))
