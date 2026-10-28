extends Interactable
## Altar in der Stadt. Anklicken öffnet ein Fenster, in dem man die Monsterstufe (1–100) wählt.
## Der Dungeon-Altar (lila) startet einen neuen, zufälligen Dungeon,
## der Endlos-Altar (rot) den Endlos-Modus (siehe hud.gd → Fenster "altar"/"endless").

## Welches Fenster sich öffnet: "altar" = Dungeon, "endless" = Endlos-Modus.
@export var window_name: String = "altar"
## Farbe der schwebenden Kugel und des Lichts.
@export var crystal_color: Color = Color(0.7, 0.2, 1.0)
## Schrift über dem Altar.
@export_multiline var title_text: String = "Dungeon-Altar\n(anklicken: neuer Dungeon)"

@onready var crystal: Node3D = $Crystal
@onready var _crystal_height: float = crystal.position.y


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = crystal_color
	material.emission_enabled = true
	material.emission = crystal_color
	material.emission_energy_multiplier = 1.2
	for part in crystal.get_children():
		part.material_override = material
	$Light.light_color = crystal_color.lerp(Color.WHITE, 0.1)
	$Label.text = title_text
	$Label.modulate = crystal_color.lerp(Color.WHITE, 0.4)


func _process(delta: float) -> void:
	crystal.position.y = _crystal_height + sin(Time.get_ticks_msec() / 600.0) * 0.06


func interact(player: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.open_window(window_name, player, self)
