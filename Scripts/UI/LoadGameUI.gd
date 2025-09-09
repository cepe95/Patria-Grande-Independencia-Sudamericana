extends Control
class_name LoadGameUI

# LoadGameUI - Interfaz para cargar partidas guardadas
# Se integra con el SaveLoadManager para mostrar y cargar archivos de guardado
# Diseñado para ser extensible y fácil de personalizar por modders

# === SEÑALES ===
signal game_loaded(filename: String)
signal load_cancelled()

# === REFERENCIAS A NODOS (se crean dinámicamente) ===
var main_panel: Panel
var title_label: Label
var saves_list: VBoxContainer
var scroll_container: ScrollContainer
var button_container: HBoxContainer
var load_button: Button
var cancel_button: Button
var delete_button: Button
var refresh_button: Button

# === VARIABLES DE ESTADO ===
var save_manager: SaveLoadManager
var selected_save_file: Dictionary = {}
var save_files: Array[Dictionary] = []

func _ready():
	"""Inicializa la interfaz de carga de partidas"""
	setup_save_manager()
	create_ui()
	refresh_save_list()

func setup_save_manager():
	"""Configura el gestor de guardado"""
	save_manager = SaveLoadManager as SaveLoadManager
	
	# Conectar señales
	save_manager.save_list_updated.connect(_on_save_list_updated)
	save_manager.load_completed.connect(_on_load_completed)

func create_ui():
	"""Crea la interfaz de usuario dinámicamente"""
	# Configurar la ventana principal
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Panel de fondo semi-transparente
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0, 0, 0, 0.7)
	add_child(background)
	
	# Panel principal centrado
	main_panel = Panel.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_panel.size = Vector2(600, 400)
	main_panel.position = Vector2(-300, -200)
	add_child(main_panel)
	
	# Layout principal
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(vbox)
	
	# Título
	title_label = Label.new()
	title_label.text = "Cargar Partida"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)
	
	# Área de lista de guardados
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll_container)
	
	saves_list = VBoxContainer.new()
	saves_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(saves_list)
	
	# Botones de acción
	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)
	
	refresh_button = Button.new()
	refresh_button.text = "Actualizar"
	refresh_button.pressed.connect(refresh_save_list)
	button_container.add_child(refresh_button)
	
	delete_button = Button.new()
	delete_button.text = "Eliminar"
	delete_button.disabled = true
	delete_button.pressed.connect(delete_selected_save)
	button_container.add_child(delete_button)
	
	load_button = Button.new()
	load_button.text = "Cargar"
	load_button.disabled = true
	load_button.pressed.connect(load_selected_save)
	button_container.add_child(load_button)
	
	cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.pressed.connect(cancel_load)
	button_container.add_child(cancel_button)

func refresh_save_list():
	"""Actualiza la lista de archivos de guardado"""
	save_files = save_manager.get_save_files()
	populate_saves_list()

func populate_saves_list():
	"""Puebla la lista con los archivos de guardado"""
	# Limpiar lista existente
	for child in saves_list.get_children():
		child.queue_free()
	
	if save_files.is_empty():
		show_no_saves_message()
		return
	
	# Crear entrada para cada archivo
	for i in range(save_files.size()):
		var save_file = save_files[i]
		var entry = create_save_entry(save_file, i)
		saves_list.add_child(entry)

func show_no_saves_message():
	"""Muestra un mensaje cuando no hay partidas guardadas"""
	var message_label = Label.new()
	message_label.text = "No hay partidas guardadas disponibles"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	saves_list.add_child(message_label)
	
	# Deshabilitar botones
	load_button.disabled = true
	delete_button.disabled = true

