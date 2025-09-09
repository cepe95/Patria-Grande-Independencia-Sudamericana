extends Panel

# ProductionPanel - Panel de gestión de producción urbana
# Permite al jugador seleccionar qué recurso produce cada ciudad

# === SEÑALES ===
signal production_changed(city_name: String, resource_type: String, production_amount: int)
signal production_cancelled()

# === REFERENCIAS A NODOS ===
@onready var title_label: Label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var city_name_label: Label = $VBoxContainer/CityInfoContainer/CityNameLabel
@onready var city_type_label: Label = $VBoxContainer/CityInfoContainer/CityTypeLabel
@onready var current_production_label: Label = $VBoxContainer/CityInfoContainer/CurrentProductionLabel
@onready var resources_container: VBoxContainer = $VBoxContainer/ContentContainer/ResourcesContainer
@onready var apply_button: Button = $VBoxContainer/ButtonsContainer/ApplyButton
@onready var cancel_button: Button = $VBoxContainer/ButtonsContainer/CancelButton

# === VARIABLES ===
var current_city_name: String = ""
var current_city_data: TownData = null
var selected_resource: String = ""
var current_production_resource: String = ""
var resource_buttons: Array[Button] = []

# Configuración de recursos y producción por tipo de ciudad
var production_config = {
	"dinero": {
		"display_name": "Dinero",
		"icon": "💰",
		"base_production": 30,
		"description": "Genera ingresos para financiar ejércitos y construcciones"
	},
	"comida": {
		"display_name": "Comida", 
		"icon": "🍞",
		"base_production": 40,
		"description": "Alimenta las tropas y mantiene la moral"
	},
	"municion": {
		"display_name": "Munición",
		"icon": "⚔️", 
		"base_production": 20,
		"description": "Esencial para el combate y entrenamiento militar"
	}
}

var city_type_multipliers = {
	"villa": 0.5,
	"pueblo": 0.7,
	"ciudad_pequeña": 0.8,
	"ciudad_mediana": 1.0,
	"ciudad_grande": 1.5,
	"capital": 2.0,
	"metropolis": 2.5
}

# === INICIALIZACIÓN ===
func _ready():
	setup_connections()

func setup_connections():
	"""Conecta las señales de los botones"""
	close_button.pressed.connect(_on_close_pressed)
	cancel_button.pressed.connect(_on_close_pressed)
	apply_button.pressed.connect(_on_apply_pressed)

# === MÉTODOS PÚBLICOS ===
func show_for_city(city_name: String, city_data: TownData, current_production: String = "dinero"):
	"""Muestra el panel de producción para una ciudad específica"""
	current_city_name = city_name
	current_city_data = city_data
	current_production_resource = current_production
	selected_resource = current_production
	
	# Actualizar información de la ciudad
	city_name_label.text = "Ciudad: " + city_name
	if city_data:
		city_type_label.text = "Tipo: " + city_data.tipo.capitalize()
	else:
		city_type_label.text = "Tipo: Ciudad"
	
	update_production_display()
	populate_resource_options()
	visible = true

func hide_panel():
	"""Oculta el panel de producción"""
	visible = false
	reset_selection()

# === GESTIÓN DE RECURSOS ===
func populate_resource_options():
	"""Puebla las opciones de recursos disponibles"""
	# Limpiar opciones anteriores
	resource_buttons.clear()
	for child in resources_container.get_children():
		child.queue_free()
	
	# Crear botones para cada recurso
	for resource_key in production_config.keys():
		var resource_data = production_config[resource_key]
		var resource_entry = create_resource_entry(resource_key, resource_data)
		resources_container.add_child(resource_entry)

func create_resource_entry(resource_key: String, resource_data: Dictionary) -> Control:
	"""Crea una entrada para un recurso en la lista"""
	var entry = HBoxContainer.new()
	entry.add_theme_constant_override("separation", 10)
	
	# Botón de radio (simulado con CheckBox)
	var radio_button = CheckBox.new()
	radio_button.button_group = create_button_group()
	radio_button.text = ""
	radio_button.pressed.connect(_on_resource_selected.bind(resource_key))
	
	# Establecer selección actual
	if resource_key == selected_resource:
		radio_button.button_pressed = true
	
	resource_buttons.append(radio_button)
	
	# Información del recurso
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Nombre y producción
	var name_container = HBoxContainer.new()
	
	var icon_label = Label.new()
	icon_label.text = resource_data.icon
	icon_label.add_theme_font_size_override("font_size", 16)
	
	var name_label = Label.new()
	name_label.text = resource_data.display_name
	name_label.add_theme_font_size_override("font_size", 14)
	
	var production_amount = calculate_production_amount(resource_key)
	var production_label = Label.new()
	production_label.text = "(+%d/turno)" % production_amount
	production_label.add_theme_color_override("font_color", Color.GREEN)
	production_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	production_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	name_container.add_child(icon_label)
	name_container.add_child(name_label)
	name_container.add_child(production_label)
	
	# Descripción
	var description_label = Label.new()
	description_label.text = resource_data.description
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	info_container.add_child(name_container)
	info_container.add_child(description_label)
	
	entry.add_child(radio_button)
	entry.add_child(info_container)
	
	# Agregar separador
	var separator = HSeparator.new()
	entry.add_child(separator)
	
	return entry

