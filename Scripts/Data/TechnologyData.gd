extends Resource
class_name TechnologyData

# Datos de una tecnología individual
@export var id: String = ""
@export var nombre: String = ""
@export var descripcion: String = ""
@export var icono: Texture2D
@export var categoria: String = "" # militar, economia, cultura, etc.

# Requisitos y costos
@export var prerequisitos: Array = [] # IDs de tecnologías requeridas
@export var costo_investigacion: int = 100 # Puntos de investigación necesarios
@export var tiempo_turnos: int = 5 # Turnos mínimos de investigación
@export var recursos_requeridos: Dictionary = {} # Recursos adicionales necesarios

# Estado de investigación
@export var desbloqueada: bool = false # Puede ser investigada
@export var investigando: bool = false # Actualmente en investigación
@export var completada: bool = false # Ya fue completada
@export var progreso_actual: int = 0 # Progreso actual de investigación

# Efectos al completar
@export var bonificaciones: Dictionary = {} # Modificadores que otorga
@export var unidades_desbloqueadas: Array = [] # Nuevas unidades disponibles
@export var edificios_desbloqueados: Array = [] # Nuevos edificios disponibles
@export var mecanicas_desbloqueadas: Array = [] # Nuevas mecánicas del juego

# Posición en el árbol (para UI)
@export var posicion_x: int = 0
@export var posicion_y: int = 0
@export var nivel_arbol: int = 0 # Nivel en el árbol tecnológico

func puede_ser_investigada(tecnologias_completadas: Array) -> bool:
	"""Verifica si esta tecnología puede ser investigada"""
	if completada or investigando:
		return false
	
	# Verificar que todos los prerequisitos estén completados
	for prereq in prerequisitos:
		if not prereq in tecnologias_completadas:
			return false
	
	return true

func iniciar_investigacion() -> void:
	"""Marca la tecnología como en investigación"""
	if puede_ser_investigada([]):  # Se validará externamente
		investigando = true
		progreso_actual = 0

func avanzar_investigacion(puntos: int) -> bool:
	"""Avanza la investigación y retorna true si se completa"""
	if not investigando:
		return false
	
	progreso_actual += puntos
	
	if progreso_actual >= costo_investigacion:
		completar_investigacion()
		return true
	
	return false

func completar_investigacion() -> void:
	"""Marca la tecnología como completada"""
	investigando = false
	completada = true
	progreso_actual = costo_investigacion

func get_progreso_porcentaje() -> float:
	"""Retorna el progreso como porcentaje (0.0 a 1.0)"""
	if costo_investigacion <= 0:
		return 1.0
	return float(progreso_actual) / float(costo_investigacion)

func get_costo_total() -> Dictionary:
	"""Retorna el costo total incluyendo recursos adicionales"""
	var costo_total = recursos_requeridos.duplicate()
	costo_total["investigacion"] = costo_investigacion
	return costo_total