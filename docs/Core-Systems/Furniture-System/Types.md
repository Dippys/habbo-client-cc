# Furniture Types

The Habbo client supports over 80 specialized furniture types, each with unique logic and visualizations. This document catalogs the major furniture categories and their implementations.

## Furniture Category System

### FurniCategory Enum
**File:** `src/com/sulake/habbo/catalog/enums/FurniCategory.as`

| ID | Category | Examples |
|----|----------|----------|
| 1 | DEFAULT | Generic items |
| 2 | WALL_PAPER | Wall coverings |
| 3 | FLOOR | Floorings |
| 4 | LANDSCAPE | Outdoor scenery |
| 5 | POST_IT | Stickie notes |
| 6 | POSTER | Wall decorations |
| 7 | SOUND_SET | Music tracks |
| 8 | TRAX_SONG | Trax songs |
| 9 | PRESENT | Gift boxes |
| 10 | ECOTRON_BOX | Ecotron boxes |
| 12 | CREDIT_FURI | Furniture with credits |
| 17 | GUILD_FURNI | Guild items |
| 18 | GAME_FURNI | Game-related |
| 19 | MONSTERPLANT_SEED | Monster plant seeds |

## Major Furniture Types

### Interactive Furniture

| Type | Logic Class | Visualization | Purpose |
|------|------------|---------------|---------|
| Dice | FurnitureDiceLogic | FurnitureBottleVisualization | Random number generator |
| One Way Door | FurnitureOneWayDoorLogic | FurnitureVisualization | Teleporter |
| Sound Machine | FurnitureSoundMachineLogic | FurnitureVisualization | Music playback |
| Jukebox | FurnitureJukeboxLogic | FurnitureVisualization | Playlist management |
| Room Dimmer | FurnitureRoomDimmerLogic | FurnitureVisualization | Lighting control |
| Present | FurniturePresentLogic | FurnitureVisualization | Gift opening |
| Stickie | FurnitureStickieLogic | FurnitureStickieVisualization | Notes |
| Mannequin | FurnitureMannequinLogic | FurnitureMannequinVisualization | Clothing display |

### Display Furniture

| Type | Logic Class | Visualization | Purpose |
|------|------------|---------------|---------|
| Trophy | FurnitureTrophyLogic | FurnitureVisualization | Achievement display |
| Badge Display | FurnitureBadgeDisplayLogic | FurnitureBadgeDisplayVisualization | Badge showcase |
| YouTube TV | FurnitureYoutubeLogic | FurnitureYoutubeVisualization | Video playback |
| Poster | FurniturePosterVisualization | FurnitureVisualization | Wall art |
| External Image | FurnitureExternalImageLogic | FurnitureExternalImageVisualization | Custom images |
| Planet System | FurniturePlanetSystemLogic | FurniturePlanetSystemVisualization | Decorative |

### Game Furniture

| Type | Logic Class | Visualization | Purpose |
|------|------------|---------------|---------|
| Ice Storm | FurnitureIceStormLogic | FurnitureVisualization | Ice Storm game |
| Score Board | FurnitureScoreLogic | FurnitureVisualization | High scores |
| High Score | FurnitureHighScoreLogic | FurnitureVisualization | Leaderboard |
| Vote Counter | FurnitureVoteCounterLogic | FurnitureVoteCounterVisualization | Voting |
| Vote Majority | FurnitureVoteMajorityLogic | FurnitureVoteMajorityVisualization | Majority voting |

### Special Furniture

| Type | Logic Class | Visualization | Purpose |
|------|------------|---------------|---------|
| Crafting Gizmo | FurnitureCraftingGizmoLogic | FurnitureVisualization | Crafting |
| Monster Plant | FurnitureMonsterplantSeedLogic | FurnitureVisualization | Pets |
| Cuckoo Clock | FurnitureCuckooClockLogic | FurnitureVisualization | Time display |
| Lovelock | FurnitureLovelockLogic | FurnitureVisualization | Valentine |
| Wildwest Wanted | FurnitureWildwestWantedLogic | FurnitureVisualization | Wildwest game |
| Guild Customized | FurnitureGuildCustomizedLogic | FurnitureGuildCustomizedVisualization | Guild items |

## Specialized Logic Classes

### Dice Logic
**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureDiceLogic.as`

```actionscript
// Handles dice roll animation and state
// State values: 0 = off, 1-6 = rolled value
// Dispatches: DICE_ACTIVATE, DICE_OFF events
```

### One Way Door Logic
**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureOneWayDoorLogic.as`

```actionscript
// Teleporter logic
// Dispatches: ENTER_ONEWAYDOOR event
// Opens interaction menu for destination selection
```

### Dimmer Logic
**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureRoomDimmerLogic.as`

```actionscript
// Manages lighting presets
// State: preset ID being used
// Extra: current color/brightness
```

### Stickie Logic
**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureStickieLogic.as`

```actionscript
// Color selection and text editing
// Data stored in FURNITURE_ITEMDATA variable
// Colors: 0-9 (preset colors)
```

### Mannequin Logic
**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureMannequinLogic.as`

```actionscript
// Stores clothing configuration
// Figure string stored in model
// Opens clothing change widget
```

### YouTube Logic
**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureYoutubeLogic.as`

```actionscript
// Fetches video list from server
// Plays YouTube videos
// Uses FurnitureYoutubeVisualization for rendering
```

## Specialized Visualizations

### FurnitureAnimatedVisualization
Base for animated furniture - handles sprite animation cycles.

### FurnitureBottleVisualization
Dice bottle animation with rolling effect.

### FurnitureStickieVisualization
Note-like rendering with color layers.

### FurnitureHabbowheelVisualization
Rotating wheel animation (win/spin states).

### FurniturePlanetSystemVisualization
Animated planet orbit system.

### FurnitureYoutubeVisualization
Video thumbnail display with play overlay.

### FurnitureGuildCustomizedVisualization
Dynamic guild logo rendering.

## Data Flow for Specialized Furniture

### State Updates

```actionscript
// Server sends state update
ObjectUpdateMessageComposer(typeId, newState, extra, data)

// Client processes
FurnitureLogic._Str_9796(k)
    └── Updates object state
    └── Updates model variables (FURNITURE_EXTRAS, FURNITURE_ITEMDATA)
    └── Triggers visualization update
```

### Extra Data Usage

| Furniture Type | Extra Data |
|---------------|------------|
| Dice | Final rolled number |
| Dimmer | Color + brightness |
| Present | Gift ID |
| Stickie | Color ID |
| Mannequin | Clothing configuration |
| Jukebox | Playlist ID |

### StuffData Types

Furniture can have custom data via IStuffData:
- `StringStuffData` - Text data (stickies)
- `IntStuffData` - Numeric data (dice value)
- `ArrayStuffData` - Complex data structures

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureDiceLogic.as` | Dice logic |
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureOneWayDoorLogic.as` | Teleporter |
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureRoomDimmerLogic.as` | Dimmer |
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureStickieLogic.as` | Stickie |
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureMannequinLogic.as` | Mannequin |
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureYoutubeLogic.as` | YouTube |
| `src/com/sulake/habbo/catalog/enums/FurniCategory.as` | Categories |

## Summary

The Furniture System provides extensive variety through:
- 80+ specialized logic classes handling unique behaviors
- 60+ visualization classes for different rendering needs
- Widget integration for complex interactions
- Server-driven state management
- Extensible category system for new furniture types