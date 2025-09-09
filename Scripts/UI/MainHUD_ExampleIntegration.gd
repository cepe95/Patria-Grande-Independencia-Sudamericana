# Ejemplo de integración con MainHUD
# Este script muestra cómo utilizar MainHUD en el flujo de juego

extends Node

# Referencia al MainHUD
@onready var main_hud: Control = $MainHUD

func _ready():
	print("Ejemplo de integración con MainHUD")
	
	# Esperar a que MainHUD esté completamente inicializado
	await get_tree().process_frame
	
	# Ejemplo 1: Actualizar recursos desde un script externo
	update_game_resources()
	
	# Ejemplo 2: Simular eventos de juego
	simulate_game_events()
	
	# Ejemplo 3: Conectar a eventos específicos del HUD
	connect_to_hud_events()

func update_game_resources():
	"""Ejemplo de cómo actualizar recursos desde scripts externos"""
	var new_resources = {
		"dinero": 1500,
		"comida": 750,
		"municion": 300
	}
	
	main_hud.update_resources(new_resources)
	print("✓ Recursos actualizados desde script externo")

func simulate_game_events():
	"""Simula eventos de juego para mostrar el sistema de eventos"""
	await get_tree().create_timer(2.0).timeout
	main_hud.add_event("Nuevo refuerzo llegó a Buenos Aires", "success")
	
	await get_tree().create_timer(3.0).timeout
	main_hud.add_event("Espías reportan movimiento enemigo", "warning")
	
	await get_tree().create_timer(4.0).timeout
	main_hud.add_event("Recursos de comida escasos en Córdoba", "warning")

func connect_to_hud_events():
	"""Ejemplo de cómo conectarse a eventos del HUD"""
	# Si MainHUD tuviera señales personalizadas, se conectarían así:
	# main_hud.unit_selected.connect(_on_unit_selected)
	# main_hud.city_selected.connect(_on_city_selected)
	# main_hud.turn_advanced.connect(_on_turn_advanced)
	
	print("✓ Conexiones a eventos del HUD establecidas")

func _on_unit_selected(unit_node: Node):
	"""Callback de ejemplo para selección de unidad"""
	print("Unidad seleccionada desde HUD: ", unit_node.name)
	# Aquí se podría implementar lógica específica del juego

func _on_city_selected(city_name: String):
	"""Callback de ejemplo para selección de ciudad"""
	print("Ciudad seleccionada desde HUD: ", city_name)
	# Aquí se podría abrir paneles específicos de gestión urbana

func _on_turn_advanced(new_turn: int):
	"""Callback de ejemplo para avance de turno"""
	print("Nuevo turno iniciado: ", new_turn)
	# Aquí se procesarían los sistemas de juego por turnos

# Ejemplo de cómo acceder a información del HUD
func get_current_selection():
	"""Obtiene la selección actual del HUD"""
	var selected_unit = main_hud.get_selected_unit()
	var selected_city = main_hud.get_selected_city()
	
	if selected_unit:
		print("Unidad seleccionada: ", selected_unit.name)
	elif selected_city != "":
		print("Ciudad seleccionada: ", selected_city)
	else:
		print("Ninguna selección activa")

# Ejemplo de integración con sistemas de guardado
func save_hud_state():
	"""Guarda el estado actual del HUD"""
	var hud_state = {
		"selected_unit": main_hud.get_selected_unit().name if main_hud.get_selected_unit() else "",
		"selected_city": main_hud.get_selected_city(),
		"current_turn": main_hud.current_turn,
		"resources": main_hud.current_resources.duplicate()
	}
	
	# Aquí se guardaría el estado en un archivo
	print("Estado del HUD guardado: ", hud_state)

func load_hud_state(saved_state: Dictionary):
	"""Carga un estado previo del HUD"""
	if saved_state.has("resources"):
		main_hud.update_resources(saved_state["resources"])
	
	if saved_state.has("current_turn"):
		main_hud.update_date_turn_display("", saved_state["current_turn"])
	
	main_hud.add_event("Estado de partida cargado", "success")
	print("Estado del HUD cargado exitosamente")