extends Resource
class_name TechnologyData

# Datos de una tecnología para el sistema de investigación

@export var id: String
@export var name: String
@export var description: String
@export var category: String  # "militar", "economia", "diplomacia", "cultural"
@export var research_cost: int = 100
@export var research_time: int = 5  # turnos

# Requisitos para investigar esta tecnología
@export var required_technologies: Array[String] = []
@export var required_resources: Dictionary = {}  # {"dinero": 500, "municion": 100}

# Efectos que otorga la tecnología cuando se completa
@export var effects: Dictionary = {}  # {"moral_bonus": 10, "unit_cost_reduction": 0.1}

# Beneficios específicos por sistema
@export var military_benefits: Dictionary = {}
@export var economic_benefits: Dictionary = {} 
@export var diplomatic_benefits: Dictionary = {}

# Metadatos
@export var icon_path: String = ""
@export var era: String = "colonial"  # "colonial", "independencia", "republica"
@export var is_secret: bool = false  # Tecnologías ocultas hasta cumplir requisitos

func _init():
	resource_name = "TechnologyData"

func can_research(available_tech: Array[String], faction_resources: Dictionary) -> bool:
	"""Verifica si se pueden cumplir los requisitos para investigar esta tecnología"""
	
	# Verificar tecnologías requeridas
	for req_tech in required_technologies:
		if req_tech not in available_tech:
			return false
	
	# Verificar recursos requeridos
	for resource in required_resources:
		var required_amount = required_resources[resource]
		var available_amount = faction_resources.get(resource, 0)
		if available_amount < required_amount:
			return false
	
	return true

func get_total_research_cost() -> int:
	"""Retorna el costo total de investigación incluyendo recursos"""
	var total_cost = research_cost
	for resource in required_resources:
		total_cost += required_resources[resource]
	return total_cost

func get_benefits_summary() -> String:
	"""Retorna un resumen de los beneficios de la tecnología"""
	var benefits = []
	
	for effect in effects:
		benefits.append("%s: %s" % [effect, effects[effect]])
	
	for benefit in military_benefits:
		benefits.append("Militar - %s: %s" % [benefit, military_benefits[benefit]])
		
	for benefit in economic_benefits:
		benefits.append("Económico - %s: %s" % [benefit, economic_benefits[benefit]])
		
	for benefit in diplomatic_benefits:
		benefits.append("Diplomático - %s: %s" % [benefit, diplomatic_benefits[benefit]])
	
	return "\n".join(benefits)