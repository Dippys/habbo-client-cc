# Room Engine Architecture

The Room Engine is the heart of the Habbo client's visual gameplay, responsible for rendering the isometric hotel rooms, managing room objects (furniture, avatars), and handling all room-related interactions.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ROOM ENGINE ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         RoomEngine                                  │    │
│  │  ┌────────────────┐  ┌────────────────┐  ┌─────────────────────┐  │    │
│  │  │  RoomManager   │  │ContentLoader  │  │   Visualization     │  │    │
│  │  │               │  │               │  │     Factory         │  │    │
│  │  └────────────────┘  └────────────────┘  └─────────────────────┘  │    │
│  │                                                                       │    │
│  │  - Creates/deletes rooms                                            │    │
│  │  - Manages room objects                                             │    │
│  │  - Update loop (30 FPS)                                             │    │
│  │  - Mouse interaction                                                │    │
│  └──────────────────────────────┬──────────────────────────────────────┘    │
│                                 │                                           │
│              ┌──────────────────┼──────────────────┐                      │
│              │                  │                  │                      │
│              ▼                  ▼                  ▼                      │
│  ┌─────────────────┐   ┌─────────────────┐  ┌─────────────────────┐      │
│  │    RoomManager   │   │ RoomContentLoader│  │VisualizationFactory │      │
│  │                  │   │                  │  │                     │      │
│  │ RoomInstance    │   │ Furniture data   │  │FurnitureVisualiz.   │      │
│  │   ├─ Objects    │   │ Pet assets       │  │AvatarVisualiz.      │      │
│  │   ├─ Renderer   │   │ Graphic assets  │  │RoomVisualization    │      │
│  │   └─ Camera     │   │                  │  │PetVisualization     │      │
│  └─────────────────┘   └─────────────────┘  └─────────────────────┘      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Core Components

### RoomEngine
**File:** `src/com/sulake/habbo/room/RoomEngine.as`

The main entry point for all room-related functionality:

```actionscript
public class RoomEngine extends Component 
    implements IRoomEngine, IRoomManagerListener, IRoomCreator, 
               IRoomEngineServices, IUpdateReceiver, IRoomContentListener
{
    private var _roomManager:IRoomManager;
    private var _roomObjectFactory:IRoomObjectFactory;
    private var _visualizationFactory:IRoomObjectVisualizationFactory;
    private var _roomContentLoader:RoomContentLoader;
    private var _activeRoomId:int;
    private var _roomInstanceDatas:Map;
}
```

### Key Responsibilities

| Method | Purpose |
|--------|---------|
| `createRoomObject()` | Creates furniture/avatar/wall items in a room |
| `getRoomObject()` | Retrieves a specific room object |
| `createRoomCanvas()` | Creates a rendering canvas for a room view |
| `initializeRoomObjectInsert()` | Initiates furniture placement mode |
| `modifyRoomObject()` | Updates object properties |
| `deleteRoomObject()` | Removes object from room |
| `update()` | Main update loop (called every frame) |

### Initialization Flow

```actionscript
override protected function initComponent():void
{
    // Create room instance data map
    _roomInstanceDatas = new Map();
    
    // Create number bank for unique IDs
    _numberBank = new NumberBank(1);
    
    // Create event and message handlers
    _roomObjectEventHandler = new RoomObjectEventHandler();
    _roomMessageHandler = new RoomMessageHandler();
    
    // Initialize content loader
    _roomContentLoader = new RoomContentLoader();
    _roomContentLoader.initialize(events, configuration);
    
    // Register for updates (30 FPS priority)
    // Set up object update categories
}
```

### Update Loop

```actionscript
public function update(k:uint):void
{
    // Batch create pending furniture
    createRoomFurniture();
    
    // Update all room instances
    _roomManager.update(k);
    
    // Update all room renderers
    updateRenderers(k);
    
    // Update room cameras
    updateCameras(k);
    
    // Update cursor if needed
    updateCursor(k);
}
```

