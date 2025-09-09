# Unit Selection System Documentation

## Overview
The unit selection system allows players to select and command individual units or groups of units on the strategic map.

## Features Implemented

### 1. Individual Unit Selection
- **Left-click** on a unit to select it
- Selected unit will show visual feedback (blue tint and white outline)
- Selecting a new unit replaces the previous selection

### 2. Multi-Selection
- **Click and drag** to create a selection rectangle
- All allied units within the rectangle will be selected
- Visual selection rectangle shows during drag operation

### 3. Additive/Subtractive Selection
- **Shift + Left-click** on a unit to add it to current selection
- **Shift + Left-click** on an already selected unit to remove it from selection
- **Shift + Drag** to add units in rectangle to current selection

### 4. Movement Orders
- **Right-click** on the map to order selected units to move to that position
- Single units move directly to the target position
- Multiple units arrange in a formation around the target position
- Units maintain minimum spacing to avoid overlap

### 5. Deselection
- **Left-click** on empty space (without dragging) to clear all selections

## Visual Feedback
- **Selected units** show blue tint and white outline
- **Selection rectangle** displays as semi-transparent blue area with white border
- **On-screen display** shows current selection count and unit names

## Technical Implementation
- `SelectionManager` singleton handles all selection logic
- Supports both screen-space and world-space coordinate conversion
- Faction-based filtering (only Patriot units can be selected)
- Formation positioning for multi-unit movement

## Controls Summary
| Action | Control |
|--------|---------|
| Select single unit | Left-click on unit |
| Select multiple units | Click and drag rectangle |
| Add/remove from selection | Shift + left-click |
| Add rectangle to selection | Shift + drag |
| Move selected units | Right-click on map |
| Clear selection | Left-click empty space |

## Unit Properties
Units must have:
- `faccion` property set to "Patriota" to be selectable
- `velocidad` property for movement speed
- Visual components (Sprite2D or Icon) for selection feedback