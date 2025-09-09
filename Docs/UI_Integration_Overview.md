# Diplomacy System Integration - Visual Overview

## Main HUD Integration

The diplomacy system has been successfully integrated into the main HUD with the following components:

### 1. **New Diplomacy Button**
- Location: Event Panel > Quick Action Buttons
- Text: "Diplomacia"
- Keyboard shortcut: Ctrl+D
- Function: Opens the diplomacy panel

### 2. **Diplomacy Panel Structure**
```
DiplomacyPanel (Modal Dialog)
├── Header Container
│   ├── Title Label: "Diplomacia y Relaciones Internacionales"
│   └── Close Button (✕)
├── Content Container
│   ├── Factions List (Scrollable)
│   │   ├── Faction Entries with:
│   │   │   ├── Flag Icon (32x24)
│   │   │   ├── Faction Name + Status
│   │   │   ├── Opinion Indicator
│   │   │   ├── Treaty Indicators (💰, ⚔️)
│   │   │   └── "Interactuar" Button
│   └── Details Panel
│       ├── Faction Information
│       │   ├── Selected Faction Name
│       │   ├── Relationship Status (Colored)
│       │   └── Opinion Rating (-100 to +100)
│       ├── Active Treaties List
│       ├── Pending Proposals (Accept/Reject)
│       ├── Available Actions
│       │   ├── "Proponer Alianza"
│       │   ├── "Acuerdo Comercial" 
│       │   ├── "Declarar Guerra"
│       │   └── "Proponer Paz"
│       └── Recent Events Log
```

### 3. **Visual Indicators**
- **Relationship Colors**:
  - Red: War/Hostile
  - Orange: Unfriendly  
  - White: Neutral
  - Light Green: Friendly
  - Green: Allied
  - Purple: Vassal
  - Gray: Unknown

- **Opinion Colors**:
  - Green: +20 or higher
  - White: -20 to +20
  - Red: -20 or lower

### 4. **Event Integration**
- Diplomatic events appear in main event log
- Special notifications for player proposals
- Status changes logged with appropriate colors
- Turn processing includes diplomatic AI decisions

### 5. **Keyboard Controls**
- `Ctrl + D`: Open diplomacy panel
- `ESC`: Close diplomacy panel (priority over pause)
- `Space`: Advance turn (processes diplomatic events)

## System Architecture

```
FactionManager
├── Patriota Faction
├── Realista Faction  
└── [Future Factions]

DiplomacyManager (Autoload)
├── Diplomatic Relations Storage
├── Proposal System
├── Random Events Processor
├── AI Decision Making
└── Configuration Loader

DiplomaticRelation (Resource)
├── Status Tracking
├── Opinion Management
├── Treaty Storage
├── Event History
└── Color/Name Helpers

MainHUD
├── Event Logging Integration
├── Turn Processing Hook
├── Panel Management
└── Keyboard Shortcuts
```

## Configuration Files

### `Data/Diplomacy/diplomatic_events.json`
- Random diplomatic events
- Proposal type definitions
- AI behavior settings
- Opinion modifiers
- Localization strings

### `Data/Factions/FactionData.gd` (Extended)
- Diplomatic personality settings
- Known factions list
- Diplomatic preference modifiers

## Testing and Validation

The system includes:
- Debug logging for all operations
- Test scene (`Scenes/Test/DiplomacyTest.tscn`)
- Comprehensive error handling
- Signal-based event system
- Modular configuration support

## User Experience

Players can now:
1. Click "Diplomacia" button to open the panel
2. View all known factions and their relationship status
3. See visual indicators for opinions and treaties
4. Send diplomatic proposals (alliances, trade, war, peace)
5. Respond to incoming proposals
6. Track diplomatic events and history
7. Use keyboard shortcuts for quick access

The system maintains consistency with the existing HUD design while adding rich diplomatic gameplay mechanics.