extends Control
class_name PauseMenuUI

# PauseMenuUI - Menú de pausa con funcionalidades de guardado y carga
# Se integra con el MainHUD para proporcionar acceso rápido a save/load
# Diseñado para ser extensible por modders

# === SEÑALES ===
signal resume_game()
signal save_game_requested()
signal load_game_requested()
signal quit_to_menu()

# === REFERENCIAS A NODOS (se crean dinámicamente) ===
var main_panel: Panel
var title_label: Label
var button_container: VBoxContainer
var resume_button: Button
var save_button: Button
var load_button: Button
var settings_button: Button
var quit_button: Button

# === VARIABLES ===
var main_hud: Control = null

func _ready():
	"""Inicializa el menú de pausa"""
	create_ui()
	setup_connections()
	
	# Buscar referencia al MainHUD
	main_hud = find_main_hud()

func create_ui():
	"""Crea la interfaz de usuario dinámicamente"""
	# Configurar la ventana principal
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Panel de fondo semi-transparente
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0, 0, 0, 0.5)
	add_child(background)
	
	# Panel principal centrado
	main_panel = Panel.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_panel.size = Vector2(300, 400)
	main_panel.position = Vector2(-150, -200)
	add_child(main_panel)
	
	# Layout principal
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(vbox)
	
	# Título
	title_label = Label.new()
	title_label.text = "JUEGO PAUSADO"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)
	
	# Contenedor de botones
	button_container = VBoxContainer.new()
	button_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)
	
	# Botones principales
	resume_button = create_menu_button("Continuar")
	save_button = create_menu_button("Guardar Partida")
	load_button = create_menu_button("Cargar Partida")
	settings_button = create_menu_button("Configuración")
	quit_button = create_menu_button("Salir al Menú Principal")
	
	button_container.add_child(resume_button)
	button_container.add_child(save_button)
	button_container.add_child(load_button)
	button_container.add_child(settings_button)
	button_container.add_child(quit_button)

func create_menu_button(text: String) -> Button:
	"""Crea un botón estilizado para el menú
	
	Args:
		text: Texto del botón
	
	Returns:
		Button: Botón configurado
	"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func setup_connections():
	"""Configura las conexiones de señales de los botones"""
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func find_main_hud() -> Control:
	"""Busca la referencia al MainHUD en la escena"""
	var parent = get_parent()
	while parent:
		if parent.has_method("save_game") and parent.has_method("load_game"):
			return parent
		parent = parent.get_parent()
	return null

func _on_resume_pressed():
	"""Reanuda el juego"""
	resume_game.emit()
	hide()

func _on_save_pressed():
	"""Solicita guardar la partida"""
	if main_hud and main_hud.has_method("save_game"):
		main_hud.save_game()
		# Mostrar confirmación visual
		show_temporary_message("Guardando partida...", 1.5)
	else:
		show_temporary_message("Error: No se pudo acceder al sistema de guardado", 2.0)
	
	save_game_requested.emit()

func _on_load_pressed():
	"""Solicita mostrar el menú de carga"""
	if main_hud and main_hud.has_method("show_load_game_menu"):
		hide() # Ocultar menú de pausa primero
		main_hud.show_load_game_menu()
	else:
		show_temporary_message("Error: No se pudo acceder al sistema de carga", 2.0)
	
	load_game_requested.emit()

func _on_settings_pressed():
	"""Abre el menú de configuración"""
	show_temporary_message("Configuración no implementada", 2.0)
	# TODO: Implementar menú de configuración

func _on_quit_pressed():
	"""Sale al menú principal"""
	# Crear diálogo de confirmación
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirmar salida"
	dialog.dialog_text = "¿Está seguro de que desea salir al menú principal?\n\nSe perderá el progreso no guardado."
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	
	# Conectar confirmación
	dialog.confirmed.connect(_on_quit_confirmed)

func _on_quit_confirmed():
	"""Confirma la salida al menú principal"""
	quit_to_menu.emit()
	
	# Cargar el menú principal
	var main_menu_scene = load("res://Scenes/UI/MainMenu.tscn")
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)
	else:
		# Fallback: salir del juego
		get_tree().quit()

func show_temporary_message(message: String, duration: float = 2.0):
	"""Muestra un mensaje temporal en el menú
	
	Args:
		message: Mensaje a mostrar
		duration: Duración en segundos
	"""
	# Crear label temporal
	var message_label = Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 12)
	message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	
	# Posicionar debajo de los botones
	button_container.add_child(message_label)
	
	# Eliminar después del tiempo especificado
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(message_label.queue_free)
	timer.timeout.connect(timer.queue_free)
	add_child(timer)
	timer.start()

func _input(event):
	"""Manejo de input para el menú de pausa"""
	if not visible:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_on_resume_pressed()
				accept_event()
			KEY_F5: # Atajo para guardar rápido
				_on_save_pressed()
				accept_event()
			KEY_F9: # Atajo para cargar rápido
				_on_load_pressed()
				accept_event()

# === MÉTODOS PÚBLICOS ===

func show_pause_menu():
	"""Muestra el menú de pausa"""
	visible = true
	resume_button.grab_focus()

func hide_pause_menu():
	"""Oculta el menú de pausa"""
	visible = false