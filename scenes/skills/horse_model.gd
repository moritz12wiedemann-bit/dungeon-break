class_name HorseModel
extends Node3D
## Pferd aus dem Farm-Animals-Pack (Quaternius), grau eingefärbt. Für Streitross (der Spieler
## sitzt darauf) und Trampeln (Herde ohne Reiter). Galoppiert, solange `running` an ist.

const MODEL := preload("res://assets/models/quaternius/animals/Horse.fbx")
## Das Modell ist riesig (etwa 9 m lang): so klein machen, dass es zur Figur passt.
const MODEL_SCALE := 0.28
## Höhe des Sattels über dem Boden (bei MODEL_SCALE), dort sitzt der Reiter.
const SADDLE_HEIGHT := 0.95
## Fell grau, Mähne/Hufe fast schwarz (Moritz wollte ein graues bzw. dunkles Pferd).
const COAT_COLOR := Color(0.22, 0.22, 0.24)
const DARK_COLOR := Color(0.05, 0.05, 0.06)

var running := false
## Galopp-Tempo (1 = normal).
var run_speed := 1.0
var _animation: AnimationPlayer


func _ready() -> void:
	var model: Node3D = MODEL.instantiate()
	model.scale = Vector3.ONE * MODEL_SCALE
	add_child(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			var material := StandardMaterial3D.new()
			material.albedo_color = COAT_COLOR if i == 0 else DARK_COLOR
			material.roughness = 0.85
			mesh.set_surface_override_material(i, material)
	_animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for anim_name in ["Armature|Run", "Armature|Idle"]:
		if _animation.has_animation(anim_name):
			_animation.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


func _process(_delta: float) -> void:
	if _animation == null:
		return
	# Unter dem Spieler (Streitross): galoppiert, wenn er sich bewegt.
	var body := get_parent() as CharacterBody3D
	if body:
		var speed := Vector2(body.velocity.x, body.velocity.z).length()
		running = speed > 0.3
		run_speed = clampf(speed / 7.0, 0.6, 1.8)
	var anim_name := "Armature|Run" if running else "Armature|Idle"
	if _animation.current_animation != anim_name:
		_animation.play(anim_name, 0.2)
	_animation.speed_scale = run_speed if running else 1.0
