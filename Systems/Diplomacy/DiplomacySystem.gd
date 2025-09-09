extends Node

# DiplomacySystem - Sistema de diplomacia y relaciones exteriores
# Maneja las relaciones entre facciones, propuestas diplomáticas y eventos

signal relation_changed(faction_a: String, faction_b: String, new_level: int)
signal proposal_created(proposal: DiplomaticProposalData)
signal proposal_resolved(proposal: DiplomaticProposalData, accepted: bool)
signal diplomatic_event_occurred(event: DiplomaticEventData)

# Almacenamiento de datos diplomáticos
var relations: Dictionary = {}  # {"faction_a-faction_b": DiplomaticRelationData}
var proposals: Dictionary = {}  # {"proposal_id": DiplomaticProposalData}
var events: Array[DiplomaticEventData] = []
var active_events: Array[DiplomaticEventData] = []

# Configuración
var config: Dictionary = {}

func _ready():
	print("✓ DiplomacySystem inicializado")
	load_configuration()
	initialize_default_relations()

func load_configuration():
	"""Carga la configuración diplomática desde archivos"""
	var config_path = "res://Data/Config/DiplomaticRules.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var result = json.parse(file.get_as_text())
			file.close()
			if result == OK:
				config = json.data
			else:
				print("Error al cargar configuración diplomática")
				_load_default_config()
	else:
		_load_default_config()

func _load_default_config():
	"""Carga configuración por defecto"""
	config = {
		"default_relation_level": 0,
		"max_proposals_per_faction": 3,
		"proposal_expiry_turns": 5,
		"relation_decay_rate": 1,
		"diplomatic_events": {
			"alliance_formed": {"relation_bonus": 50, "reputation_bonus": 10},
			"war_declared": {"relation_penalty": -80, "reputation_penalty": -5},
			"peace_treaty": {"relation_bonus": 30, "reputation_bonus": 5}
		}
	}

func initialize_default_relations():
	"""Inicializa relaciones por defecto entre facciones conocidas"""
	var faction_manager = get_node_or_null("/root/FactionManager")
	if not faction_manager:
		return
	
	var faction_names = faction_manager.facciones.keys()
	
	for i in range(faction_names.size()):
		for j in range(i + 1, faction_names.size()):
			var faction_a = faction_names[i]
			var faction_b = faction_names[j]
			
			if not has_relation(faction_a, faction_b):
				create_relation(faction_a, faction_b, config.get("default_relation_level", 0))

# === GESTIÓN DE RELACIONES ===

func create_relation(faction_a: String, faction_b: String, initial_level: int = 0) -> DiplomaticRelationData:
	"""Crea una nueva relación diplomática"""
	var relation = DiplomaticRelationData.new()
	relation.faction_a = faction_a
	relation.faction_b = faction_b
	relation.relation_level = initial_level
	relation.relation_status = "neutral"
	relation.established_date = get_current_date()
	
	var key = get_relation_key(faction_a, faction_b)
	relations[key] = relation
	
	return relation

func get_relation(faction_a: String, faction_b: String) -> DiplomaticRelationData:
	"""Obtiene la relación entre dos facciones"""
	var key = get_relation_key(faction_a, faction_b)
	return relations.get(key, null)

func has_relation(faction_a: String, faction_b: String) -> bool:
	"""Verifica si existe una relación entre dos facciones"""
	var key = get_relation_key(faction_a, faction_b)
	return relations.has(key)

func get_relation_key(faction_a: String, faction_b: String) -> String:
	"""Genera una clave única para la relación (ordenada alfabéticamente)"""
	if faction_a < faction_b:
		return faction_a + "-" + faction_b
	else:
		return faction_b + "-" + faction_a

func modify_relation(faction_a: String, faction_b: String, change: int, reason: String = ""):
	"""Modifica el nivel de relación entre dos facciones"""
	var relation = get_relation(faction_a, faction_b)
	if not relation:
		relation = create_relation(faction_a, faction_b)
	
	var old_level = relation.relation_level
	relation.relation_level = clamp(relation.relation_level + change, -100, 100)
	
	if reason != "":
		relation.add_interaction(reason)
	
	# Actualizar estado de relación automáticamente
	_update_relation_status(relation)
	
	# Emitir señal si hubo cambio
	if old_level != relation.relation_level:
		relation_changed.emit(faction_a, faction_b, relation.relation_level)

