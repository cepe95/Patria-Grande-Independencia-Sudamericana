extends Node

# EventManager - Sistema de gestión de eventos históricos y aleatorios
# Autoload para gestionar eventos a nivel global

signal event_triggered(event_data: EventData)
signal event_completed(event_data: EventData, choice_made: Dictionary)

# === VARIABLES ===
var loaded_events: Array[EventData] = []
var triggered_events: Dictionary = {}  # ID -> número de veces ejecutado
var pending_events: Array[EventData] = []
var current_date: Date
var current_turn: int = 1

# Referencias al juego
var main_hud: Control
var game_clock: Node

# === CONFIGURACIÓN ===
var random_event_check_chance: float = 0.1  # Probabilidad de verificar eventos aleatorios por turno
var max_events_per_turn: int = 2

func _ready():
	print("✓ EventManager inicializado")
	load_events_from_files()
	# Conectar al GameClock cuando esté disponible
	call_deferred("connect_to_game_systems")

func connect_to_game_systems():
	"""Conecta el EventManager a los sistemas del juego"""
	# Buscar MainHUD
	main_hud = get_tree().get_first_node_in_group("main_hud")
	if not main_hud:
		# Buscar en la escena actual
		var scene_root = get_tree().current_scene
		if scene_root:
			main_hud = scene_root.get_node_or_null("UI/MainHUD") 
			if not main_hud:
				main_hud = scene_root.find_child("MainHUD", true, false)
	
	if main_hud:
		print("✓ EventManager conectado a MainHUD")
	else:
		print("⚠ EventManager no pudo encontrar MainHUD")
	
	# Buscar GameClock
	game_clock = get_tree().get_first_node_in_group("game_clock")
	if not game_clock and main_hud:
		# Buscar GameClock en el mapa estratégico
		var strategic_map = main_hud.get_node_or_null("StrategicMap")
		if strategic_map:
			game_clock = strategic_map.get_node_or_null("GameClock")
	
	if game_clock:
		if game_clock.has_signal("date_changed"):
			game_clock.date_changed.connect(_on_date_changed)
		print("✓ EventManager conectado a GameClock")
	else:
		print("⚠ EventManager no pudo encontrar GameClock")

