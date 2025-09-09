extends Panel

# RecruitmentPanel - Panel de reclutamiento de unidades para ciudades
# Permite al jugador seleccionar y reclutar diferentes tipos de unidades

# === SEÑALES ===
signal unit_recruited(unit_data: UnitData, city_name: String)
signal recruitment_cancelled()

# === REFERENCIAS A NODOS ===
@onready var title_label: Label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var city_name_label: Label = $VBoxContainer/CityInfoContainer/CityNameLabel
@onready var city_resources_label: Label = $VBoxContainer/CityInfoContainer/CityResourcesLabel
@onready var units_list: VBoxContainer = $VBoxContainer/ContentContainer/UnitsListContainer/UnitsScrollContainer/UnitsList
@onready var unit_name_label: Label = $VBoxContainer/ContentContainer/DetailsContainer/UnitDetailsContainer/UnitNameLabel
@onready var unit_stats_container: VBoxContainer = $VBoxContainer/ContentContainer/DetailsContainer/UnitDetailsContainer/UnitStatsContainer
@onready var recruit_button: Button = $VBoxContainer/ButtonsContainer/RecruitButton
@onready var cancel_button: Button = $VBoxContainer/ButtonsContainer/CancelButton

# === VARIABLES ===
var current_city_name: String = ""
var current_city_data: TownData = null
var selected_unit_data: UnitData = null
var current_resources: Dictionary = {}
var available_units: Array[UnitData] = []

# === INICIALIZACIÓN ===
func _ready():
	setup_connections()
	load_available_units()

func setup_connections():
	"""Conecta las señales de los botones"""
	close_button.pressed.connect(_on_close_pressed)
	cancel_button.pressed.connect(_on_close_pressed)
	recruit_button.pressed.connect(_on_recruit_pressed)

# === MÉTODOS PÚBLICOS ===
func show_for_city(city_name: String, city_data: TownData, resources: Dictionary):
	"""Muestra el panel de reclutamiento para una ciudad específica"""
	current_city_name = city_name
	current_city_data = city_data
	current_resources = resources
	
	# Actualizar información de la ciudad
	city_name_label.text = "Ciudad: " + city_name
	if city_data:
		city_resources_label.text = "Manpower disponible: %d" % city_data.manpower
	else:
		city_resources_label.text = "Manpower disponible: 100"
	
	populate_units_list()
	reset_selection()
	visible = true

func hide_panel():
	"""Oculta el panel de reclutamiento"""
	visible = false
	reset_selection()

# === CARGA DE UNIDADES ===
func load_available_units():
	"""Carga las unidades disponibles desde los archivos de recursos"""
	available_units.clear()
	
	# Definir unidades disponibles con sus costos
	# En una implementación completa, esto se cargaría desde archivos .tres
	var unit_definitions = [
		{
			"nombre": "Pelotón de Infantería",
			"rama": "Infantería", 
			"nivel": 1,
			"tamaño": 50,
			"costo_dinero": 100,
			"costo_comida": 50,
			"costo_municion": 20,
			"manpower_requerido": 50,
			"descripcion": "Unidad básica de infantería. Barata y versátil."
		},
		{
			"nombre": "Compañía de Infantería",
			"rama": "Infantería",
			"nivel": 2, 
			"tamaño": 150,
			"costo_dinero": 250,
			"costo_comida": 120,
			"costo_municion": 60,
			"manpower_requerido": 150,
			"descripcion": "Unidad de infantería más grande y efectiva."
		},
		{
			"nombre": "Pelotón de Caballería",
			"rama": "Caballería",
			"nivel": 1,
			"tamaño": 30,
			"costo_dinero": 200,
			"costo_comida": 80,
			"costo_municion": 15,
			"manpower_requerido": 30,
			"descripcion": "Unidad móvil para reconocimiento y ataques rápidos."
		},
		{
			"nombre": "Batería de Artillería",
			"rama": "Artillería", 
			"nivel": 1,
			"tamaño": 25,
			"costo_dinero": 400,
			"costo_comida": 60,
			"costo_municion": 100,
			"manpower_requerido": 25,
			"descripcion": "Apoyo de fuego pesado para asedios y batallas."
		}
	]
	
	# Crear objetos UnitData a partir de las definiciones
	for definition in unit_definitions:
		var unit_data = UnitData.new()
		unit_data.nombre = definition.nombre
		unit_data.rama = definition.rama
		unit_data.nivel = definition.nivel
		unit_data.tamaño = definition.tamaño
		
		# Asignar costos personalizados
		unit_data.set_meta("costo_dinero", definition.costo_dinero)
		unit_data.set_meta("costo_comida", definition.costo_comida) 
		unit_data.set_meta("costo_municion", definition.costo_municion)
		unit_data.set_meta("manpower_requerido", definition.manpower_requerido)
		unit_data.set_meta("descripcion", definition.descripcion)
		
		available_units.append(unit_data)

