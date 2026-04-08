# Furniture Architecture

The Furniture (Furni) system manages all items placed in rooms - from simple chairs to complex interactive objects. This document details the architecture, data models, and type mapping system.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FURNITURE ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Furniture Data                                   │   │
│  │                                                                       │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │  IFurnitureData │  │ FurnitureData    │  │ FurnitureData  │   │   │
│  │  │  (catalog)      │  │ (session)        │  │ (room instance)│   │   │
│  │  │                 │  │                  │  │                 │   │   │
│  │  │ - type, id      │  │ - type, id      │  │ - id, typeId   │   │   │
│  │  │ - className     │  │ - tileSize      │  │ - loc, dir    │   │   │
│  │  │ - dimensions    │  │ - category      │  │ - state, data │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   RoomObjectLogicComponent                           │   │
│  │                                                                       │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │FurnitureLogic  │  │ FurnitureDice    │  │ FurnitureStickie│   │   │
│  │  │  (base class)  │  │    Logic         │  │    Logic        │   │   │
│  │  │                 │  │                  │  │                 │   │   │
│  │  │ - dimensions   │  │ - dice state    │  │ - color        │   │   │
│  │  │ - mouse events │  │ - roll animation│  │ - text         │   │   │
│  │  │ - state change │  │                  │  │                 │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  │                                                                       │   │
│  │  (80+ specialized logic classes)                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              RoomObjectVisualizationFactory                        │   │
│  │                                                                       │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │FurnitureVisual │  │ FurnitureAnimated│  │FurnitureStickie │   │   │
│  │  │ ization         │  │  Visualization   │  │  Visualization  │   │   │
│  │  │                 │  │                  │  │                 │   │   │
│  │  │ - sprites      │  │ - animations    │  │ - layers        │   │   │
│  │  │ - direction    │  │ - layers       │  │                 │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  │                                                                       │   │
│  │  (60+ specialized visualization classes)                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Interfaces

### IFurnitureData
**File:** `src/com/sulake/habbo/session/furniture/IFurnitureData.as`

Catalog data from server:

| Property | Type | Description |
|----------|------|-------------|
| `type` | String | "s" (floor) or "i" (wall) |
| `id` | int | Furniture type ID |
| `className` | String | SWF class name |
| `fullName` | String | Display name |
| `tileSizeX/Y/Z` | int | Dimensions in grid units |
| `colours` | Array | Available colors |
| `category` | int | Furniture category |
| `canStandOn/SitOn/LayOn` | Boolean | Interaction flags |

### FurnitureData (Room Instance)
**File:** `src/com/sulake/habbo/room/utils/FurnitureData.as`

Runtime instance data:

| Property | Type | Description |
|----------|------|-------------|
| `id` | int | Instance ID |
| `typeId` | int | Furniture type ID |
| `type` | String | "s" or "i" |
| `loc` | Vector3D | Position |
| `dir` | Vector3D | Direction |
| `state` | int | Current state |
| `data` | IStuffData | Custom data |
| `ownerId` | int | Owner user ID |
| `ownerName` | String | Owner name |

## FurnitureLogic

**File:** `src/com/sulake/habbo/room/object/logic/furniture/FurnitureLogic.as`

Base class for all furniture logic:

### Key Responsibilities

| Method | Purpose |
|--------|---------|
| `initialize(k:XML)` | Parse dimensions and configuration |
| `mouseEvent(k:RoomSpriteMouseEvent, _arg_2:IRoomGeometry)` | Handle mouse interaction |
| `useObject()` | Trigger widget open, state change |
| `processUpdateMessage(k:RoomObjectUpdateMessage)` | Process server updates |
| `update(k:int)` | Update bounce animation |

### Mouse Event Handling

```actionscript
// ROOLL_OVER - Show tooltip
// ROLL_OUT - Hide tooltip
// CLICK - Open context menu
// DOUBLE_CLICK - Use object
// MOUSE_DOWN - Start drag (for placement)
```

### Bounce Animation

Furniture has a subtle bounce effect when rotated:
- 8 rotation steps
- 0.0625 height increment per step

## FurnitureVisualization

**File:** `src/com/sulake/habbo/room/object/visualization/furniture/FurnitureVisualization.as`

Base class for all furniture rendering:

### Key Methods

| Method | Purpose |
|--------|---------|
| `update(k:IRoomGeometry, _arg_2:int, ...)` | Main render loop |
| `updateObject(k, _arg_2)` | Update direction |
| `updateModel(k)` | Update from model |
| `updateAnimation(k):int` | Animation update (override) |
| `updateSprite(k, _arg_2)` | Update sprite properties |

