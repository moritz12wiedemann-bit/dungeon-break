class_name CharacterAnimator
extends Node
## Spielt die Animationen einer Figur (ModularCharacter) passend zum Zustand ab:
## stehen, laufen, zuschlagen, getroffen werden, sterben.
## Muss direkt unter einem CharacterBody3D hängen (Spieler oder Gegner).
## Das Modell (mit seinem AnimationPlayer) liegt irgendwo darunter, meist im Knoten "Visual".
## Welche Animationen es gibt, steht in tools/build_quaternius_animations.py (ANIMATIONS).

## Animation im Stehen.
@export var idle_animation: String = "Idle"
## Animation beim Laufen.
@export var move_animation: String = "Jog"
## Bei dieser Geschwindigkeit (Meter pro Sekunde) läuft die Laufanimation in normalem Tempo.
## Ist die Figur schneller oder langsamer, wird die Animation entsprechend schneller oder langsamer.
@export var move_animation_speed: float = 5.0
## Angriffs-Animationen. Bei jedem Schlag wird zufällig eine davon gewählt.
@export var attack_animations: PackedStringArray = ["Sword_Regular_A"]
## Animation, wenn die Figur getroffen wird (leer = keine).
@export var hit_animation: String = "Hit_Chest"
@export var death_animation: String = "Death"
## Animation beim Wiederbeleben (leer = direkt wieder stehen).
@export var revive_animation: String = "Revive"
## So lange (Sekunden) dauert die zuletzt gestartete Aktion (z. B. ein Schlag) wirklich.
var last_action_duration: float = 0.0
## Überblendzeit zwischen zwei Animationen in Sekunden.
@export var blend_time: float = 0.15

var _body: CharacterBody3D
var _player: AnimationPlayer
## Solange eine einmalige Animation (Schlag, Treffer ...) läuft, kein Wechsel zu Stehen/Laufen.
var _action_left: float = 0.0
var _dead: bool = false


func _ready() -> void:
	_body = get_parent() as CharacterBody3D


func _physics_process(delta: float) -> void:
	if not _find_player() or _dead:
		return
	_action_left -= delta
	if _action_left > 0.0:
		return
	var speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	if speed > 0.3:
		_play_loop(move_animation, speed / move_animation_speed)
	else:
		_play_loop(idle_animation, 1.0)


## Spielt einen zufälligen Schlag ab. Dauert höchstens `max_duration` Sekunden
## (die Animation wird schneller abgespielt, wenn sie sonst zu lang wäre).
## `fit`: genau `max_duration` dauern, also bei langer Pause auch langsamer abspielen.
func play_attack(max_duration: float, fit: bool = false) -> void:
	if attack_animations.is_empty():
		return
	var anim_name: String = attack_animations[randi() % attack_animations.size()]
	play_action(anim_name, max_duration, fit)


## Spielt eine Animation einmal ab und kehrt danach zu Stehen/Laufen zurück.
## `fit`: genau `max_duration` dauern (auch langsamer, aber höchstens halb so schnell).
func play_action(anim_name: String, max_duration: float = 0.0, fit: bool = false) -> void:
	if not _find_player() or _dead or not _player.has_animation(anim_name):
		return
	var length := _player.get_animation(anim_name).length
	var speed := 1.0
	if max_duration > 0.0 and (length > max_duration or fit):
		speed = maxf(length / max_duration, 0.5)
	_player.speed_scale = 1.0
	_player.play(anim_name, blend_time, speed)
	# Läuft dieselbe Animation schon, von vorn beginnen.
	_player.seek(0.0, true)
	_action_left = length / speed
	last_action_duration = _action_left


## Kurze Geste (Trank trinken, aufheben ...), nur wenn die Figur gerade steht und nichts anderes tut.
func play_gesture(anim_name: String) -> void:
	if _action_left > 0.0 or Vector2(_body.velocity.x, _body.velocity.z).length() > 0.3:
		return
	play_action(anim_name)


## Zusammenzucken bei einem Treffer, aber keinen Schlag unterbrechen.
func play_hit() -> void:
	if hit_animation.is_empty() or _action_left > 0.0:
		return
	play_action(hit_animation)


func play_death() -> void:
	if not _find_player():
		return
	_dead = true
	_player.speed_scale = 1.0
	_player.play(death_animation, blend_time)


func revive() -> void:
	_dead = false
	_action_left = 0.0
	if not revive_animation.is_empty():
		play_action(revive_animation)


func _play_loop(anim_name: String, speed: float) -> void:
	if _player.current_animation != anim_name:
		_player.play(anim_name, blend_time)
	_player.speed_scale = clampf(speed, 0.4, 2.0)


## Sucht den AnimationPlayer im Modell. Gegner bekommen ihr Modell erst nach diesem Knoten,
## deshalb wird erst beim ersten Gebrauch gesucht.
func _find_player() -> bool:
	if _player:
		return true
	_player = _body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _player == null:
		return false
	return true