## RoomManager

**File:** `src/com/sulake/room/RoomManager.as`

Manages multiple room instances:

```actionscript
public class RoomManager extends Component implements IRoomManager, IRoomInstanceContainer
{
    private var _rooms:Map;                    // String ID -> RoomInstance
    private var _state:int;                    // State machine
    private var _rendererFactory:IRoomRendererFactory;
    private var _contentLoader:IRoomContentLoader;
}
```

### RoomManager States

```actionscript
public static const ROOM_MANAGER_ERROR:int = -1;
public static const ROOM_MANAGER_LOADING:int = 0;
public static const ROOM_MANAGER_LOADED:int = 1;
public static const ROOM_MANAGER_INITIALIZING:int = 2;
public static const ROOM_MANAGER_INITIALIZED:int = 3;
```

### Room Creation

```actionscript
public function createRoom(k:String, _arg_2:IRoomRendererFactory):IRoomInstance
{
    var roomInstance:RoomInstance = new RoomInstance(k, this, _rendererFactory);
    roomInstance.initialize();
    
    _rooms.add(k, roomInstance);
    return roomInstance;
}
```

## RoomInstance

**File:** `src/com/sulake/room/RoomInstance.as`

Represents a single room with all its objects:

```actionscript
public class RoomInstance implements IRoomInstance
{
    private var _managers:Map;                // Category -> RoomObjectManager
    private var _renderer:IRoomRendererBase;
    private var _container:IRoomInstanceContainer;
    private var _numberData:Dictionary;
    private var _stringData:Dictionary;
}
```

### Per-Room Components

| Component | Purpose |
|-----------|---------|
| `RoomObjectManager` (per category) | Manages objects of that type |
| `RoomRenderer` | Renders the room view |
| `RoomCamera` | Camera position and target |
| `LegacyWallGeometry` | Wall position calculations |
| `FurniStackingHeightMap` | Furniture stacking heights |
| `TileObjectMap` | Tile occupancy |

### Object Access Methods

```actionscript
// Create object in room
public function createRoomObject(k:int, _arg_2:String, _arg_3:int):IRoomObject

// Get object by ID and category
public function getObject(k:int, _arg_2:int):IRoomObject

// Get all objects in category
public function getObjects(k:int):Array
```

## Object Categories

**File:** `src/com/sulake/habbo/room/object/RoomObjectCategoryEnum.as`

```actionscript
public class RoomObjectCategoryEnum 
{
    public static const OBJECT_CATEGORY_UNKNOWN:int = -2;
    public static const OBJECT_CATEGORY_ROOM:int = 0;        // Floor, walls
    public static const OBJECT_CATEGORY_FURNITURE:int = 10;   // Floor items
    public static const OBJECT_CATEGORY_WALLITEM:int = 20;     // Wall items
    public static const OBJECT_CATEGORY_USER:int = 100;       // Avatars
    public static const OBJECT_CATEGORY_CURSOR:int = 200;     // Cursor
    public static const SNOWBALL:int = 201;                   // SnowStorm game
    public static const SNOW_SPLASH:int = 202;
}
```

### Category Usage

| Category | Objects | Example |
|----------|---------|---------|
| 0 | Room | Floor tiles, walls, masks |
| 10 | Furniture | Chairs, tables, lamps |
| 20 | Wall Items | Posters, wall decorations |
| 100 | Users | Avatars, pets, bots |
| 200 | Cursor | Selection arrow, tile cursor |

## Content Loading

### RoomContentLoader
**File:** `src/com/sulake/habbo/room/RoomContentLoader.as`

Loads furniture, pet, and room assets:

```actionscript
public class RoomContentLoader implements IRoomContentLoader, IFurniDataListener, IDisposable
{
    private var _libraries:Map;
    private var _activeObjectTypes:Map;
    private var _wallItemTypes:Map;
    private var _petTypes:Map;
    private var _assetCollections:Map;
}
```