### Layer System

Furniture can have up to 26 layers (a-z):
- Each layer has its own sprite
- Properties: alpha, color, offset, z-depth

## Type Mapping System

### Logic Mapping (RoomObjectLogicComponent)

| Logic Key | Class | Purpose |
|-----------|-------|---------|
| `FURNITURE_BASIC` | FurnitureLogic | Default |
| `FURNITURE_MULTISTATE` | FurnitureMultistateLogic | Multi-state items |
| `FURNITURE_DICE` | FurnitureDiceLogic | Dice |
| `FURNITURE_STICKIE` | FurnitureStickieLogic | Stickies |
| `FURNITURE_SOUND_MACHINE` | FurnitureSoundMachineLogic | Sound machine |
| `FURNITURE_JUKEBOX` | FurnitureJukeboxLogic | Jukebox |
| `FURNITURE_PRESENT` | FurniturePresentLogic | Presents |
| `FURNITURE_ONE_WAY_DOOR` | FurnitureOneWayDoorLogic | Teleporter |
| `FURNITURE_WINDOW` | FurnitureWindowLogic | Windows |
| `FURNITURE_ROOMDIMMER` | FurnitureRoomDimmerLogic | Dimmers |
| `FURNITURE_MANNEQUIN` | FurnitureMannequinLogic | Mannequins |
| `FURNITURE_YOUTUBE` | FurnitureYoutubeLogic | YouTube TV |
| ... and 50+ more |

### Visualization Mapping (RoomObjectVisualizationFactory)

| Type | Class | Purpose |
|------|-------|---------|
| `FURNITURE_STATIC` | FurnitureVisualization | Static items |
| `FURNITURE_ANIMATED` | FurnitureAnimatedVisualization | Animated items |
| `FURNITURE_STICKIE` | FurnitureStickieVisualization | Stickies |
| `FURNITURE_BOTTLE` | FurnitureBottleVisualization | Dice bottles |
| `FURNITURE_HABBOWHEEL` | FurnitureHabbowheelVisualization | Habbo wheel |
| `FURNITURE_YOUTUBE` | FurnitureYoutubeVisualization | YouTube |
| `FURNITURE_MANNEQUIN` | FurnitureMannequinVisualization | Mannequin |
| `FURNITURE_GUILD_CUSTOMIZED` | FurnitureGuildCustomizedVisualization | Guild items |
| ... and 50+ more |

### Type Resolution Flow

```
RoomEngine creates furniture
       │
       ▼
RoomContentLoader.getLogicType(typeId)
       │   └─ Reads "logic" from index XML
       │
       ▼
RoomObjectLogicComponent.createRoomObjectLogic(key)
       │   └─ Returns appropriate logic class
       │
       ▼
RoomContentLoader.getVisualizationType(typeId)
       │   └─ Reads "visualization" from index XML
       │
       ▼
RoomObjectVisualizationFactory.createRoomObjectVisualization(type)
       │   └─ Returns appropriate visualization class
       │
       ▼
Furniture loads VisualizationData from _visualization XML
```

## RoomObjectPlacementSource

**File:** `src/com/sulake/habbo/room/enum/RoomObjectPlacementSource.as`

```actionscript
public static const CATALOG:String = "catalog";    // From purchase
public static const INVENTORY:String = "inventory"; // From inventory
```

Used when placing furniture:
- `RoomEngine.initializeRoomObjectInsert(typeId, source, ...)`
- Validates placement source for permissions

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/session/furniture/IFurnitureData.as` | Catalog interface |
| `src/com/sulake/habbo/session/furniture/FurnitureData.as` | Session data |
| `src/com/sulake/habbo/room/utils/FurnitureData.as` | Room instance data |
| `src/com/sulake/habbo/room/object/logic/furniture/FurnitureLogic.as` | Base logic |
| `src/com/sulake/habbo/room/object/visualization/furniture/FurnitureVisualization.as` | Base visualization |
| `src/com/sulake/habbo/room/RoomObjectLogicComponent.as` | Logic factory |
| `src/com/sulake/habbo/room/object/RoomObjectVisualizationFactory.as` | Visualization factory |
| `src/com/sulake/habbo/room/enum/RoomObjectPlacementSource.as` | Placement modes |

## Next Steps

- [Furniture Interactions](Core-Systems/Furniture-System/Interactions) - Click/use handling
- [Furniture Types](Core-Systems/Furniture-System/Types) - Specialized furniture types