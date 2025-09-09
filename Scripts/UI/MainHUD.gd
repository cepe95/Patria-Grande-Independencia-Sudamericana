extends Control

# MainHUD - Interfaz principal estratégica del juego
# Maneja la comunicación entre todos los paneles de la interfaz

# === REFERENCIAS A NODOS ===
@onready var strategic_map: Node2D = $StrategicMap
@onready var resource_bar: Panel = $UI/ResourceBar
@onready var city_unit_list_panel: Panel = $UI/CityUnitListPanel
@onready var details_panel: Panel = $UI/DetailsPanel
@onready var event_panel: Panel = $UI/EventPanel
@onready var pause_menu: Control = $UI/PauseMenu

# Referencias a elementos específicos de los paneles
@onready var dinero_label: Label = $UI/ResourceBar/Content/ResourcesContainer/DineroLabel
@onready var comida_label: Label = $UI/ResourceBar/Content/ResourcesContainer/ComidaLabel
@onready var municion_label: Label = $UI/ResourceBar/Content/ResourcesContainer/MunicionLabel
@onready var date_label: Label = $UI/ResourceBar/Content/DateTurnContainer/DateLabel
@onready var turn_label: Label = $UI/ResourceBar/Content/DateTurnContainer/TurnLabel

@onready var cities_list: VBoxContainer = $UI/CityUnitListPanel/VBoxContainer/TabContainer/Ciudades/CitiesList
@onready var units_list: VBoxContainer = $UI/CityUnitListPanel/VBoxContainer/TabContainer/Unidades/UnitsList

@onready var details_title: Label = $UI/DetailsPanel/VBoxContainer/HeaderContainer/TitleLabel
@onready var details_content: VBoxContainer = $UI/DetailsPanel/VBoxContainer/ContentContainer/DetailsContent
@onready var close_details_button: Button = $UI/DetailsPanel/VBoxContainer/HeaderContainer/CloseButton

@onready var events_log: VBoxContainer = $UI/EventPanel/VBoxContainer/EventsContainer/EventsList/EventsLog
@onready var next_turn_button: Button = $UI/EventPanel/VBoxContainer/EventsContainer/QuickActionsContainer/QuickActionButtons/NextTurnButton
@onready var pause_button: Button = $UI/EventPanel/VBoxContainer/EventsContainer/QuickActionsContainer/QuickActionButtons/PauseButton

# === VARIABLES DE ESTADO ===
var selected_unit: Node = null
var selected_city: Node = null
var current_resources: Dictionary = {}
var current_turn: int = 1

# === INICIALIZACIÓN ===
func _ready():
	print("✓ MainHUD inicializado")
	setup_ui_connections()
	setup_strategic_map_connections()
	initialize_resource_display()
	populate_city_unit_lists()
	add_initial_events()

func setup_ui_connections():
	"""Conecta las señales de los elementos de la UI"""
	# Botón de cerrar panel de detalles
	close_details_button.pressed.connect(_on_close_details_pressed)
	
	# Botones de acciones rápidas
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	
	# Input de teclado para pausar (ESC)
	set_process_unhandled_input(true)

func setup_strategic_map_connections():
	"""Conecta las señales del mapa estratégico"""
	if strategic_map:
		# Conectar señal de selección de división si existe
		var divisions = strategic_map.get_node_or_null("UnitsContainer")
		if divisions:
			for child in divisions.get_children():
				if child.has_signal("division_seleccionada"):
					child.division_seleccionada.connect(_on_unit_selected)
		
		# Conectar señal de cambio de fecha del GameClock
		var game_clock = strategic_map.get_node_or_null("GameClock")
		if game_clock and game_clock.has_signal("date_changed"):
			game_clock.date_changed.connect(_on_date_changed)

# === MANEJO DE RECURSOS ===
func initialize_resource_display():
	"""Inicializa la visualización de recursos"""
	current_resources = {
		"dinero": 1000,
		"comida": 500,
		"municion": 200
	}
	update_resource_display()

func update_resource_display():
	"""Actualiza la visualización de recursos en la barra superior"""
	dinero_label.text = "Dinero: %d" % current_resources.get("dinero", 0)
	comida_label.text = "Comida: %d" % current_resources.get("comida", 0)
	municion_label.text = "Munición: %d" % current_resources.get("municion", 0)

func update_date_turn_display(date_text: String = "", turn: int = -1):
	"""Actualiza la visualización de fecha y turno"""
	if date_text != "":
		date_label.text = "Fecha: %s" % date_text
	if turn > 0:
		current_turn = turn
		turn_label.text = "Turno: %d" % current_turn

# === LISTAS DE CIUDADES Y UNIDADES ===
func populate_city_unit_lists():
	"""Puebla las listas de ciudades y unidades con datos del mapa"""
	populate_cities_list()
	populate_units_list()

