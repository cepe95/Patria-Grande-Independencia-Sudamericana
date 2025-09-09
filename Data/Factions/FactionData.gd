extends Resource
class_name FactionData

@export var nombre: String
@export var color: Color
@export var bandera_path: String
@export var ideologia: String
@export var recursos := {
	# Alimentación
	"pan": 0,
	"carne": 0,
	"fruta": 0,
	"verdura": 0,
	"vino": 0,
	"aguardiente": 0,
	"tabaco": 0,

	# Economía
	"dinero": 0,
	"oro": 0,
	"plata": 0,

	# Militar
	"municion": 0,
	"polvora": 0,
	"mosquetes": 0,
	"sables": 0,
	"lanzas": 0,
	"cañones": 0,
	"caballos": 0,

	# Cultural
	"biblias": 0,

	# Estado estratégico
	"moral": 100,
	"prestigio": 0
}

# === PROPIEDADES DIPLOMÁTICAS ===
@export var diplomatic_reputation: int = 0  # Reputación diplomática general
@export var diplomatic_style: String = "balanced"  # aggressive, defensive, balanced, peaceful
@export var preferred_relation_type: String = "neutral"  # alliance, neutral, isolation
@export var active_proposals: Array[String] = []  # IDs de propuestas activas