func _update_relation_status(relation: DiplomaticRelationData):
	"""Actualiza el estado de relación basado en el nivel"""
	var level = relation.relation_level
	var old_status = relation.relation_status
	
	# No cambiar si hay tratados específicos activos
	if relation.relation_status in ["alliance", "war", "peace_treaty", "trade_agreement"]:
		return
	
	if level >= 80:
		relation.relation_status = "alliance"
	elif level <= -80:
		relation.relation_status = "war"
	else:
		relation.relation_status = "neutral"
	
	# Si cambió el estado, añadir al historial
	if old_status != relation.relation_status:
		relation.add_interaction("Relación cambió a: " + relation.get_relation_name())

# === GESTIÓN DE PROPUESTAS ===

func create_proposal(proposer: String, target: String, proposal_type: String, terms: Dictionary = {}) -> DiplomaticProposalData:
	"""Crea una nueva propuesta diplomática"""
	var proposal = DiplomaticProposalData.new()
	proposal.proposal_id = generate_proposal_id()
	proposal.proposer = proposer
	proposal.target = target
	proposal.proposal_type = proposal_type
	proposal.terms = terms
	proposal.title = _generate_proposal_title(proposal_type, proposer, target)
	proposal.description = _generate_proposal_description(proposal_type, terms)
	proposal.created_date = get_current_date()
	proposal.status = "pending"
	
	# Calcular posibilidad de aceptación
	var relation = get_relation(proposer, target)
	if relation:
		proposal.acceptance_chance = proposal.calculate_acceptance_chance(relation.relation_level)
	
	proposals[proposal.proposal_id] = proposal
	proposal_created.emit(proposal)
	
	return proposal

func resolve_proposal(proposal_id: String, accepted: bool) -> bool:
	"""Resuelve una propuesta diplomática"""
	var proposal = proposals.get(proposal_id, null)
	if not proposal or proposal.status != "pending":
		return false
	
	proposal.status = "accepted" if accepted else "rejected"
	proposal.response_date = get_current_date()
	
	if accepted:
		_apply_proposal_effects(proposal)
	
	proposal_resolved.emit(proposal, accepted)
	return true

func _apply_proposal_effects(proposal: DiplomaticProposalData):
	"""Aplica los efectos de una propuesta aceptada"""
	var relation = get_relation(proposal.proposer, proposal.target)
	if not relation:
		return
	
	match proposal.proposal_type:
		"alliance":
			relation.relation_status = "alliance"
			relation.relation_level = max(relation.relation_level, 70)
			relation.defensive_pact = true
			relation.military_access = true
		"peace_treaty":
			relation.relation_status = "peace_treaty"
			relation.relation_level = max(relation.relation_level, 0)
		"trade_agreement":
			relation.relation_status = "trade_agreement"
			relation.trade_modifier = 1.5
			relation.relation_level += 20
		"war_declaration":
			relation.relation_status = "war"
			relation.relation_level = -80
		"military_access":
			relation.military_access = true
		"technology_sharing":
			relation.technology_sharing = true

func generate_proposal_id() -> String:
	"""Genera un ID único para propuestas"""
	return "prop_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

func _generate_proposal_title(type: String, proposer: String, target: String) -> String:
	"""Genera título para la propuesta"""
	match type:
		"alliance":
			return "Propuesta de Alianza entre %s y %s" % [proposer, target]
		"peace_treaty":
			return "Tratado de Paz entre %s y %s" % [proposer, target]
		"trade_agreement":
			return "Acuerdo Comercial entre %s y %s" % [proposer, target]
		"war_declaration":
			return "Declaración de Guerra de %s contra %s" % [proposer, target]
		_:
			return "Propuesta Diplomática de %s a %s" % [proposer, target]

