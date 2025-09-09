#!/usr/bin/env python3
"""
Visualización simple del sistema de reclutamiento implementado
Muestra cómo funcionaría el sistema visualmente
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch
import numpy as np

def create_recruitment_visualization():
    """Crea una visualización del sistema de reclutamiento"""
    
    # Crear figura
    fig, ax = plt.subplots(1, 1, figsize=(14, 10))
    ax.set_xlim(-400, 400)
    ax.set_ylim(-400, 400)
    ax.set_aspect('equal')
    ax.set_title('Sistema de Reclutamiento Contextual - Patria Grande\nIndependencia Sudamericana', 
                 fontsize=16, fontweight='bold', pad=20)
    
    # Fondo del mapa
    ax.add_patch(patches.Rectangle((-350, -350), 700, 700, 
                                   facecolor='lightgreen', alpha=0.3, 
                                   label='Mapa Estratégico'))
    
    # Pueblos de prueba
    towns = [
        {"name": "Villa Independencia", "pos": (-100, -300), "type": "villa", "color": "orange"},
        {"name": "Ciudad Real", "pos": (250, 300), "type": "ciudad_mediana", "color": "brown"},
        {"name": "Capital del Virreinato", "pos": (0, 0), "type": "capital", "color": "gold"}
    ]
    
    for town in towns:
        x, y = town["pos"]
        # Pueblo como rectángulo
        ax.add_patch(patches.Rectangle((x-20, y-20), 40, 40, 
                                     facecolor=town["color"], alpha=0.8, 
                                     edgecolor='black', linewidth=2))
        # Nombre del pueblo
        ax.text(x, y-35, town["name"], ha='center', va='top', 
                fontsize=10, fontweight='bold')
        # Tipo del pueblo
        ax.text(x, y+35, f'({town["type"]})', ha='center', va='bottom', 
                fontsize=8, style='italic')
        
        # Rango de reclutamiento (círculo)
        circle = patches.Circle((x, y), 50, fill=False, 
                              edgecolor=town["color"], linestyle='--', alpha=0.6)
        ax.add_patch(circle)
    
    # Divisiones
    divisions = [
        {"name": "División Patriota", "pos": (-150, -350), "color": "blue", "faction": "Patriota"},
        {"name": "División Realista", "pos": (280, 350), "color": "red", "faction": "Realista"}
    ]
    
    for div in divisions:
        x, y = div["pos"]
        # División como triángulo
        triangle = patches.RegularPolygon((x, y), 3, radius=15, 
                                        facecolor=div["color"], alpha=0.8,
                                        edgecolor='black', linewidth=2)
        ax.add_patch(triangle)
        # Nombre de la división
        ax.text(x, y-25, div["name"], ha='center', va='top', 
                fontsize=9, fontweight='bold')
        ax.text(x, y+25, f'({div["faction"]})', ha='center', va='bottom', 
                fontsize=8, style='italic')
    
    # Simulación de división en rango de reclutamiento
    # División patriota cerca de Villa Independencia
    selected_div_pos = (-120, -280)
    ax.add_patch(patches.RegularPolygon(selected_div_pos, 3, radius=15, 
                                      facecolor='blue', alpha=0.8,
                                      edgecolor='yellow', linewidth=3))
    ax.text(selected_div_pos[0], selected_div_pos[1]-25, "División Seleccionada", 
            ha='center', va='top', fontsize=9, fontweight='bold', color='blue')
    
    # Flecha indicando movimiento
    ax.annotate('', xy=selected_div_pos, xytext=(-150, -350),
                arrowprops=dict(arrowstyle='->', lw=2, color='blue', alpha=0.7))
    ax.text(-135, -315, 'Click derecho\npara mover', ha='center', va='center',
            fontsize=8, bbox=dict(boxstyle="round,pad=0.3", facecolor='lightblue', alpha=0.7))
    
    # Panel de detalles simulado
    panel_x, panel_y = 150, -200
    panel_width, panel_height = 200, 150
    
    # Fondo del panel
    panel_bg = FancyBboxPatch((panel_x, panel_y), panel_width, panel_height,
                             boxstyle="round,pad=5", facecolor='lightgray', 
                             edgecolor='black', linewidth=2, alpha=0.9)
    ax.add_patch(panel_bg)
    
    # Título del panel
    ax.text(panel_x + panel_width/2, panel_y + panel_height - 20, 
            'Panel de Detalles', ha='center', va='center', 
            fontsize=12, fontweight='bold')
    
    # Contenido del panel
    details_text = [
        "División: División Patriota",
        "Facción: Patriota", 
        "Cantidad Total: 650",
        "Moral: 85",
        "Experiencia: 20"
    ]
    
    for i, text in enumerate(details_text):
        ax.text(panel_x + 10, panel_y + panel_height - 45 - i*15, 
                text, ha='left', va='center', fontsize=9)
    
    # Botón de reclutamiento
    button_y = panel_y + 25
    button_bg = FancyBboxPatch((panel_x + 10, button_y), panel_width - 20, 25,
                              boxstyle="round,pad=2", facecolor='green', 
                              edgecolor='darkgreen', linewidth=2, alpha=0.8)
    ax.add_patch(button_bg)
    ax.text(panel_x + panel_width/2, button_y + 12, 
            'Reclutar en Villa Independencia', ha='center', va='center', 
            fontsize=10, fontweight='bold', color='white')
    
    # Flecha del pueblo al botón
    ax.annotate('', xy=(panel_x - 10, button_y + 12), xytext=(-80, -300),
                arrowprops=dict(arrowstyle='->', lw=2, color='green', alpha=0.7))
    ax.text(-40, -250, 'Aparece cuando\nestá en rango', ha='center', va='center',
            fontsize=8, bbox=dict(boxstyle="round,pad=0.3", facecolor='lightgreen', alpha=0.7))
    
    # Leyenda
    legend_elements = [
        plt.Line2D([0], [0], marker='s', color='w', markerfacecolor='orange', 
                  markersize=10, label='Villa (Pelotón)'),
        plt.Line2D([0], [0], marker='s', color='w', markerfacecolor='brown', 
                  markersize=10, label='Ciudad Mediana (Pelotón, Compañía)'),
        plt.Line2D([0], [0], marker='s', color='w', markerfacecolor='gold', 
                  markersize=10, label='Capital (Todas las unidades)'),
        plt.Line2D([0], [0], marker='^', color='w', markerfacecolor='blue', 
                  markersize=10, label='División Patriota'),
        plt.Line2D([0], [0], marker='^', color='w', markerfacecolor='red', 
                  markersize=10, label='División Realista'),
        plt.Line2D([0], [0], linestyle='--', color='gray', 
                  label='Rango de Reclutamiento (50 unidades)')
    ]
    
    ax.legend(handles=legend_elements, loc='upper left', fontsize=9)
    
    # Instrucciones
    instructions = [
        "📋 Instrucciones:",
        "1. Click izquierdo: Seleccionar división",
        "2. Click derecho: Mover división",
        "3. Acerca división a pueblo para reclutar",
        "4. Click en 'Reclutar en [Pueblo]' en panel",
        "5. Selecciona unidad en menú emergente"
    ]
    
    for i, instruction in enumerate(instructions):
        ax.text(-350, 350 - i*25, instruction, ha='left', va='top', 
                fontsize=9, fontweight='bold' if i == 0 else 'normal')
    
    # Remover ejes
    ax.set_xticks([])
    ax.set_yticks([])
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['bottom'].set_visible(False)
    ax.spines['left'].set_visible(False)
    
    plt.tight_layout()
    plt.savefig('recruitment_system_visualization.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    print("✅ Visualización creada: recruitment_system_visualization.png")

if __name__ == "__main__":
    create_recruitment_visualization()