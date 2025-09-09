extends Panel
class_name TechnologyPanel

# Panel de interfaz para el árbol tecnológico

signal technology_selected(technology: TechnologyData)
signal research_started(technology_id: String)

# Referencias a nodos UI
@onready var title_label: Label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var tree_scroll: ScrollContainer = $VBoxContainer/TreeContainer/TreeScroll
@onready var tree_container: Control = $VBoxContainer/TreeContainer/TreeScroll/TreeGrid
@onready var details_container: VBoxContainer = $VBoxContainer/DetailsContainer
@onready var tech_name_label: Label = $VBoxContainer/DetailsContainer/TechNameLabel
@onready var tech_description_label: Label = $VBoxContainer/DetailsContainer/TechDescriptionLabel
@onready var tech_cost_label: Label = $VBoxContainer/DetailsContainer/TechCostLabel
@onready var tech_progress_bar: ProgressBar = $VBoxContainer/DetailsContainer/ProgressContainer/TechProgressBar
@onready var tech_progress_label: Label = $VBoxContainer/DetailsContainer/ProgressContainer/TechProgressLabel
@onready var research_button: Button = $VBoxContainer/DetailsContainer/ResearchButton
@onready var resources_label: Label = $VBoxContainer/HeaderContainer/ResourcesLabel

# Estado del panel
var technology_manager: TechnologyManager
var current_faction: String = "Patriota"
var selected_technology: TechnologyData = null
var technology_buttons: Dictionary = {}

# Constantes de diseño
const TECH_BUTTON_SIZE = Vector2(120, 80)
const TECH_SPACING_X = 150
const TECH_SPACING_Y = 100
const TREE_MARGIN = 50

func _ready():
	setup_ui()
	connect_signals()
	hide()  # Oculto por defecto

func setup_ui():
	"""Configura la interfaz inicial"""
	title_label.text = "Árbol Tecnológico"
	close_button.text = "✕"
	research_button.text = "Iniciar Investigación"
	
	# Configurar el contenedor del árbol
	tree_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func connect_signals():
	"""Conecta las señales de la UI"""
	close_button.pressed.connect(_on_close_button_pressed)
	research_button.pressed.connect(_on_research_button_pressed)

func set_technology_manager(manager: TechnologyManager):
	"""Establece el gestor de tecnologías"""
	technology_manager = manager
	if technology_manager:
		technology_manager.technology_completed.connect(_on_technology_completed)
		technology_manager.technology_started.connect(_on_technology_started)
		technology_manager.research_progress_changed.connect(_on_research_progress_changed)
		refresh_technology_tree()

func show_panel():
	"""Muestra el panel y actualiza los datos"""
	visible = true
	refresh_technology_tree()
	update_resources_display()

func hide_panel():
	"""Oculta el panel"""
	visible = false

func refresh_technology_tree():
	"""Actualiza la visualización del árbol tecnológico"""
	if not technology_manager:
		return
	
	clear_technology_buttons()
	create_technology_buttons()
	update_technology_states()

func clear_technology_buttons():
	"""Limpia los botones de tecnología existentes"""
	for button in technology_buttons.values():
		if is_instance_valid(button):
			button.queue_free()
	technology_buttons.clear()

func create_technology_buttons():
	"""Crea los botones para cada tecnología"""
	var technologies = technology_manager.get_all_technologies()
	
	for tech in technologies:
		create_technology_button(tech)

func create_technology_button(tech: TechnologyData) -> Control:
	"""Crea un botón para una tecnología específica"""
	var button_container = Control.new()
	var tech_button = Button.new()
	
	# Configurar el botón
	tech_button.text = tech.nombre
	tech_button.size = TECH_BUTTON_SIZE
	tech_button.custom_min_size = TECH_BUTTON_SIZE
	tech_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Posición en el árbol
	var pos_x = TREE_MARGIN + tech.posicion_x * TECH_SPACING_X
	var pos_y = TREE_MARGIN + tech.posicion_y * TECH_SPACING_Y
	button_container.position = Vector2(pos_x, pos_y)
	button_container.size = TECH_BUTTON_SIZE
	
	# Conectar señal
	tech_button.pressed.connect(_on_technology_button_pressed.bind(tech))
	
	button_container.add_child(tech_button)
	tree_container.add_child(button_container)
	
	# Guardar referencia
	technology_buttons[tech.id] = tech_button
	
	return button_container

