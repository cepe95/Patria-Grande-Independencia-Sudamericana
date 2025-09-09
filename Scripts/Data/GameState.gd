extends Resource
class_name GameState

# GameState - Clase que contiene todos los datos necesarios para guardar/cargar una partida
# Diseñada para ser utilizada con ResourceSaver/ResourceLoader de Godot
# Modders pueden extender esta clase para agregar datos adicionales

@export var version: String = "1.0" # Versión del formato de guardado para compatibilidad
@export var save_date: String = "" # Fecha de guardado para mostrar en la UI
@export var save_name: String = "" # Nombre personalizable del guardado

# === DATOS DE JUEGO BÁSICOS ===
@export var current_turn: int = 1
@export var current_resources: Dictionary = {}
@export var selected_unit_id: String = "" # ID para reconstruir referencia
@export var selected_city_name: String = ""

# === DATOS DE CIUDADES ===
# Array de diccionarios con datos de ciudades serializables
@export var cities_data: Array[Dictionary] = []

# === DATOS DE UNIDADES ===
# Array de diccionarios con datos de unidades serializables
@export var units_data: Array[Dictionary] = []

# === DATOS DE FACCIONES ===
# Diccionario con el estado actual de cada facción
@export var factions_data: Dictionary = {}

# === CONFIGURACIÓN DE MAPA ===
@export var map_config: Dictionary = {}

# === EVENTOS DEL LOG ===
# Para preservar el historial de eventos
@export var events_log: Array[Dictionary] = []

# === MÉTODOS DE UTILIDAD ===

func _init():
	"""Inicializa valores por defecto"""
	current_resources = {
		"dinero": 1000,
		"comida": 500,
		"municion": 200
	}
	save_date = Time.get_datetime_string_from_system()

func get_display_name() -> String:
	"""Retorna el nombre para mostrar en la UI de carga"""
	if save_name != "":
		return save_name
	return "Partida - Turno %d (%s)" % [current_turn, save_date.split("T")[0]]

func set_from_main_hud(main_hud: Control):
	"""Extrae datos del MainHUD actual para guardar
	
	Args:
		main_hud: Referencia al MainHUD activo
	"""
	if not main_hud:
		push_error("GameState: MainHUD reference is null")
		return
	
	# Datos básicos
	current_turn = main_hud.current_turn
	current_resources = main_hud.current_resources.duplicate()
	selected_city_name = main_hud.get_selected_city()
	
	# ID de unidad seleccionada (si existe)
	var selected_unit = main_hud.get_selected_unit()
	if selected_unit and selected_unit.has_method("get_id"):
		selected_unit_id = selected_unit.get_id()
	elif selected_unit and selected_unit.get("data"):
		selected_unit_id = selected_unit.data.get("nombre", "")
	
	# Extraer datos de ciudades desde las listas de la UI
	extract_cities_data(main_hud)
	
	# Extraer datos de unidades desde el mapa estratégico
	extract_units_data(main_hud)
	
	# Extraer log de eventos
	extract_events_log(main_hud)

func extract_cities_data(main_hud: Control):
	"""Extrae datos de ciudades desde el MainHUD"""
	cities_data.clear()
	
	# Ejemplo de extracción - esto se adaptará según la implementación real
	# Por ahora guardamos las ciudades de ejemplo que maneja el MainHUD
	var example_cities = [
		{"nombre": "Buenos Aires", "tipo": "Capital", "faccion": "Patriota", "controlada": true},
		{"nombre": "Córdoba", "tipo": "Ciudad", "faccion": "Realista", "controlada": true},
		{"nombre": "Montevideo", "tipo": "Puerto", "faccion": "Patriota", "controlada": true}
	]
	
	for city in example_cities:
		cities_data.append(city)

func extract_units_data(main_hud: Control):
	"""Extrae datos de unidades desde el mapa estratégico"""
	units_data.clear()
	
	if not main_hud.strategic_map:
		return
	
	var units_container = main_hud.strategic_map.get_node_or_null("UnitsContainer")
	if units_container:
		for unit in units_container.get_children():
			var unit_data = unit.get("data")
			if unit_data:
				# Crear una copia serializable de los datos de la unidad
				var serializable_data = {}
				for key in unit_data:
					serializable_data[key] = unit_data[key]
				
				# Agregar posición si está disponible
				if unit.has_method("get_global_position"):
					serializable_data["position"] = var_to_str(unit.global_position)
				
				units_data.append(serializable_data)

func extract_events_log(main_hud: Control):
	"""Extrae el log de eventos del MainHUD"""
	events_log.clear()
	
	# Nota: En una implementación completa, el MainHUD debería exponer 
	# una función para obtener los eventos en formato serializable
	# Por ahora guardamos algunos eventos de ejemplo
	events_log.append({
		"turn": current_turn,
		"message": "Estado de juego guardado",
		"type": "success"
	})

func apply_to_main_hud(main_hud: Control):
	"""Aplica los datos guardados al MainHUD actual
	
	Args:
		main_hud: Referencia al MainHUD donde cargar los datos
	"""
	if not main_hud:
		push_error("GameState: MainHUD reference is null")
		return
	
	# Restaurar datos básicos
	main_hud.current_turn = current_turn
	main_hud.current_resources = current_resources.duplicate()
	main_hud.update_resource_display()
	main_hud.update_date_turn_display("", current_turn)
	
	# Restaurar selecciones (esto requerirá implementación adicional en el MainHUD)
	# main_hud.restore_selections(selected_unit_id, selected_city_name)
	
	# Aplicar datos de ciudades
	apply_cities_data(main_hud)
	
	# Aplicar datos de unidades
	apply_units_data(main_hud)
	
	# Restaurar eventos
	apply_events_log(main_hud)
	
	# Refrescar la interfaz
	main_hud.refresh_interface()

func apply_cities_data(main_hud: Control):
	"""Restaura los datos de ciudades en el MainHUD"""
	# En una implementación completa, esto restauraría las ciudades en el mapa
	# Por ahora solo agregamos un evento informativo
	main_hud.add_event("Ciudades restauradas: %d" % cities_data.size(), "info")

func apply_units_data(main_hud: Control):
	"""Restaura los datos de unidades en el mapa estratégico"""
	# En una implementación completa, esto recrearía las unidades en el mapa
	# Por ahora solo agregamos un evento informativo
	main_hud.add_event("Unidades restauradas: %d" % units_data.size(), "info")

func apply_events_log(main_hud: Control):
	"""Restaura eventos al log del MainHUD"""
	for event in events_log:
		main_hud.add_event(
			event.get("message", "Evento restaurado"),
			event.get("type", "info")
		)