func populate_units_list():
	"""Puebla la lista de unidades disponibles"""
	# Limpiar lista existente
	for child in units_list.get_children():
		child.queue_free()
	
	# Filtrar unidades según lo que la ciudad puede sostener
	var sustainable_units = get_sustainable_units()
	
	for unit_data in sustainable_units:
		var unit_entry = create_unit_list_entry(unit_data)
		units_list.add_child(unit_entry)

func get_sustainable_units() -> Array[UnitData]:
	"""Retorna las unidades que la ciudad puede sostener según su nivel"""
	var sustainable = []
	
	if not current_city_data:
		# Si no hay datos de ciudad, permitir solo unidades básicas
		for unit in available_units:
			if unit.nivel <= 1:
				sustainable.append(unit)
		return sustainable
	
	# Verificar unidades sostenibles según el tipo de ciudad
	var max_level = 1
	match current_city_data.tipo:
		"villa", "pueblo", "ciudad_pequeña":
			max_level = 1
		"ciudad_mediana":
			max_level = 2
		"ciudad_grande":
			max_level = 3
		"capital", "metropolis":
			max_level = 4
	
	for unit in available_units:
		if unit.nivel <= max_level:
			sustainable.append(unit)
	
	return sustainable

func create_unit_list_entry(unit_data: UnitData) -> Control:
	"""Crea una entrada en la lista de unidades"""
	var entry = VBoxContainer.new()
	entry.add_theme_constant_override("separation", 5)
	
	# Botón principal de la unidad
	var unit_button = Button.new()
	unit_button.text = unit_data.nombre
	unit_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	unit_button.pressed.connect(_on_unit_selected.bind(unit_data))
	
	# Container para costos
	var cost_container = HBoxContainer.new()
	cost_container.add_theme_constant_override("separation", 10)
	
	# Mostrar costos
	var cost_dinero = unit_data.get_meta("costo_dinero", 0)
	var cost_comida = unit_data.get_meta("costo_comida", 0)
	var cost_municion = unit_data.get_meta("costo_municion", 0)
	
	var cost_label = Label.new()
	cost_label.text = "💰%d 🍞%d ⚔️%d" % [cost_dinero, cost_comida, cost_municion]
	cost_label.add_theme_font_size_override("font_size", 10)
	
	# Verificar si se puede costear
	var can_afford = can_afford_unit(unit_data)
	if not can_afford:
		unit_button.disabled = true
		cost_label.add_theme_color_override("font_color", Color.RED)
	else:
		cost_label.add_theme_color_override("font_color", Color.WHITE)
	
	cost_container.add_child(cost_label)
	
	entry.add_child(unit_button)
	entry.add_child(cost_container)
	
	# Añadir separador
	var separator = HSeparator.new()
	entry.add_child(separator)
	
	return entry

# === SELECCIÓN DE UNIDADES ===
func _on_unit_selected(unit_data: UnitData):
	"""Callback cuando se selecciona una unidad"""
	selected_unit_data = unit_data
	update_unit_details()
	recruit_button.disabled = not can_afford_unit(unit_data)