func populate_cities_list():
	"""Puebla la lista de ciudades"""
	# Limpiar lista existente
	for child in cities_list.get_children():
		child.queue_free()
	
	# TODO: Obtener ciudades reales del mapa estratégico
	# Por ahora, agregar ciudades de ejemplo
	var example_cities = [
		{"nombre": "Buenos Aires", "tipo": "Capital", "faccion": "Patriota"},
		{"nombre": "Córdoba", "tipo": "Ciudad", "faccion": "Realista"},
		{"nombre": "Montevideo", "tipo": "Puerto", "faccion": "Patriota"}
	]
	
	for city_data in example_cities:
		add_city_to_list(city_data)

func populate_units_list():
	"""Puebla la lista de unidades"""
	# Limpiar lista existente
	for child in units_list.get_children():
		child.queue_free()
	
	# Obtener unidades del mapa estratégico
	if strategic_map:
		var units_container = strategic_map.get_node_or_null("UnitsContainer")
		if units_container:
			for unit in units_container.get_children():
				if unit.has_method("get_button_data") or unit.get("data"):
					add_unit_to_list(unit)

func add_city_to_list(city_data: Dictionary):
	"""Agrega una ciudad a la lista"""
	var city_entry = create_list_entry(
		city_data.get("nombre", "Ciudad Desconocida"),
		city_data.get("tipo", "Desconocido"),
		city_data.get("faccion", "Neutral"),
		"city"
	)
	cities_list.add_child(city_entry)

func add_unit_to_list(unit_node: Node):
	"""Agrega una unidad a la lista"""
	var unit_data = unit_node.get("data")
	if not unit_data:
		return
	
	var unit_entry = create_list_entry(
		unit_data.get("nombre", "Unidad Desconocida"),
		"División", # Tipo por defecto
		unit_data.get("faccion", "Neutral"),
		"unit",
		unit_node
	)
	units_list.add_child(unit_entry)

func create_list_entry(name: String, type: String, faction: String, entry_type: String, reference_node: Node = null) -> Control:
	"""Crea una entrada para las listas de ciudades/unidades"""
	var entry = HBoxContainer.new()
	entry.add_theme_constant_override("separation", 10)
	
	# Icono de facción/bandera
	var icon = TextureRect.new()
	icon.custom_min_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Cargar icono según facción
	var icon_path = ""
	match faction:
		"Patriota":
			icon_path = "res://Assets/Icons/Division Patriota.png"
		"Realista":
			icon_path = "res://Assets/Icons/Division Realista.png"
		_:
			icon_path = "res://Assets/Icons/Division Patriota.png"  # Por defecto
	
	var texture = load(icon_path) as Texture2D
	if texture:
		icon.texture = texture
	
	# Información de texto
	var info_container = VBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 12)
	
	var type_label = Label.new()
	type_label.text = "%s (%s)" % [type, faction]
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	info_container.add_child(name_label)
	info_container.add_child(type_label)
	
	# Botón de selección
	var select_button = Button.new()
	select_button.text = "Ver"
	select_button.custom_min_size = Vector2(50, 30)
	
	# Conectar señal del botón
	select_button.pressed.connect(_on_list_entry_selected.bind(entry_type, name, reference_node))
	
	entry.add_child(icon)
	entry.add_child(info_container)
	entry.add_child(select_button)
	
	return entry

# === PANEL DE DETALLES ===
func show_details(title: String, content_data: Dictionary):
	"""Muestra el panel de detalles con la información proporcionada"""
	details_title.text = title
	
	# Limpiar contenido anterior
	for child in details_content.get_children():
		child.queue_free()
	
	# Agregar nuevo contenido
	for key in content_data:
		var info_line = HBoxContainer.new()
		
		var key_label = Label.new()
		key_label.text = str(key) + ":"
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.add_theme_font_size_override("font_size", 12)
		
		var value_label = Label.new()
		value_label.text = str(content_data[key])
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override("font_size", 12)
		
		info_line.add_child(key_label)
		info_line.add_child(value_label)
		details_content.add_child(info_line)
	
	details_panel.visible = true

func hide_details():
	"""Oculta el panel de detalles"""
	details_panel.visible = false
	selected_unit = null
	selected_city = null

# === MANEJO DE EVENTOS ===
func add_event(message: String, event_type: String = "info"):
	"""Agrega un evento al log de eventos"""
	var event_entry = HBoxContainer.new()
	
	var time_label = Label.new()
	time_label.text = "[Turno %d]" % current_turn
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	time_label.custom_min_size = Vector2(80, 0)
	
	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_font_size_override("font_size", 11)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Color según tipo de evento
	match event_type:
		"warning":
			message_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		"error":
			message_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		"success":
			message_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		_:  # info
			message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	event_entry.add_child(time_label)
	event_entry.add_child(message_label)
	events_log.add_child(event_entry)
	
	# Scroll automático al final
	await get_tree().process_frame
	var scroll_container = events_log.get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func add_initial_events():
	"""Agrega eventos iniciales de ejemplo"""
	add_event("¡Bienvenido a Patria Grande!", "success")
	add_event("El movimiento independentista se extiende por Sudamérica", "info")
	add_event("Consulta el panel de ciudades y unidades para comenzar", "info")

