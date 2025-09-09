extends Panel

# DiplomacyPanel - Panel de diplomacia y relaciones exteriores
# Muestra relaciones, propuestas, eventos y permite gestión diplomática

@onready var nations_list: VBoxContainer = $VBoxContainer/ContentContainer/MainContent/NationsContainer/NationsList
@onready var relations_display: VBoxContainer = $VBoxContainer/ContentContainer/MainContent/RelationsContainer/RelationsDisplay
@onready var proposals_list: VBoxContainer = $VBoxContainer/ContentContainer/MainContent/ProposalsContainer/ProposalsList
@onready var events_log: VBoxContainer = $VBoxContainer/ContentContainer/MainContent/EventsContainer/EventsList
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var panel_title: Label = $VBoxContainer/HeaderContainer/TitleLabel

# Referencias al sistema de diplomacia
var diplomacy_system: Node
var main_hud: Node
var current_faction: String = "Patriota"  # Facción del jugador por defecto

signal diplomacy_panel_closed

func _ready():
	print("✓ DiplomacyPanel inicializado")
	setup_ui_connections()
	hide()  # Panel oculto por defecto

func setup_ui_connections():
	"""Conecta las señales de la UI"""
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func initialize(hud_reference: Node):
	"""Inicializa el panel con referencias necesarias"""
	main_hud = hud_reference
	diplomacy_system = get_node_or_null("/root/DiplomacySystem")
	if not diplomacy_system:
		print("⚠ Warning: DiplomacySystem no encontrado")
	else:
		# Conectar señales del sistema de diplomacia
		diplomacy_system.relation_changed.connect(_on_relation_changed)
		diplomacy_system.proposal_created.connect(_on_proposal_created)
		diplomacy_system.diplomatic_event_occurred.connect(_on_event_occurred)

func show_panel():
	"""Muestra el panel de diplomacia"""
	show()
	refresh_all_content()
	if main_hud:
		main_hud.add_event("Panel de diplomacia abierto", "info")

func hide_panel():
	"""Oculta el panel de diplomacia"""
	hide()
	diplomacy_panel_closed.emit()

func refresh_all_content():
	"""Actualiza todo el contenido del panel"""
	refresh_nations_list()
	refresh_relations_display()
	refresh_proposals_list()
	refresh_events_log()

func refresh_nations_list():
	"""Actualiza la lista de naciones"""
	if not nations_list or not diplomacy_system:
		return
	
	# Limpiar lista anterior
	for child in nations_list.get_children():
		child.queue_free()
	
	# Obtener facciones del FactionManager
	var faction_manager = get_node_or_null("/root/FactionManager")
	if not faction_manager:
		return
	
	var factions = faction_manager.facciones
	
	for faction_name in factions:
		if faction_name == current_faction:
			continue  # No mostrar la propia facción
		
		var faction_data = factions[faction_name]
		var nation_entry = create_nation_entry(faction_name, faction_data)
		nations_list.add_child(nation_entry)