func create_button_group() -> ButtonGroup:
	"""Crea un grupo de botones para simular radio buttons"""
	if not has_meta("button_group"):
		set_meta("button_group", ButtonGroup.new())
	return get_meta("button_group")

func calculate_production_amount(resource_key: String) -> int:
	"""Calcula la cantidad de producción para un recurso y ciudad"""
	var base_production = production_config[resource_key]["base_production"]
	var city_type = "ciudad_mediana"  # Por defecto
	
	if current_city_data:
		city_type = current_city_data.tipo
	
	var multiplier = city_type_multipliers.get(city_type, 1.0)
	return int(base_production * multiplier)

func update_production_display():
	"""Actualiza la visualización de la producción actual"""
	var production_amount = calculate_production_amount(current_production_resource)
	var resource_data = production_config.get(current_production_resource, {"display_name": "Desconocido", "icon": "?"})
	
	current_production_label.text = "Producción Actual: %s %s (+%d/turno)" % [
		resource_data.icon,
		resource_data.display_name,
		production_amount
	]

# === SELECCIÓN DE RECURSOS ===
func _on_resource_selected(resource_key: String):
	"""Callback cuando se selecciona un recurso"""
	selected_resource = resource_key
	
	# Habilitar botón de aplicar si hay cambios
	apply_button.disabled = (selected_resource == current_production_resource)

# === CALLBACKS DE BOTONES ===
func _on_apply_pressed():
	"""Callback cuando se aplican los cambios de producción"""
	if selected_resource == current_production_resource:
		return
	
	var production_amount = calculate_production_amount(selected_resource)
	production_changed.emit(current_city_name, selected_resource, production_amount)
	hide_panel()

func _on_close_pressed():
	"""Callback cuando se cierra el panel"""
	production_cancelled.emit()
	hide_panel()

func reset_selection():
	"""Resetea la selección actual"""
	selected_resource = ""
	resource_buttons.clear()
	apply_button.disabled = true

# === MÉTODOS ESTÁTICOS PARA INTEGRACIÓN ===
static func get_production_amount_for_city(city_type: String, resource_key: String) -> int:
	"""Método estático para calcular producción desde otros scripts"""
	var production_config_static = {
		"dinero": {"base_production": 30},
		"comida": {"base_production": 40}, 
		"municion": {"base_production": 20}
	}
	
	var city_type_multipliers_static = {
		"villa": 0.5,
		"pueblo": 0.7,
		"ciudad_pequeña": 0.8,
		"ciudad_mediana": 1.0,
		"ciudad_grande": 1.5,
		"capital": 2.0,
		"metropolis": 2.5
	}
	
	var base_production = production_config_static.get(resource_key, {}).get("base_production", 0)
	var multiplier = city_type_multipliers_static.get(city_type, 1.0)
	return int(base_production * multiplier)

static func get_available_resources() -> Array[String]:
	"""Retorna la lista de recursos disponibles para producción"""
	return ["dinero", "comida", "municion"]

# === DOCUMENTACIÓN PARA MODDERS ===
"""
Para extender el sistema de producción urbana:

1. Agregar nuevos recursos:
   - Añadir entrada en production_config con display_name, icon, base_production, description
   - Actualizar el sistema de recursos principal para manejar el nuevo recurso
   - Considerar balance de juego para base_production

2. Modificar multiplicadores de ciudad:
   - Editar city_type_multipliers para ajustar balance entre tipos de ciudad
   - Añadir nuevos tipos de ciudad si es necesario

3. Lógica de producción personalizada:
   - Modificar calculate_production_amount() para lógicas más complejas
   - Considerar factores como poblacion, recursos locales, eventos

4. Restricciones de producción:
   - Modificar populate_resource_options() para filtrar recursos según ciudad
   - Implementar prerequisitos o tecnologías requeridas

5. UI personalizada:
   - Modificar ProductionPanel.tscn para cambiar diseño
   - Agregar nuevos elementos visuales o información
   - Personalizar iconos y colores

Ejemplo de configuración personalizada:
production_config["hierro"] = {
    "display_name": "Hierro",
    "icon": "🔧",
    "base_production": 15,
    "description": "Material para fabricar armas y herramientas"
}
"""