func create_save_entry(save_file: Dictionary, index: int) -> Control:
	"""Crea una entrada visual para un archivo de guardado
	
	Args:
		save_file: Información del archivo
		index: Índice en la lista
	
	Returns:
		Control: El widget de entrada creado
	"""
	var entry = Panel.new()
	entry.custom_minimum_size = Vector2(0, 60)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	entry.add_child(hbox)
	
	# Información principal
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Nombre de la partida
	var name_label = Label.new()
	name_label.text = save_file.get("display_name", "Partida sin nombre")
	name_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_label)
	
	# Información adicional
	var details_hbox = HBoxContainer.new()
	info_vbox.add_child(details_hbox)
	
	var turn_label = Label.new()
	turn_label.text = "Turno: " + str(save_file.get("turn", "?"))
	turn_label.add_theme_font_size_override("font_size", 10)
	turn_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	details_hbox.add_child(turn_label)
	
	details_hbox.add_child(VSeparator.new())
	
	var date_label = Label.new()
	var formatted_date = SaveLoadManager.format_date(save_file.get("modified_time", 0))
	date_label.text = formatted_date
	date_label.add_theme_font_size_override("font_size", 10)
	date_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	details_hbox.add_child(date_label)
	
	details_hbox.add_child(VSeparator.new())
	
	var size_label = Label.new()
	size_label.text = SaveLoadManager.format_file_size(save_file.get("size", 0))
	size_label.add_theme_font_size_override("font_size", 10)
	size_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	details_hbox.add_child(size_label)
	
	# Botón de selección
	var select_button = Button.new()
	select_button.text = "Seleccionar"
	select_button.custom_minimum_size = Vector2(100, 0)
	select_button.pressed.connect(select_save_file.bind(save_file, entry))
	hbox.add_child(select_button)
	
	return entry

func select_save_file(save_file: Dictionary, entry: Control):
	"""Selecciona un archivo de guardado
	
	Args:
		save_file: Información del archivo seleccionado
		entry: Widget de entrada asociado
	"""
	# Deseleccionar entrada anterior
	for child in saves_list.get_children():
		if child is Panel:
			child.modulate = Color.WHITE
	
	# Marcar como seleccionado
	entry.modulate = Color(1.2, 1.2, 1.0)
	selected_save_file = save_file
	
	# Habilitar botones
	load_button.disabled = false
	delete_button.disabled = false

func load_selected_save():
	"""Carga el archivo seleccionado"""
	if selected_save_file.is_empty():
		show_error_message("No hay archivo seleccionado")
		return
	
	var filename = selected_save_file.get("filename", "")
	if filename.is_empty():
		show_error_message("Archivo inválido seleccionado")
		return
	
	# Emitir señal para cargar el juego
	game_loaded.emit(filename)
	
	# Cerrar la interfaz
	queue_free()

func delete_selected_save():
	"""Elimina el archivo seleccionado después de confirmación"""
	if selected_save_file.is_empty():
		show_error_message("No hay archivo seleccionado")
		return
	
	# Crear diálogo de confirmación
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "¿Está seguro de que desea eliminar la partida guardada?\n\n" + selected_save_file.get("display_name", "")
	dialog.title = "Confirmar eliminación"
	add_child(dialog)
	dialog.popup_centered()
	
	# Conectar confirmación
	dialog.confirmed.connect(_on_delete_confirmed)

func _on_delete_confirmed():
	"""Callback cuando se confirma la eliminación"""
	var filename = selected_save_file.get("filename", "")
	if save_manager.delete_save_file(filename):
		show_success_message("Archivo eliminado exitosamente")
		selected_save_file = {}
		load_button.disabled = true
		delete_button.disabled = true
		refresh_save_list()
	else:
		show_error_message("Error al eliminar archivo: " + save_manager.get_last_error())

func cancel_load():
	"""Cancela la operación de carga"""
	load_cancelled.emit()
	queue_free()

func show_error_message(message: String):
	"""Muestra un mensaje de error temporal"""
	print("LoadGameUI Error: " + message)
	# TODO: Implementar notificación visual

func show_success_message(message: String):
	"""Muestra un mensaje de éxito temporal"""
	print("LoadGameUI Success: " + message)
	# TODO: Implementar notificación visual

# === CALLBACKS ===

func _on_save_list_updated(new_save_files: Array):
	"""Callback cuando se actualiza la lista de archivos"""
	save_files = new_save_files
	populate_saves_list()

func _on_load_completed(success: bool, message: String):
	"""Callback cuando se completa una operación de carga"""
	if success:
		show_success_message(message)
	else:
		show_error_message(message)

# === INPUT HANDLING ===

func _input(event):
	"""Manejo de input para cerrar con ESC"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			cancel_load()
			accept_event()
		elif event.keycode == KEY_ENTER:
			if not load_button.disabled:
				load_selected_save()
				accept_event()