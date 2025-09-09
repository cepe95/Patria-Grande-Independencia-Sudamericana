extends Control
class_name ResourceAllocationPanel

# Panel para asignar recursos a diferentes categorías
# Integrado con EconomicManager para gestión completa de recursos

signal allocation_confirmed(category: String, resources: Dictionary)
signal allocation_cancelled()

# === REFERENCIAS A NODOS ===
@onready var category_tabs: TabContainer = $VBoxContainer/CategoryTabs
@onready var total_cost_label: Label = $VBoxContainer/Footer/TotalCostContainer/TotalCostLabel
@onready var confirm_button: Button = $VBoxContainer/Footer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $VBoxContainer/Footer/ButtonContainer/CancelButton

# === VARIABLES ===
var current_faction: String = "Patriota"
var current_allocations: Dictionary = {}  # category -> {resource_id -> amount}
var available_resources: Dictionary = {}

# === INICIALIZACIÓN ===
func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	setup_allocation_tabs()

func setup_allocation_tabs():
	"""Configura las pestañas de asignación"""
	if not EconomicManager:
		print("⚠ EconomicManager no disponible para ResourceAllocationPanel")
		return
	
	var categories = ["construccion", "unidades", "tecnologia", "diplomacia"]
	var tab_names = ["Construcción", "Unidades", "Tecnología", "Diplomacia"]
	
	for i in categories.size():
		var category = categories[i]
		var tab_name = tab_names[i]
		
		var tab_content = create_allocation_tab(category, tab_name)
		category_tabs.add_child(tab_content)
		category_tabs.set_tab_title(i, tab_name)

func create_allocation_tab(category: String, title: String) -> Control:
	"""Crea una pestaña de asignación para una categoría"""
	var tab = VBoxContainer.new()
	tab.name = category
	
	# Título y descripción
	var header = VBoxContainer.new()
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	
	var desc_label = Label.new()
	var config = EconomicManager.economic_config
	var category_config = config.get("allocation_categories", {}).get(category, {})
	desc_label.text = category_config.get("description", "Categoría de asignación de recursos")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	header.add_child(title_label)
	header.add_child(desc_label)
	tab.add_child(header)
	
	# Separador
	var separator = HSeparator.new()
	tab.add_child(separator)
	
	# Lista de recursos
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_min_size = Vector2(0, 300)
	
	var resource_list = VBoxContainer.new()
	resource_list.name = "ResourceList"
	
	# Agregar controles de recursos relevantes para esta categoría
	var required_resources = category_config.get("required_resources", [])
	for resource_id in required_resources:
		if EconomicManager.resource_definitions.has(resource_id):
			var resource_control = create_resource_allocation_control(resource_id, category)
			resource_list.add_child(resource_control)
	
	scroll.add_child(resource_list)
	tab.add_child(scroll)
	
	return tab