func load_events_from_files():
	"""Carga eventos desde archivos de configuración"""
	var events_dir = "res://Data/Events/"
	
	# Verificar si existe el directorio
	if not DirAccess.dir_exists_absolute(events_dir):
		print("⚠ Directorio de eventos no existe: %s" % events_dir)
		create_sample_events()
		return
	
	var dir = DirAccess.open(events_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var files_found = 0
		
		while file_name != "":
			if file_name.ends_with(".json"):
				load_event_file(events_dir + file_name)
				files_found += 1
			file_name = dir.get_next()
		
		if files_found == 0:
			print("⚠ No se encontraron archivos JSON de eventos")
			create_sample_events()
		else:
			print("✓ Cargados %d eventos desde %d archivos" % [loaded_events.size(), files_found])
	else:
		print("⚠ Error al abrir directorio de eventos")
		create_sample_events()

func load_event_file(file_path: String):
	"""Carga un archivo de evento JSON"""
	if not FileAccess.file_exists(file_path):
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("No se pudo abrir archivo de evento: " + file_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("Error al parsear JSON en: " + file_path)
		return
	
	var event_data_dict = json.data
	
	# Puede ser un evento único o un array de eventos
	if event_data_dict is Array:
		for event_dict in event_data_dict:
			create_event_from_dict(event_dict)
	else:
		create_event_from_dict(event_data_dict)

func create_event_from_dict(event_dict: Dictionary):
	"""Crea un EventData desde un diccionario"""
	var event = EventData.new()
	event.from_dict(event_dict)
	loaded_events.append(event)

func create_sample_events():
	"""Crea eventos de ejemplo para demostración"""
	# Evento histórico: Revolución de Mayo  
	var revolucion_mayo = EventData.new()
	revolucion_mayo.id = "revolucion_mayo"
	revolucion_mayo.title = "Revolución de Mayo"
	revolucion_mayo.description = "El 25 de mayo de 1810 marca el inicio del proceso revolucionario en el Río de la Plata. Se forma la Primera Junta de Gobierno, dando el primer paso hacia la independencia."
	revolucion_mayo.event_type = EventData.EventType.HISTORICAL
	revolucion_mayo.trigger_date = "1810/05/25"
	revolucion_mayo.category = "político"
	revolucion_mayo.add_resource_effect("moral", 10)
	revolucion_mayo.add_choice("Apoyar la revolución", [{"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "dinero", "amount": -100}, {"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "moral", "amount": 20}])
	revolucion_mayo.add_choice("Mantener cautela", [{"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "moral", "amount": 5}])
	
	# Evento aleatorio: Motín de tropas
	var motin_tropas = EventData.new()
	motin_tropas.id = "motin_tropas"
	motin_tropas.title = "Motín en las Tropas"
	motin_tropas.description = "La falta de pago y las duras condiciones han provocado descontento entre las tropas. Algunos soldados amenazan con abandonar sus puestos."
	motin_tropas.event_type = EventData.EventType.RANDOM
	motin_tropas.random_chance = 0.15  # Mayor probabilidad para testing
	motin_tropas.category = "militar"
	motin_tropas.add_choice("Pagar soldadas atrasadas", [{"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "dinero", "amount": -150}, {"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "moral", "amount": 15}])
	motin_tropas.add_choice("Imponer disciplina militar", [{"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "moral", "amount": -10}])
	motin_tropas.add_choice("Negociar con los soldados", [{"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "dinero", "amount": -50}, {"type": EventData.EffectType.RESOURCE_CHANGE, "resource": "moral", "amount": 5}])
	
	# Evento aleatorio: Buena cosecha
	var buena_cosecha = EventData.new()
	buena_cosecha.id = "buena_cosecha"
	buena_cosecha.title = "Excelente Cosecha"
	buena_cosecha.description = "Las condiciones climáticas han sido favorables este año, resultando en una cosecha abundante que beneficia a toda la región."
	buena_cosecha.event_type = EventData.EventType.RANDOM
	buena_cosecha.random_chance = 0.12  # 12% de chance por turno para testing
	buena_cosecha.category = "económico"
	buena_cosecha.add_resource_effect("comida", 200)
	buena_cosecha.add_resource_effect("dinero", 100)
	
	# Evento histórico simple sin opciones
	var independencia_chile = EventData.new()
	independencia_chile.id = "independencia_chile"
	independencia_chile.title = "Independencia de Chile"
	independencia_chile.description = "Chile declara su independencia, fortaleciendo el movimiento independentista en toda Sudamérica."
	independencia_chile.event_type = EventData.EventType.HISTORICAL
	independencia_chile.trigger_date = "1818/02/12"
	independencia_chile.category = "político"
	independencia_chile.add_resource_effect("moral", 15)
	independencia_chile.add_resource_effect("dinero", 100)
	
	loaded_events = [revolucion_mayo, motin_tropas, buena_cosecha, independencia_chile]
	print("✓ Creados %d eventos de ejemplo" % loaded_events.size())

func check_events_for_turn(turn: int, date: Date = null):
	"""Verifica y dispara eventos para el turno actual"""
	current_turn = turn
	if date:
		current_date = date
	
	var events_this_turn = 0
	var game_context = get_game_context()
	
	# Verificar eventos históricos
	for event in loaded_events:
		if events_this_turn >= max_events_per_turn:
			break
			
		if should_trigger_event(event, game_context):
			trigger_event(event)
			events_this_turn += 1
	
	# Verificar eventos aleatorios ocasionalmente
	if randf() <= random_event_check_chance:
		check_random_events(game_context, max_events_per_turn - events_this_turn)

func check_random_events(game_context: Dictionary, max_events: int):
	"""Verifica eventos aleatorios"""
	var events_triggered = 0
	
	for event in loaded_events:
		if events_triggered >= max_events:
			break
			
		if event.event_type == EventData.EventType.RANDOM:
			if should_trigger_event(event, game_context):
				trigger_event(event)
				events_triggered += 1

func should_trigger_event(event: EventData, context: Dictionary) -> bool:
	"""Verifica si un evento debe dispararse"""
	# Verificar si ya se ejecutó y no puede repetirse
	if triggered_events.has(event.id) and not event.can_repeat:
		return false
	
	# Verificar condiciones de activación
	return event.should_trigger(current_date, current_turn, context)

func trigger_event(event: EventData):
	"""Dispara un evento"""
	# Registrar que el evento fue ejecutado
	if triggered_events.has(event.id):
		triggered_events[event.id] += 1
	else:
		triggered_events[event.id] = 1
	
	# Agregar a eventos pendientes para mostrar
	pending_events.append(event)
	
	# Emitir señal
	event_triggered.emit(event)
	
	# Mostrar evento si hay HUD disponible
	if main_hud and main_hud.has_method("show_event_modal"):
		main_hud.show_event_modal(event)
	else:
		# Fallback: mostrar como evento simple en el log
		show_event_as_log_entry(event)
	
	print("✓ Evento disparado: %s" % event.title)

func show_event_as_log_entry(event: EventData):
	"""Muestra el evento como entrada de log simple"""
	if main_hud and main_hud.has_method("add_event"):
		var message = "%s: %s" % [event.title, event.description]
		main_hud.add_event(message, "warning")

func complete_event(event: EventData, choice_made: Dictionary = {}):
	"""Completa un evento y aplica sus efectos"""
	var effects_to_apply = event.effects.duplicate()
	
	# Si se hizo una elección, aplicar sus efectos específicos
	if not choice_made.is_empty() and choice_made.has("effects"):
		effects_to_apply.append_array(choice_made.effects)
	
	# Aplicar efectos
	var results = apply_event_effects(effects_to_apply)
	
	# Remover de eventos pendientes
	pending_events.erase(event)
	
	# Emitir señal de completado
	event_completed.emit(event, choice_made)
	
	# Log del evento completado
	if main_hud and main_hud.has_method("add_event"):
		var choice_text = choice_made.get("text", "")
		var message = "Evento completado: %s" % event.title
		if not choice_text.is_empty():
			message += " (Elegido: %s)" % choice_text
		main_hud.add_event(message, "success")
	
	print("✓ Evento completado: %s" % event.title)
	return results

func apply_event_effects(effects: Array) -> Dictionary:
	"""Aplica los efectos de un evento"""
	var results = {
		"resource_changes": {},
		"other_changes": []
	}
	
	for effect in effects:
		match effect.get("type", EventData.EffectType.CUSTOM):
			EventData.EffectType.RESOURCE_CHANGE:
				var resource = effect.get("resource", "")
				var amount = effect.get("amount", 0)
				if not resource.is_empty():
					results.resource_changes[resource] = amount
					# Aplicar cambio de recursos al HUD
					if main_hud and main_hud.has_method("modify_resource"):
						main_hud.modify_resource(resource, amount)
			
			_:
				results.other_changes.append(effect)
	
	return results

func get_game_context() -> Dictionary:
	"""Obtiene el contexto actual del juego para evaluar condiciones"""
	var context = {
		"current_turn": current_turn,
		"current_date": current_date,
		"resources": {}
	}
	
	# Obtener recursos del HUD si está disponible
	if main_hud and main_hud.has_method("get_current_resources"):
		context.resources = main_hud.get_current_resources()
	
	return context

func get_triggered_events() -> Dictionary:
	"""Retorna el historial de eventos disparados"""
	return triggered_events.duplicate()

func get_pending_events() -> Array[EventData]:
	"""Retorna eventos pendientes de mostrar"""
	return pending_events.duplicate()

func _on_date_changed(new_date: Date):
	"""Callback cuando cambia la fecha"""
	current_date = new_date
	# No verificar eventos automáticamente por cambio de fecha
	# Los eventos se verificarán en cambio de turno

# === MÉTODOS PARA EVENTOS PERSONALIZADOS ===

func add_custom_event(event: EventData):
	"""Agrega un evento personalizado en tiempo de ejecución"""
	loaded_events.append(event)

func force_trigger_event(event_id: String):
	"""Fuerza el disparo de un evento específico"""
	for event in loaded_events:
		if event.id == event_id:
			trigger_event(event)
			return true
	return false

func remove_event(event_id: String):
	"""Remueve un evento del sistema"""
	for i in range(loaded_events.size()):
		if loaded_events[i].id == event_id:
			loaded_events.remove_at(i)
			return true
	return false