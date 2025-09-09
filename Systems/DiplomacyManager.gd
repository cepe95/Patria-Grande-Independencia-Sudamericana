extends Node
class_name DiplomacyManager

# Señales para eventos diplomáticos
signal diplomatic_status_changed(faction_a: String, faction_b: String, new_status: DiplomaticRelation.RelationStatus)
signal diplomatic_proposal_received(from_faction: String, to_faction: String, proposal_type: String, details: Dictionary)
signal diplomatic_event_occurred(event_type: String, description: String, factions_involved: Array)

# Almacenamiento de relaciones diplomáticas
var diplomatic_relations: Dictionary = {}
var diplomatic_proposals: Array[Dictionary] = []
var diplomatic_events_config: Dictionary = {}

# Referencias del juego
var current_turn: int = 1
var player_faction: String = "Patriota"

func _ready():
	load_diplomatic_config()
	initialize_base_relations()

func load_diplomatic_config():
	"""Carga la configuración diplomática desde archivos"""
	# Cargar configuración de eventos diplomáticos aleatorios
	var config_path = "res://Data/Diplomacy/diplomatic_events.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				diplomatic_events_config = json.data
	else:
		# Configuración por defecto si no existe el archivo
		create_default_diplomatic_config()

func create_default_diplomatic_config():
	"""Crea configuración diplomática por defecto"""
	diplomatic_events_config = {
		"random_events": [
			{
				"name": "border_skirmish",
				"description": "Escaramuza fronteriza entre {faction_a} y {faction_b}",
				"probability": 0.05,
				"opinion_change": -15,
				"status_requirements": ["NEUTRAL", "UNFRIENDLY"]
			},
			{
				"name": "trade_dispute",
				"description": "Disputa comercial afecta las relaciones entre {faction_a} y {faction_b}",
				"probability": 0.03,
				"opinion_change": -10,
				"status_requirements": ["NEUTRAL", "FRIENDLY"]
			},
			{
				"name": "cultural_exchange",
				"description": "Intercambio cultural mejora las relaciones entre {faction_a} y {faction_b}",
				"probability": 0.04,
				"opinion_change": 10,
				"status_requirements": ["NEUTRAL", "FRIENDLY"]
			}
		],
		"proposal_types": {
			"alliance": {
				"name": "Propuesta de Alianza",
				"description": "Formar una alianza militar y política",
				"requirements": ["can_propose_alliance"],
				"success_probability": 0.6
			},
			"trade_agreement": {
				"name": "Acuerdo Comercial",
				"description": "Establecer un acuerdo de comercio beneficioso",
				"requirements": ["can_propose_trade"],
				"success_probability": 0.7
			},
			"war_declaration": {
				"name": "Declaración de Guerra",
				"description": "Declarar guerra formal",
				"requirements": ["can_declare_war"],
				"success_probability": 1.0
			},
			"peace_treaty": {
				"name": "Tratado de Paz",
				"description": "Establecer la paz y cesar hostilidades",
				"requirements": [],
				"success_probability": 0.5
			}
		}
	}

func initialize_base_relations():
	"""Inicializa las relaciones diplomáticas básicas entre facciones conocidas"""
	var factions = FactionManager.facciones.keys()
	
	for i in range(factions.size()):
		for j in range(i + 1, factions.size()):
			var faction_a = factions[i]
			var faction_b = factions[j]
			var relation_key = get_relation_key(faction_a, faction_b)
			
			# Crear relación inicial según facciones
			var initial_status = DiplomaticRelation.RelationStatus.NEUTRAL
			if (faction_a == "Patriota" and faction_b == "Realista") or (faction_a == "Realista" and faction_b == "Patriota"):
				initial_status = DiplomaticRelation.RelationStatus.HOSTILE
			
			var relation = DiplomaticRelation.new(faction_a, faction_b, initial_status)
			diplomatic_relations[relation_key] = relation
			
			print("✓ Relación diplomática inicializada: %s ↔ %s (%s)" % [faction_a, faction_b, relation.get_relation_name()])