func create_nation_entry(faction_name: String, faction_data: FactionData) -> Control:
	"""Crea una entrada visual para una nación"""
	var entry = HBoxContainer.new()
	entry.custom_min_size = Vector2(0, 60)
	
	# Bandera/Ícono de la facción
	var icon = TextureRect.new()
	icon.custom_min_size = Vector2(40, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Cargar bandera si existe
	if faction_data.bandera_path != "":
		var texture = load(faction_data.bandera_path) as Texture2D
		if texture:
			icon.texture = texture
	
	# Información de la nación
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = faction_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", faction_data.color)
	
	var ideology_label = Label.new()
	ideology_label.text = "Ideología: " + faction_data.ideologia
	ideology_label.add_theme_font_size_override("font_size", 10)
	ideology_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	# Estado de relación
	var relation = diplomacy_system.get_relation(current_faction, faction_name)
	var relation_label = Label.new()
	if relation:
		relation_label.text = "Relación: " + relation.get_relation_name() + " (" + str(relation.relation_level) + ")"
		relation_label.add_theme_color_override("font_color", relation.get_relation_color())
	else:
		relation_label.text = "Relación: Sin establecer"
		relation_label.add_theme_color_override("font_color", Color.GRAY)
	relation_label.add_theme_font_size_override("font_size", 10)
	
	info_container.add_child(name_label)
	info_container.add_child(ideology_label)
	info_container.add_child(relation_label)
	
	# Botones de acción
	var actions_container = VBoxContainer.new()
	actions_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	var diplomacy_button = Button.new()
	diplomacy_button.text = "Diplomacia"
	diplomacy_button.custom_min_size = Vector2(100, 25)
	diplomacy_button.pressed.connect(_on_diplomacy_button_pressed.bind(faction_name))
	
	var details_button = Button.new()
	details_button.text = "Detalles"
	details_button.custom_min_size = Vector2(100, 25)
	details_button.pressed.connect(_on_nation_details_pressed.bind(faction_name))
	
	actions_container.add_child(diplomacy_button)
	actions_container.add_child(details_button)
	
	entry.add_child(icon)
	entry.add_child(info_container)
	entry.add_child(actions_container)
	
	# Separador visual
	var separator = HSeparator.new()
	separator.modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	var wrapper = VBoxContainer.new()
	wrapper.add_child(entry)
	wrapper.add_child(separator)
	
	return wrapper

func refresh_relations_display():
	"""Actualiza la visualización de relaciones"""
	if not relations_display or not diplomacy_system:
		return
	
	# Limpiar display anterior
	for child in relations_display.get_children():
		child.queue_free()
	
	var faction_relations = diplomacy_system.get_faction_relations(current_faction)
	
	if faction_relations.is_empty():
		var no_relations_label = Label.new()
		no_relations_label.text = "No hay relaciones establecidas"
		no_relations_label.add_theme_color_override("font_color", Color.GRAY)
		relations_display.add_child(no_relations_label)
		return
	
	for relation in faction_relations:
		var other_faction = relation.faction_a if relation.faction_a != current_faction else relation.faction_b
		var relation_entry = create_relation_entry(relation, other_faction)
		relations_display.add_child(relation_entry)

func create_relation_entry(relation: DiplomaticRelationData, other_faction: String) -> Control:
	"""Crea una entrada visual para una relación"""
	var entry = VBoxContainer.new()
	
	# Encabezado de la relación
	var header = HBoxContainer.new()
	
	var faction_label = Label.new()
	faction_label.text = other_faction
	faction_label.add_theme_font_size_override("font_size", 12)
	faction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var status_label = Label.new()
	status_label.text = relation.get_relation_name()
	status_label.add_theme_color_override("font_color", relation.get_relation_color())
	status_label.add_theme_font_size_override("font_size", 12)
	
	header.add_child(faction_label)
	header.add_child(status_label)
	
	# Detalles de la relación
	var details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 2)
	
	var level_label = Label.new()
	level_label.text = "Nivel: " + str(relation.relation_level) + "/100"
	level_label.add_theme_font_size_override("font_size", 10)
	
	var modifiers_text = []
	if relation.trade_modifier != 1.0:
		modifiers_text.append("Comercio: x" + str(relation.trade_modifier))
	if relation.military_access:
		modifiers_text.append("Acceso militar")
	if relation.technology_sharing:
		modifiers_text.append("Intercambio tecnológico")
	if relation.defensive_pact:
		modifiers_text.append("Pacto defensivo")
	
	if not modifiers_text.is_empty():
		var modifiers_label = Label.new()
		modifiers_label.text = "Modificadores: " + ", ".join(modifiers_text)
		modifiers_label.add_theme_font_size_override("font_size", 10)
		modifiers_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		details.add_child(modifiers_label)
	
	details.add_child(level_label)
	
	entry.add_child(header)
	entry.add_child(details)
	
	# Separador
	var separator = HSeparator.new()
	separator.modulate = Color(0.3, 0.3, 0.3, 0.8)
	entry.add_child(separator)
	
	return entry