func _generate_proposal_description(type: String, terms: Dictionary) -> String:
	"""Genera descripción para la propuesta"""
	match type:
		"alliance":
			return "Propuesta de alianza militar y política con beneficios mutuos."
		"peace_treaty":
			return "Tratado para finalizar hostilidades y establecer paz."
		"trade_agreement":
			return "Acuerdo para mejorar las relaciones comerciales."
		"war_declaration":
			return "Declaración formal de guerra y hostilidades."
		_:
			return "Propuesta diplomática con términos específicos."

# === GESTIÓN DE EVENTOS ===

func create_diplomatic_event(title: String, description: String, factions: Array[String], effects: Dictionary = {}) -> DiplomaticEventData:
	"""Crea un nuevo evento diplomático"""
	var event = DiplomaticEventData.new()
	event.event_id = "event_" + str(Time.get_unix_time_from_system())
	event.title = title
	event.description = description
	event.date = get_current_date()
	event.factions_involved = factions
	event.relation_changes = effects.get("relations", {})
	event.resource_effects = effects.get("resources", {})
	
	events.append(event)
	active_events.append(event)
	diplomatic_event_occurred.emit(event)
	
	# Aplicar efectos inmediatamente
	_apply_event_effects(event)
	
	return event

func _apply_event_effects(event: DiplomaticEventData):
	"""Aplica los efectos de un evento diplomático"""
	# Aplicar cambios de relaciones
	for relation_key in event.relation_changes:
		var parts = relation_key.split("-")
		if parts.size() == 2:
			modify_relation(parts[0], parts[1], event.relation_changes[relation_key], 
							"Evento: " + event.title)
	
	# Aplicar efectos de recursos (integración con otros sistemas)
	for faction_name in event.resource_effects:
		var faction_manager = get_node_or_null("/root/FactionManager")
		if faction_manager and faction_manager.faccion_existe(faction_name):
			var faction = faction_manager.obtener_faccion(faction_name)
			var resource_changes = event.resource_effects[faction_name]
			for resource in resource_changes:
				if faction.recursos.has(resource):
					faction.recursos[resource] += resource_changes[resource]

func process_turn():
	"""Procesa eventos diplomáticos cada turno"""
	# Procesar eventos activos
	for i in range(active_events.size() - 1, -1, -1):
		var event = active_events[i]
		event.process_turn()
		if not event.is_active:
			active_events.remove_at(i)
	
	# Procesar expiración de propuestas
	for proposal_id in proposals:
		var proposal = proposals[proposal_id]
		if proposal.status == "pending":
			# TODO: Implementar lógica de expiración basada en turnos
			pass

# === UTILIDADES ===

func get_current_date() -> String:
	"""Obtiene la fecha actual del juego"""
	# TODO: Integrar con sistema de fechas del juego
	return "1810-01-01"

func get_all_relations() -> Array[DiplomaticRelationData]:
	"""Retorna todas las relaciones diplomáticas"""
	var all_relations: Array[DiplomaticRelationData] = []
	for relation in relations.values():
		all_relations.append(relation)
	return all_relations

func get_faction_relations(faction_name: String) -> Array[DiplomaticRelationData]:
	"""Retorna todas las relaciones de una facción"""
	var faction_relations: Array[DiplomaticRelationData] = []
	for relation in relations.values():
		if relation.faction_a == faction_name or relation.faction_b == faction_name:
			faction_relations.append(relation)
	return faction_relations

func get_pending_proposals(faction_name: String) -> Array[DiplomaticProposalData]:
	"""Retorna propuestas pendientes para una facción"""
	var pending: Array[DiplomaticProposalData] = []
	for proposal in proposals.values():
		if (proposal.target == faction_name or proposal.proposer == faction_name) and proposal.status == "pending":
			pending.append(proposal)
	return pending

func get_recent_events(limit: int = 10) -> Array[DiplomaticEventData]:
	"""Retorna eventos diplomáticos recientes"""
	var recent = events.duplicate()
	recent.reverse()
	return recent.slice(0, min(limit, recent.size()))