func get_relation_key(faction_a: String, faction_b: String) -> String:
	"""Genera una clave única para la relación entre dos facciones"""
	var factions = [faction_a, faction_b]
	factions.sort()
	return factions[0] + "_" + factions[1]

func get_diplomatic_relation(faction_a: String, faction_b: String) -> DiplomaticRelation:
	"""Obtiene la relación diplomática entre dos facciones"""
	var key = get_relation_key(faction_a, faction_b)
	return diplomatic_relations.get(key, null)

func set_diplomatic_status(faction_a: String, faction_b: String, new_status: DiplomaticRelation.RelationStatus):
	"""Establece el estado diplomático entre dos facciones"""
	var relation = get_diplomatic_relation(faction_a, faction_b)
	if relation:
		var old_status = relation.status
		relation.status = new_status
		relation.last_contact_turn = current_turn
		
		# Emitir señal de cambio
		diplomatic_status_changed.emit(faction_a, faction_b, new_status)
		
		# Agregar evento a la relación
		relation.add_recent_event("status_change", 
			"Cambio de relación de %s a %s" % [relation.get_relation_name(), relation.get_relation_name()], 
			current_turn)
		
		print("✓ Estado diplomático cambiado: %s ↔ %s: %s → %s" % [faction_a, faction_b, old_status, new_status])

func send_diplomatic_proposal(from_faction: String, to_faction: String, proposal_type: String, details: Dictionary = {}):
	"""Envía una propuesta diplomática"""
	var proposal = {
		"from": from_faction,
		"to": to_faction,
		"type": proposal_type,
		"details": details,
		"turn": current_turn,
		"id": generate_proposal_id()
	}
	
	diplomatic_proposals.append(proposal)
	diplomatic_proposal_received.emit(from_faction, to_faction, proposal_type, details)
	
	print("✓ Propuesta diplomática enviada: %s → %s (%s)" % [from_faction, to_faction, proposal_type])

func respond_to_proposal(proposal_id: String, accept: bool) -> bool:
	"""Responde a una propuesta diplomática"""
	for i in range(diplomatic_proposals.size()):
		var proposal = diplomatic_proposals[i]
		if proposal.get("id", "") == proposal_id:
			process_proposal_response(proposal, accept)
			diplomatic_proposals.remove_at(i)
			return true
	return false

func process_proposal_response(proposal: Dictionary, accepted: bool):
	"""Procesa la respuesta a una propuesta diplomática"""
	var from_faction = proposal.get("from", "")
	var to_faction = proposal.get("to", "")
	var proposal_type = proposal.get("type", "")
	
	if accepted:
		match proposal_type:
			"alliance":
				set_diplomatic_status(from_faction, to_faction, DiplomaticRelation.RelationStatus.ALLIED)
				var relation = get_diplomatic_relation(from_faction, to_faction)
				if relation:
					relation.active_treaties.append("alliance")
			"trade_agreement":
				var relation = get_diplomatic_relation(from_faction, to_faction)
				if relation:
					relation.trade_agreement = true
					relation.active_treaties.append("trade")
			"war_declaration":
				set_diplomatic_status(from_faction, to_faction, DiplomaticRelation.RelationStatus.WAR)
			"peace_treaty":
				set_diplomatic_status(from_faction, to_faction, DiplomaticRelation.RelationStatus.NEUTRAL)
		
		print("✓ Propuesta aceptada: %s entre %s y %s" % [proposal_type, from_faction, to_faction])
	else:
		print("✗ Propuesta rechazada: %s entre %s y %s" % [proposal_type, from_faction, to_faction])

func generate_proposal_id() -> String:
	"""Genera un ID único para una propuesta"""
	return "prop_" + str(current_turn) + "_" + str(randi() % 10000)

func process_turn_events():
	"""Procesa eventos diplomáticos del turno"""
	current_turn += 1
	process_random_diplomatic_events()
	process_ai_diplomatic_decisions()

func process_random_diplomatic_events():
	"""Procesa eventos diplomáticos aleatorios"""
	if not diplomatic_events_config.has("random_events"):
		return
	
	for event_config in diplomatic_events_config["random_events"]:
		if randf() < event_config.get("probability", 0.0):
			trigger_random_event(event_config)