func refresh_proposals_list():
	"""Actualiza la lista de propuestas"""
	if not proposals_list or not diplomacy_system:
		return
	
	# Limpiar lista anterior
	for child in proposals_list.get_children():
		child.queue_free()
	
	var pending_proposals = diplomacy_system.get_pending_proposals(current_faction)
	
	if pending_proposals.is_empty():
		var no_proposals_label = Label.new()
		no_proposals_label.text = "No hay propuestas pendientes"
		no_proposals_label.add_theme_color_override("font_color", Color.GRAY)
		proposals_list.add_child(no_proposals_label)
		return
	
	for proposal in pending_proposals:
		var proposal_entry = create_proposal_entry(proposal)
		proposals_list.add_child(proposal_entry)

func create_proposal_entry(proposal: DiplomaticProposalData) -> Control:
	"""Crea una entrada visual para una propuesta"""
	var entry = VBoxContainer.new()
	entry.custom_min_size = Vector2(0, 80)
	
	# Encabezado de la propuesta
	var header = HBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = proposal.get_type_name()
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var status_label = Label.new()
	status_label.text = proposal.status.capitalize()
	status_label.add_theme_color_override("font_color", proposal.get_status_color())
	status_label.add_theme_font_size_override("font_size", 10)
	
	header.add_child(title_label)
	header.add_child(status_label)
	
	# Información de la propuesta
	var info = VBoxContainer.new()
	
	var parties_label = Label.new()
	parties_label.text = proposal.proposer + " → " + proposal.target
	parties_label.add_theme_font_size_override("font_size", 10)
	parties_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	var description_label = Label.new()
	description_label.text = proposal.description
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	info.add_child(parties_label)
	info.add_child(description_label)
	
	# Botones de acción (solo si el jugador es el objetivo)
	if proposal.target == current_faction and proposal.status == "pending":
		var actions = HBoxContainer.new()
		
		var accept_button = Button.new()
		accept_button.text = "Aceptar"
		accept_button.custom_min_size = Vector2(80, 30)
		accept_button.pressed.connect(_on_proposal_accepted.bind(proposal.proposal_id))
		
		var reject_button = Button.new()
		reject_button.text = "Rechazar"
		reject_button.custom_min_size = Vector2(80, 30)
		reject_button.pressed.connect(_on_proposal_rejected.bind(proposal.proposal_id))
		
		var chance_label = Label.new()
		chance_label.text = "Posibilidad: " + str(int(proposal.acceptance_chance)) + "%"
		chance_label.add_theme_font_size_override("font_size", 9)
		chance_label.add_theme_color_override("font_color", Color.YELLOW)
		
		actions.add_child(accept_button)
		actions.add_child(reject_button)
		actions.add_child(chance_label)
		
		info.add_child(actions)
	
	entry.add_child(header)
	entry.add_child(info)
	
	# Separador
	var separator = HSeparator.new()
	separator.modulate = Color(0.4, 0.4, 0.4, 0.8)
	entry.add_child(separator)
	
	return entry

func refresh_events_log():
	"""Actualiza el registro de eventos diplomáticos"""
	if not events_log or not diplomacy_system:
		return
	
	# Limpiar log anterior
	for child in events_log.get_children():
		child.queue_free()
	
	var recent_events = diplomacy_system.get_recent_events(5)
	
	if recent_events.is_empty():
		var no_events_label = Label.new()
		no_events_label.text = "No hay eventos diplomáticos recientes"
		no_events_label.add_theme_color_override("font_color", Color.GRAY)
		events_log.add_child(no_events_label)
		return
	
	for event in recent_events:
		var event_entry = create_event_entry(event)
		events_log.add_child(event_entry)