func create_resource_allocation_control(resource_id: String, category: String) -> Control:
	"""Crea un control para asignar un recurso específico"""
	var res_def = EconomicManager.resource_definitions[resource_id]
	var available = EconomicManager.get_resource_amount(current_faction, resource_id)
	
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Nombre del recurso
	var name_label = Label.new()
	name_label.text = res_def.get_display_name()
	name_label.custom_min_size = Vector2(120, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Cantidad disponible
	var available_label = Label.new()
	available_label.text = "Disponible: " + str(available)
	available_label.custom_min_size = Vector2(100, 0)
	available_label.add_theme_font_size_override("font_size", 10)
	available_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# Control de cantidad a asignar
	var amount_container = HBoxContainer.new()
	
	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_min_size = Vector2(30, 30)
	
	var amount_input = SpinBox.new()
	amount_input.min_value = 0
	amount_input.max_value = available
	amount_input.step = 1
	amount_input.value = 0
	amount_input.custom_min_size = Vector2(80, 30)
	amount_input.name = "AmountInput_" + resource_id + "_" + category
	
	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_min_size = Vector2(30, 30)
	
	# Conectar señales
	minus_button.pressed.connect(_on_amount_decrease.bind(amount_input))
	plus_button.pressed.connect(_on_amount_increase.bind(amount_input))
	amount_input.value_changed.connect(_on_amount_changed.bind(resource_id, category))
	
	amount_container.add_child(minus_button)
	amount_container.add_child(amount_input)
	amount_container.add_child(plus_button)
	
	container.add_child(name_label)
	container.add_child(available_label)
	container.add_child(amount_container)
	
	return container

# === EVENTOS ===
func _on_amount_decrease(spin_box: SpinBox):
	"""Callback para decrementar cantidad"""
	spin_box.value = max(0, spin_box.value - 1)

func _on_amount_increase(spin_box: SpinBox):
	"""Callback para incrementar cantidad"""
	spin_box.value = min(spin_box.max_value, spin_box.value + 1)

func _on_amount_changed(new_value: float, resource_id: String, category: String):
	"""Callback cuando cambia la cantidad a asignar"""
	if not current_allocations.has(category):
		current_allocations[category] = {}
	
	current_allocations[category][resource_id] = int(new_value)
	update_total_cost()

func update_total_cost():
	"""Actualiza el costo total de las asignaciones"""
	var total_cost = {}
	
	for category in current_allocations:
		for resource_id in current_allocations[category]:
			var amount = current_allocations[category][resource_id]
			if amount > 0:
				if not total_cost.has(resource_id):
					total_cost[resource_id] = 0
				total_cost[resource_id] += amount
	
	# Mostrar resumen del costo total
	var cost_text = "Costo Total: "
	if total_cost.is_empty():
		cost_text += "Sin asignaciones"
	else:
		var cost_parts = []
		for resource_id in total_cost:
			var res_def = EconomicManager.resource_definitions.get(resource_id)
			var name = res_def.get_display_name() if res_def else resource_id
			cost_parts.append(name + ": " + str(total_cost[resource_id]))
		cost_text += " | ".join(cost_parts)
	
	total_cost_label.text = cost_text
	
	# Validar si se pueden realizar las asignaciones
	var can_afford = true
	for resource_id in total_cost:
		var available = EconomicManager.get_resource_amount(current_faction, resource_id)
		if available < total_cost[resource_id]:
			can_afford = false
			break
	
	confirm_button.disabled = not can_afford or total_cost.is_empty()

func _on_confirm_pressed():
	"""Callback para confirmar asignaciones"""
	for category in current_allocations:
		var resources = current_allocations[category]
		if not resources.is_empty():
			# Filtrar recursos con cantidad > 0
			var filtered_resources = {}
			for resource_id in resources:
				if resources[resource_id] > 0:
					filtered_resources[resource_id] = resources[resource_id]
			
			if not filtered_resources.is_empty():
				if EconomicManager.allocate_resources(current_faction, category, filtered_resources):
					allocation_confirmed.emit(category, filtered_resources)
				else:
					print("⚠ Error al asignar recursos para categoría: ", category)
	
	# Cerrar panel
	visible = false

func _on_cancel_pressed():
	"""Callback para cancelar asignaciones"""
	allocation_cancelled.emit()
	visible = false

# === MÉTODOS PÚBLICOS ===
func show_for_faction(faction_name: String):
	"""Muestra el panel para una facción específica"""
	current_faction = faction_name
	current_allocations.clear()
	
	# Actualizar recursos disponibles
	refresh_available_resources()
	
	# Resetear todos los controles
	reset_allocation_controls()
	
	visible = true

func refresh_available_resources():
	"""Actualiza los recursos disponibles para mostrar"""
	if EconomicManager:
		available_resources = EconomicManager.get_all_faction_resources(current_faction)

func reset_allocation_controls():
	"""Resetea todos los controles de asignación"""
	for tab_index in category_tabs.get_tab_count():
		var tab = category_tabs.get_tab_control(tab_index)
		if tab:
			var resource_list = tab.get_node_or_null("ScrollContainer/ResourceList")
			if resource_list:
				for child in resource_list.get_children():
					var amount_input = find_amount_input_in_control(child)
					if amount_input:
						amount_input.value = 0
						# Actualizar máximo disponible
						var resource_id = extract_resource_id_from_input_name(amount_input.name)
						if resource_id != "":
							amount_input.max_value = EconomicManager.get_resource_amount(current_faction, resource_id)

func find_amount_input_in_control(control: Control) -> SpinBox:
	"""Encuentra el SpinBox de cantidad en un control"""
	if control is SpinBox:
		return control
	
	for child in control.get_children():
		var result = find_amount_input_in_control(child)
		if result:
			return result
	
	return null

func extract_resource_id_from_input_name(input_name: String) -> String:
	"""Extrae el ID del recurso del nombre del input"""
	if input_name.begins_with("AmountInput_"):
		var parts = input_name.split("_")
		if parts.size() >= 3:
			return parts[1]
	return ""