func update_unit_details():
	"""Actualiza los detalles de la unidad seleccionada"""
	if not selected_unit_data:
		unit_name_label.text = "Selecciona una unidad"
		# Limpiar detalles
		for child in unit_stats_container.get_children():
			child.queue_free()
		return
	
	unit_name_label.text = selected_unit_data.nombre
	
	# Limpiar detalles anteriores
	for child in unit_stats_container.get_children():
		child.queue_free()
	
	# Información de la unidad
	var info_data = {
		"Rama": selected_unit_data.rama,
		"Tamaño": str(selected_unit_data.tamaño),
		"Nivel": str(selected_unit_data.nivel),
		"": "",  # Separador
		"Costo en Dinero": str(selected_unit_data.get_meta("costo_dinero", 0)),
		"Costo en Comida": str(selected_unit_data.get_meta("costo_comida", 0)), 
		"Costo en Munición": str(selected_unit_data.get_meta("costo_municion", 0)),
		"Manpower Requerido": str(selected_unit_data.get_meta("manpower_requerido", 0)),
		" ": "",  # Separador
		"Descripción": selected_unit_data.get_meta("descripcion", "Sin descripción")
	}
	
	for key in info_data:
		if key == "" or key == " ":
			# Separador visual
			var separator = HSeparator.new()
			unit_stats_container.add_child(separator)
			continue
			
		var info_line = HBoxContainer.new()
		
		var key_label = Label.new()
		key_label.text = key + ":"
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.add_theme_font_size_override("font_size", 11)
		
		var value_label = Label.new()
		value_label.text = str(info_data[key])
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override("font_size", 11)
		
		# Color especial para descripción
		if key == "Descripción":
			value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			value_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
		
		info_line.add_child(key_label)
		info_line.add_child(value_label)
		unit_stats_container.add_child(info_line)

# === VALIDACIÓN DE RECURSOS ===
func can_afford_unit(unit_data: UnitData) -> bool:
	"""Verifica si se pueden costear los recursos para reclutar la unidad"""
	var cost_dinero = unit_data.get_meta("costo_dinero", 0)
	var cost_comida = unit_data.get_meta("costo_comida", 0)
	var cost_municion = unit_data.get_meta("costo_municion", 0)
	var manpower_required = unit_data.get_meta("manpower_requerido", 0)
	
	# Verificar recursos
	var has_dinero = current_resources.get("dinero", 0) >= cost_dinero
	var has_comida = current_resources.get("comida", 0) >= cost_comida
	var has_municion = current_resources.get("municion", 0) >= cost_municion
	
	# Verificar manpower de la ciudad
	var has_manpower = true
	if current_city_data:
		has_manpower = current_city_data.manpower >= manpower_required
	
	return has_dinero and has_comida and has_municion and has_manpower

func get_recruitment_costs(unit_data: UnitData) -> Dictionary:
	"""Retorna los costos de reclutamiento de una unidad"""
	return {
		"dinero": unit_data.get_meta("costo_dinero", 0),
		"comida": unit_data.get_meta("costo_comida", 0),
		"municion": unit_data.get_meta("costo_municion", 0),
		"manpower": unit_data.get_meta("manpower_requerido", 0)
	}

# === CALLBACKS DE BOTONES ===
func _on_recruit_pressed():
	"""Callback cuando se presiona el botón de reclutar"""
	if not selected_unit_data or not can_afford_unit(selected_unit_data):
		return
	
	# Emitir señal de reclutamiento
	unit_recruited.emit(selected_unit_data, current_city_name)
	hide_panel()

func _on_close_pressed():
	"""Callback cuando se cierra el panel"""
	recruitment_cancelled.emit()
	hide_panel()

func reset_selection():
	"""Resetea la selección actual"""
	selected_unit_data = null
	unit_name_label.text = "Selecciona una unidad"
	recruit_button.disabled = true
	
	# Limpiar detalles
	for child in unit_stats_container.get_children():
		child.queue_free()

# === MÉTODOS PARA EXTENSIÓN (MODDERS) ===
"""
Para extender el sistema de reclutamiento:

1. Agregar nuevos tipos de unidades:
   - Crear archivos .tres en Data/Units/ con la estructura UnitData
   - Modificar load_available_units() para cargar desde archivos
   - Agregar iconos correspondientes en Assets/Icons/

2. Modificar costos de unidades:
   - Editar los valores en unit_definitions en load_available_units()
   - O cargar costos desde archivos de configuración

3. Agregar nuevos recursos:
   - Añadir campos al diccionario current_resources
   - Modificar can_afford_unit() para verificar nuevos recursos
   - Actualizar create_unit_list_entry() para mostrar costos

4. Cambiar restricciones de ciudad:
   - Modificar get_sustainable_units() para diferentes lógicas
   - Editar los niveles máximos por tipo de ciudad

5. Personalizar UI:
   - Modificar RecruitmentPanel.tscn para cambiar diseño
   - Agregar nuevos elementos en unit_stats_container
"""