func update_technology_states():
	"""Actualiza el estado visual de las tecnologías"""
	if not technology_manager:
		return
	
	var completed = technology_manager.get_completed_technologies(current_faction)
	var available = technology_manager.get_available_technologies(current_faction)
	
	for tech in technology_manager.get_all_technologies():
		var button = technology_buttons.get(tech.id)
		if not button:
			continue
		
		# Colorear según estado
		if tech.completada or tech.id in completed:
			button.modulate = Color.GREEN
			button.disabled = true
		elif tech.investigando:
			button.modulate = Color.YELLOW
			button.disabled = true
		elif tech in available:
			button.modulate = Color.WHITE
			button.disabled = false
		else:
			button.modulate = Color.GRAY
			button.disabled = true

func update_resources_display():
	"""Actualiza la visualización de recursos"""
	if not technology_manager:
		return
	
	var points_per_turn = technology_manager.get_research_points_per_turn(current_faction)
	resources_label.text = "Investigación: %d/turno" % points_per_turn

func show_technology_details(tech: TechnologyData):
	"""Muestra los detalles de una tecnología"""
	selected_technology = tech
	
	tech_name_label.text = tech.nombre
	tech_description_label.text = tech.descripcion
	
	# Mostrar costos
	var cost_text = "Costo: %d puntos de investigación" % tech.costo_investigacion
	if tech.recursos_requeridos.size() > 0:
		cost_text += "\nRecursos: "
		for resource in tech.recursos_requeridos:
			cost_text += "%s: %d  " % [resource, tech.recursos_requeridos[resource]]
	
	if tech.prerequisitos.size() > 0:
		cost_text += "\nRequiere: " + ", ".join(tech.prerequisitos)
	
	tech_cost_label.text = cost_text
	
	# Mostrar progreso
	if tech.investigando:
		tech_progress_bar.value = tech.get_progreso_porcentaje() * 100
		tech_progress_label.text = "%d/%d (%d%%)" % [
			tech.progreso_actual, 
			tech.costo_investigacion, 
			int(tech.get_progreso_porcentaje() * 100)
		]
		tech_progress_bar.visible = true
		tech_progress_label.visible = true
	else:
		tech_progress_bar.visible = false
		tech_progress_label.visible = false
	
	# Estado del botón de investigación
	update_research_button_state()

func update_research_button_state():
	"""Actualiza el estado del botón de investigación"""
	if not selected_technology or not technology_manager:
		research_button.disabled = true
		research_button.text = "Selecciona una tecnología"
		return
	
	var tech = selected_technology
	var completed = technology_manager.get_completed_technologies(current_faction)
	
	if tech.completada or tech.id in completed:
		research_button.disabled = true
		research_button.text = "Completada"
	elif tech.investigando:
		research_button.disabled = true
		research_button.text = "En investigación"
	elif not tech.puede_ser_investigada(completed):
		research_button.disabled = true
		research_button.text = "Requisitos no cumplidos"
	elif not technology_manager.has_required_resources(current_faction, tech.recursos_requeridos):
		research_button.disabled = true
		research_button.text = "Recursos insuficientes"
	else:
		research_button.disabled = false
		research_button.text = "Iniciar Investigación"

# === CALLBACKS ===

func _on_close_button_pressed():
	"""Callback al presionar el botón de cerrar"""
	hide_panel()

func _on_technology_button_pressed(tech: TechnologyData):
	"""Callback al presionar un botón de tecnología"""
	show_technology_details(tech)
	technology_selected.emit(tech)

func _on_research_button_pressed():
	"""Callback al presionar el botón de investigación"""
	if selected_technology and technology_manager:
		var success = technology_manager.start_research(current_faction, selected_technology.id)
		if success:
			research_started.emit(selected_technology.id)
			refresh_technology_tree()
			update_research_button_state()

func _on_technology_completed(tech: TechnologyData):
	"""Callback cuando se completa una investigación"""
	refresh_technology_tree()
	if selected_technology and selected_technology.id == tech.id:
		show_technology_details(tech)

func _on_technology_started(tech: TechnologyData):
	"""Callback cuando se inicia una investigación"""
	refresh_technology_tree()
	if selected_technology and selected_technology.id == tech.id:
		show_technology_details(tech)

func _on_research_progress_changed(tech: TechnologyData, progress: float):
	"""Callback cuando cambia el progreso de investigación"""
	if selected_technology and selected_technology.id == tech.id:
		show_technology_details(tech)

# === MÉTODOS PÚBLICOS ===

func set_current_faction(faction_name: String):
	"""Establece la facción actual"""
	current_faction = faction_name
	if visible:
		refresh_technology_tree()

func get_selected_technology() -> TechnologyData:
	"""Obtiene la tecnología seleccionada"""
	return selected_technology