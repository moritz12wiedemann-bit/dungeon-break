extends RefCounted
## Krieger: Zorn des Himmels. Runde Fläche am Mauszeiger; nach 0,5 s macht sie 3 s lang
## ständig Schaden an allen Gegnern darin (die Fläche selbst: heaven_wrath_area.gd).
## Erweiterung 1 "Himmelssog": zieht Gegner zur Mitte, Herauslaufen geht nur mühsam.
## Erweiterung 2 "Entfesselter Zorn": keine Abklingzeit, verbraucht den ganzen Zorn
## (siehe "spend_all_upgrade"), pro verbrauchtem Zorn +1 % Schaden für diesen Einsatz.

const DAMAGE_PER_RAGE := 0.01


static func cast(player, aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	# Der Zorn wird erst nach dem Zaubern abgezogen, hier steht also noch alles zur Verfügung.
	var bonus: float = 1.0 + (player.mana * DAMAGE_PER_RAGE if upgrade == 2 else 0.0)
	var area := preload("res://scenes/skills/heaven_wrath_area.gd").new(player, upgrade == 1, bonus)
	player.get_tree().current_scene.add_child(area)
	area.global_position = Vector3(aim.x, aim.y + 0.03, aim.z)
	player.animator.play_action("Spell_Shoot", 0.4)
	return true