func create_event_entry(event: DiplomaticEventData) -> Control:
	"""Crea una entrada visual para un evento"""
	var entry = VBoxContainer.new()
	
	var header = HBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = event.title
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var date_label = Label.new()
	date_label.text = event.date
	date_label.add_theme_font_size_override("font_size", 9)
	date_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	header.add_child(title_label)
	header.add_child(date_label)
	
	var description_label = Label.new()
	description_label.text = event.description
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", event.get_severity_color())
	
	entry.add_child(header)
	entry.add_child(description_label)
	
	return entry

# === SEÑALES Y CALLBACKS ===

func _on_close_pressed():
	"""Callback cuando se presiona el botón de cerrar"""
	hide_panel()

func _on_diplomacy_button_pressed(faction_name: String):
	"""Callback cuando se presiona el botón de diplomacia de una facción"""
	show_diplomacy_options(faction_name)

func _on_nation_details_pressed(faction_name: String):
	"""Callback cuando se presiona el botón de detalles de una nación"""
	show_nation_details(faction_name)

func _on_proposal_accepted(proposal_id: String):
	"""Callback cuando se acepta una propuesta"""
	if diplomacy_system:
		diplomacy_system.resolve_proposal(proposal_id, true)
		refresh_proposals_list()
		refresh_relations_display()
		if main_hud:
			main_hud.add_event("Propuesta diplomática aceptada", "success")

func _on_proposal_rejected(proposal_id: String):
	"""Callback cuando se rechaza una propuesta"""
	if diplomacy_system:
		diplomacy_system.resolve_proposal(proposal_id, false)
		refresh_proposals_list()
		if main_hud:
			main_hud.add_event("Propuesta diplomática rechazada", "warning")

func _on_relation_changed(faction_a: String, faction_b: String, new_level: int):
	"""Callback cuando cambia una relación"""
	refresh_relations_display()

func _on_proposal_created(proposal: DiplomaticProposalData):
	"""Callback cuando se crea una propuesta"""
	refresh_proposals_list()

func _on_event_occurred(event: DiplomaticEventData):
	"""Callback cuando ocurre un evento diplomático"""
	refresh_events_log()
	refresh_relations_display()

# === DIÁLOGOS Y VENTANAS AUXILIARES ===

func show_diplomacy_options(faction_name: String):
	"""Muestra opciones diplomáticas para una facción"""
	# TODO: Implementar diálogo de opciones diplomáticas
	print("Mostrar opciones diplomáticas para: ", faction_name)
	
	# Por ahora, crear una propuesta de ejemplo
	if diplomacy_system:
		var proposal_types = ["alliance", "peace_treaty", "trade_agreement"]
		var random_type = proposal_types[randi() % proposal_types.size()]
		diplomacy_system.create_proposal(current_faction, faction_name, random_type)
		
		if main_hud:
			main_hud.add_event("Propuesta diplomática enviada a " + faction_name, "info")

func show_nation_details(faction_name: String):
	"""Muestra detalles detallados de una nación"""
	if not main_hud:
		return
	
	var faction_manager = get_node_or_null("/root/FactionManager")
	if not faction_manager or not faction_manager.faccion_existe(faction_name):
		return
	
	var faction_data = faction_manager.obtener_faccion(faction_name)
	var relation = diplomacy_system.get_relation(current_faction, faction_name) if diplomacy_system else null
	
	var details = {
		"Nombre": faction_name,
		"Ideología": faction_data.ideologia,
		"Dinero": faction_data.recursos.get("dinero", 0),
		"Moral": faction_data.recursos.get("moral", 0),
		"Prestigio": faction_data.recursos.get("prestigio", 0)
	}
	
	if relation:
		details["Relación"] = relation.get_relation_name() + " (" + str(relation.relation_level) + ")"
		details["Última interacción"] = relation.last_interaction if relation.last_interaction != "" else "Ninguna"
	
	main_hud.show_details("Detalles de " + faction_name, details)