func trigger_random_event(event_config: Dictionary):
	"""Dispara un evento diplomático aleatorio"""
	var factions = FactionManager.facciones.keys()
	if factions.size() < 2:
		return
	
	# Seleccionar dos facciones al azar
	var faction_a = factions[randi() % factions.size()]
	var faction_b = factions[randi() % factions.size()]
	while faction_b == faction_a:
		faction_b = factions[randi() % factions.size()]
	
	var relation = get_diplomatic_relation(faction_a, faction_b)
	if not relation:
		return
	
	# Verificar requisitos de estado
	var status_requirements = event_config.get("status_requirements", [])
	if not status_requirements.is_empty():
		var current_status_name = relation.get_relation_name().to_upper().replace(" ", "_")
		if not current_status_name in status_requirements:
			return
	
	# Aplicar efectos del evento
	var opinion_change = event_config.get("opinion_change", 0)
	if opinion_change != 0:
		relation.modify_opinion(faction_a, faction_b, opinion_change)
		relation.modify_opinion(faction_b, faction_a, opinion_change)
	
	# Crear descripción del evento
	var description = event_config.get("description", "").format({
		"faction_a": faction_a,
		"faction_b": faction_b
	})
	
	# Agregar evento a la relación
	relation.add_recent_event(event_config.get("name", "unknown"), description, current_turn, opinion_change)
	
	# Emitir señal del evento
	diplomatic_event_occurred.emit(event_config.get("name", "unknown"), description, [faction_a, faction_b])
	
	print("✓ Evento diplomático: %s" % description)

func process_ai_diplomatic_decisions():
	"""Procesa decisiones diplomáticas de la IA"""
	# Implementación básica de IA diplomática
	var factions = FactionManager.facciones.keys()
	var non_player_factions = factions.filter(func(f): return f != player_faction)
	
	for ai_faction in non_player_factions:
		for other_faction in factions:
			if other_faction == ai_faction:
				continue
				
			var relation = get_diplomatic_relation(ai_faction, other_faction)
			if not relation:
				continue
			
			# IA considera acciones basadas en relación actual
			consider_ai_diplomatic_action(ai_faction, other_faction, relation)

func consider_ai_diplomatic_action(ai_faction: String, other_faction: String, relation: DiplomaticRelation):
	"""La IA considera una acción diplomática"""
	var opinion = relation.get_opinion_towards(other_faction)
	
	# Lógica simple de IA
	if opinion > 60 and relation.can_propose_alliance() and randf() < 0.1:
		send_diplomatic_proposal(ai_faction, other_faction, "alliance")
	elif opinion < -60 and relation.can_declare_war() and randf() < 0.05:
		send_diplomatic_proposal(ai_faction, other_faction, "war_declaration")
	elif opinion > 30 and relation.can_propose_trade() and randf() < 0.15:
		send_diplomatic_proposal(ai_faction, other_faction, "trade_agreement")

func get_all_relations() -> Array[DiplomaticRelation]:
	"""Retorna todas las relaciones diplomáticas"""
	var relations: Array[DiplomaticRelation] = []
	for relation in diplomatic_relations.values():
		relations.append(relation)
	return relations

func get_relations_for_faction(faction_name: String) -> Array[DiplomaticRelation]:
	"""Retorna todas las relaciones de una facción específica"""
	var faction_relations: Array[DiplomaticRelation] = []
	for relation in diplomatic_relations.values():
		if relation.faction_a == faction_name or relation.faction_b == faction_name:
			faction_relations.append(relation)
	return faction_relations

func get_pending_proposals_for_faction(faction_name: String) -> Array[Dictionary]:
	"""Retorna propuestas pendientes para una facción"""
	var pending: Array[Dictionary] = []
	for proposal in diplomatic_proposals:
		if proposal.get("to", "") == faction_name:
			pending.append(proposal)
	return pending

func save_diplomatic_config():
	"""Guarda la configuración diplomática actual"""
	var config_path = "res://Data/Diplomacy/diplomatic_events.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(diplomatic_events_config, "\t")
		file.store_string(json_string)
		file.close()
		print("✓ Configuración diplomática guardada en: " + config_path)