# === SEÑALES Y CALLBACKS ===
func _on_unit_selected(unit_node: Node):
	"""Callback cuando se selecciona una unidad en el mapa"""
	selected_unit = unit_node
	selected_city = null
	
	var unit_data = unit_node.get("data")
	if unit_data:
		var details = {
			"Nombre": unit_data.get("nombre", "Desconocido"),
			"Facción": unit_data.get("faccion", "Neutral"),
			"Rama Principal": unit_data.get("rama_principal", "Desconocida"),
			"Cantidad Total": unit_data.get("cantidad_total", 0),
			"Movilidad": unit_data.get("movilidad", 0),
			"Moral": unit_data.get("moral", 0),
			"Experiencia": unit_data.get("experiencia", 0)
		}
		show_details("División: " + unit_data.get("nombre", "Desconocida"), details)
		add_event("División seleccionada: " + unit_data.get("nombre", "Desconocida"), "info")

func _on_list_entry_selected(entry_type: String, name: String, reference_node: Node):
	"""Callback cuando se selecciona una entrada de las listas"""
	match entry_type:
		"unit":
			if reference_node:
				_on_unit_selected(reference_node)
		"city":
			# TODO: Implementar selección de ciudad
			var city_details = {
				"Nombre": name,
				"Tipo": "Ciudad",
				"Estado": "Controlada",
				"Población": "15,000",
				"Recursos": "Comida, Dinero",
				"Guarnición": "1 Compañía"
			}
			show_details("Ciudad: " + name, city_details)
			add_event("Ciudad seleccionada: " + name, "info")

func _on_close_details_pressed():
	"""Callback para cerrar el panel de detalles"""
	hide_details()

func _on_next_turn_pressed():
	"""Callback para avanzar al siguiente turno"""
	current_turn += 1
	update_date_turn_display("", current_turn)
	add_event("Nuevo turno iniciado", "success")
	
	# TODO: Aquí se procesarían los eventos del turno
	print("✓ Avanzando al turno: ", current_turn)

func _on_pause_pressed():
	"""Callback para pausar el juego"""
	pause_menu.visible = true
	add_event("Juego pausado", "info")

func _on_date_changed(new_date):
	"""Callback cuando cambia la fecha en el GameClock"""
	if new_date and new_date.has_method("as_string"):
		update_date_turn_display(new_date.as_string())

func _unhandled_input(event):
	"""Manejo de input no procesado (teclas de acceso rápido)"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if details_panel.visible:
					hide_details()
				else:
					_on_pause_pressed()
			KEY_SPACE:
				_on_next_turn_pressed()

# === MÉTODOS PLACEHOLDER PARA INTEGRACIÓN FUTURA ===

func move_unit_to_position(unit: Node, target_position: Vector2):
	"""PLACEHOLDER: Mover unidad a posición específica"""
	print("TODO: Implementar movimiento de unidad a posición: ", target_position)
	add_event("Movimiento de unidad ordenado", "info")

func start_battle(attacking_unit: Node, defending_unit: Node):
	"""PLACEHOLDER: Iniciar batalla entre unidades"""
	print("TODO: Implementar sistema de batalla")
	add_event("¡Batalla iniciada!", "warning")

func recruit_unit_in_city(city_name: String, unit_type: String):
	"""PLACEHOLDER: Reclutar unidad en ciudad"""
	print("TODO: Implementar reclutamiento de unidades")
	add_event("Reclutamiento ordenado en " + city_name, "info")

func manage_city_production(city_name: String, resource_type: String):
	"""PLACEHOLDER: Gestionar producción de ciudad"""
	print("TODO: Implementar gestión de producción urbana")
	add_event("Producción ajustada en " + city_name, "info")

func show_diplomacy_panel():
	"""PLACEHOLDER: Mostrar panel de diplomacia"""
	print("TODO: Implementar panel de diplomacia")
	add_event("Panel de diplomacia solicitado", "info")

func show_technology_tree():
	"""PLACEHOLDER: Mostrar árbol de tecnologías"""
	print("TODO: Implementar árbol de tecnologías")
	add_event("Investigación tecnológica solicitada", "info")

func save_game():
	"""PLACEHOLDER: Guardar partida"""
	print("TODO: Implementar sistema de guardado")
	add_event("Partida guardada", "success")

func load_game():
	"""PLACEHOLDER: Cargar partida"""
	print("TODO: Implementar sistema de carga")
	add_event("Partida cargada", "success")