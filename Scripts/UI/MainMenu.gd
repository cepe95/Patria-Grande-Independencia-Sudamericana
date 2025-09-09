extends Control

@onready var start_button = $ButtonContainer/StartButton
@onready var load_button = $ButtonContainer/LoadButton
@onready var settings_button = $ButtonContainer/SettingsButton
@onready var exit_button = $ButtonContainer/ExitButton

# Referencia al menú de configuración
var settings_scene: PackedScene = preload("res://Scenes/UI/Settings.tscn")
var settings_instance: Control = null

func _ready():
	# Crear instancia del menú de configuración
	settings_instance = settings_scene.instantiate()
	add_child(settings_instance)
	settings_instance.hide()

func _on_start_button_pressed():
	var campaign_selection = load("res://scenes/ui/CampaignSelection.tscn")
	get_tree().change_scene_to_packed(campaign_selection)

func _on_load_button_pressed():
	pass

func _on_settings_button_pressed():
	if settings_instance:
		settings_instance.show_settings()

func _on_exit_button_pressed():
	get_tree().quit()
