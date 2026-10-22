extends CharacterBody3D
## Spielerfigur mit Click-to-Move.
## Linke Maustaste klicken oder gedrückt halten: die Figur läuft zum Mauszeiger.
## Den Weg um Hindernisse herum berechnet der NavigationAgent3D.

## Laufgeschwindigkeit in Metern pro Sekunde.
@export var move_speed: float = 6.0
## Wie schnell sich die Figur in Laufrichtung dreht.
@export var turn_speed: float = 12.0
## Auf welchen Physik-Ebenen ein Mausklick einen Zielpunkt finden darf (Ebene 1 = "Welt").
@export_flags_3d_physics var click_mask: int = 1

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# Am Anfang steht die Figur still: das Ziel ist ihr eigener Standort.
	nav_agent.target_position = global_position


func _unhandled_input(event: InputEvent) -> void:
	# Ein einzelner Klick setzt sofort ein neues Ziel.
	if event.is_action_pressed("move"):
		_set_target_from_mouse()


func _physics_process(delta: float) -> void:
	# Maustaste gedrückt halten = Ziel folgt laufend dem Mauszeiger (wie in Diablo).
	if Input.is_action_pressed("move"):
		_set_target_from_mouse()

	var horizontal := Vector3.ZERO
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


## Schickt einen Strahl von der Kamera durch den Mauszeiger in die Welt
## und nimmt den Treffpunkt als neues Laufziel.
func _set_target_from_mouse() -> void:
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
	nav_agent.target_position = hit.position


## Dreht die Figur weich in die angegebene Richtung.
func _face_direction(direction: Vector3, delta: float) -> void:
	var target_angle := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, clampf(turn_speed * delta, 0.0, 1.0))