### Placeholder Types

```actionscript
public static const PLACE_HOLDER:String = "place_holder";
public static const WALL_PLACE_HOLDER:String = "wall_place_holder";
public static const PET_PLACE_HOLDER:String = "pet_place_holder";
public static const ROOM:String = "room";
public static const TILE_CURSOR:String = "tile_cursor";
public static const SELECTION_ARROW:String = "selection_arrow";
```

### Asset Loading Flow

```
1. RoomEngine initializes RoomContentLoader
2. RoomContentLoader.initialize() loads furniture data from session
3. When entering room, request furniture type assets
4. RoomContentLoader.getVisualizationType() returns appropriate type
5. If not loaded, uses placeholder until asset arrives
```

## Visualization Factory

**File:** `src/com/sulake/habbo/room/object/RoomObjectVisualizationFactory.as`

Maps object types to visualization classes:

```actionscript
public class RoomObjectVisualizationFactory extends Component implements IRoomObjectVisualizationFactory
{
    public function createRoomObjectVisualization(k:String):IRoomObjectGraphicVisualization
}
```

### Visualization Type Mapping

| Type String | Visualization Class |
|-------------|-------------------|
| `room` | `RoomVisualization` |
| `tile_cursor` | `TileCursorVisualization` |
| `user` | `AvatarVisualization` |
| `bot` | `AvatarVisualization` |
| `pet_animated` | `AnimatedPetVisualization` |
| `furniture_static` | `FurnitureVisualization` |
| `furniture_animated` | `FurnitureAnimatedVisualization` |
| `furniture_reset` | `FurnitureResettingAnimatedVisualization` |
| `furniture_bottle` | `FurnitureBottleVisualization` |
| `furniture_stickie` | `FurnitureStickieVisualization` |
| `furniture_youtube` | `FurnitureYoutubeVisualization` |

## Supporting Systems

### RoomCamera
**File:** `src/com/sulake/habbo/room/utils/RoomCamera.as`

Manages camera position, target, and zoom:

```actionscript
public class RoomCamera
{
    public function getScreenPositionForPosition(k:Number, _arg_2:Number, _arg_3:Number):Point
    public function getZoom():int
    public function setTarget(k:Vector3D):void
}
```

### LegacyWallGeometry
**File:** `src/com/sulake/habbo/room/utils/LegacyWallGeometry.as`

Calculates wall item positions:

```actionscript
public function getPositionForWallItem(k:String, _arg_2:Number):WallPosition
public function getWidthOfWallItem(k:String):Number
```

### FurniStackingHeightMap
**File:** `src/com/sulake/habbo/room/utils/FurniStackingHeightMap.as`

Tracks furniture heights for stacking:

```actionscript
public function getStackingHeightMap():Map  // [x,y] -> height
public function getObjectHeightForLocation(k:int, _arg_2:int):Number
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/room/RoomEngine.as` | Main entry point |
| `src/com/sulake/room/RoomManager.as` | Room instance management |
| `src/com/sulake/room/RoomInstance.as` | Single room state |
| `src/com/sulake/room/RoomObjectManager.as` | Object tracking per category |
| `src/com/sulake/habbo/room/RoomContentLoader.as` | Asset loading |
| `src/com/sulake/habbo/room/object/RoomObjectVisualizationFactory.as` | Visualization creation |
| `src/com/sulake/habbo/room/object/RoomObjectCategoryEnum.as` | Category definitions |
| `src/com/sulake/room/renderer/RoomRenderer.as` | Rendering management |
| `src/com/sulake/room/renderer/RoomSpriteCanvas.as` | Canvas rendering |

## Next Steps

- [Room Object Lifecycle](Core-Systems/Room-Engine/Object-Lifecycle) - Object creation, updates, disposal
- [Room Rendering](Core-Systems/Room-Engine/Rendering) - Render pipeline details
- [Room Heightmaps](Core-Systems/Room-Engine/Heightmaps) - Tile geometry
