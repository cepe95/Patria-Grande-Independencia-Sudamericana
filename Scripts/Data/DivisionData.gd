extends Resource
class_name DivisionData

@export var nombre: String
@export var rama_principal: String        # infanteria, caballeria, artilleria
@export var unidades_componentes: Array   # lista de UnitData
@export var cantidad_total: int
@export var icono_path: String
@export var movilidad: int                # velocidad estratégica
@export var moral: int                    # promedio o valor compuesto
@export var experiencia: int              # opcional
@export var icono: Texture2D
@export var faccion: String = ""
@export var posicion_inicial: Vector2 = Vector2.ZERO
@export var estado: String = "activo"

# Campos adicionales para el panel de detalles
@export var comandante: Resource = null   # CommanderData si existe
@export var condicion_fisica: int = 100
@export var bajas_recientes: int = 0
@export var nivel_refuerzos: int = 0
@export var estado_actual: String = "Activo"
@export var ubicacion: String = ""
@export var suministro: String = "Completo"
@export var fecha_creacion: String = ""
@export var historial_batallas: Array[String] = []
@export var mision: String = ""
