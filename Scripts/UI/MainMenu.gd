extends Control

@onready var start_button = $ButtonContainer/StartButton
@onready var load_button = $ButtonContainer/LoadButton
@onready var settings_button = $ButtonContainer/SettingsButton
@onready var exit_button = $ButtonContainer/ExitButton



func _on_start_button_pressed():
	var campaign_selection = load("res://scenes/ui/CampaignSelection.tscn")
	get_tree().change_scene_to_packed(campaign_selection)

func _on_load_button_pressed():
	"""Muestra el menú de carga de partidas"""
	# Verificar si hay partidas guardadas
	if not SaveLoadManager.has_save_files():
		show_no_saves_dialog()
		return
	
	# Cargar el menú de carga
	var load_scene = load("res://Scenes/UI/LoadGame.tscn")
	if load_scene:
		var load_instance = load_scene.instantiate()
		get_tree().current_scene.add_child(load_instance)
		
		# Conectar señales
		if load_instance.has_signal("game_loaded"):
			load_instance.game_loaded.connect(_on_game_loaded)
	else:
		show_error_dialog("No se pudo cargar el menú de partidas guardadas")

func show_no_saves_dialog():
	"""Muestra un diálogo informando que no hay partidas guardadas"""
	var dialog = AcceptDialog.new()
	dialog.title = "Sin partidas guardadas"
	dialog.dialog_text = "No hay partidas guardadas disponibles.\n\nInicia una nueva campaña para poder guardar el progreso."
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	
	# Eliminar el diálogo después de cerrarlo
	dialog.confirmed.connect(dialog.queue_free)

func show_error_dialog(message: String):
	"""Muestra un diálogo de error"""
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	
	# Eliminar el diálogo después de cerrarlo
	dialog.confirmed.connect(dialog.queue_free)

func _on_game_loaded(filename: String):
	"""Callback cuando se carga una partida desde el menú principal"""
	# Cambiar a la escena principal del juego
	var test_main_hud_scene = load("res://Scenes/UI/TestMainHUD.tscn")
	if test_main_hud_scene:
		# Cambiar a la escena del juego
		get_tree().change_scene_to_packed(test_main_hud_scene)
		
		# Esperar a que la escena esté lista y luego cargar
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Buscar el MainHUD en la nueva escena y cargar el juego
		var main_hud = get_tree().current_scene.get_node_or_null("MainHUD")
		if main_hud and main_hud.has_method("load_game_on_start"):
			main_hud.load_game_on_start(filename)
		elif main_hud and main_hud.has_method("load_game"):
			main_hud.load_game(filename)
		else:
			show_error_dialog("No se pudo encontrar el MainHUD en la escena del juego")
	else:
		show_error_dialog("No se pudo cargar la escena principal del juego")

func _on_settings_button_pressed():
	pass

func _on_exit_button_pressed():
	get_tree().quit()
