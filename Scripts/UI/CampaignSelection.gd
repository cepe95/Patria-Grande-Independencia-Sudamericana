extends Control
@onready var BtnCampaña1 = $VBoxContainer/BtnCampaña1
@onready var BtnVolver = $VBoxContainer/BtnVolver
func _on_btn_campaña_1_pressed() -> void:
	print("Botón campaña presionado")
	get_tree().change_scene_to_file("res://Scenes/Strategic/StrategicMap.tscn")
func _on_btn_volver_pressed() -> void:
	pass # Replace with function body.
