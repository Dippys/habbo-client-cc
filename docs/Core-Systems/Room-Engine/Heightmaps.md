# Room Heightmaps

Heightmaps define the 3D terrain of a room - the floor heights, furniture stacking, and wall positioning. This document details how height data flows from the server to the client and how it's used for rendering and interaction.

## Heightmap System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        HEIGHTMAP SYSTEM OVERVIEW                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Server Sends          ┌──────────────────┐                                 │
│  ────────────────►     │ FloorHeightMap  │                                 │
│  Heightmap String      │    MessageParser │                                 │
│                       └────────┬─────────┘                                 │
│                                │                                            │
│              ┌─────────────────┼─────────────────┐                         │
│              ▼                 ▼                 ▼                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │FurniStacking     │  │ LegacyWall       │  │  TileObjectMap  │         │
│  │HeightMap         │  │ Geometry         │  │                  │         │
│  │                  │  │                  │  │                  │         │
│  │ - Tile heights   │  │ - Wall positions │  │ - Object lookup │         │
│  │ - Stacking       │  │ - Old format     │  │ - Click detection│        │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                              │
│  Used By:        Used By:                    Used By:                      │
│  - Rendering     - Wall item placement       - Furniture placement         │
│  - Pathfinding   - Wall item rendering       - Object picking              │
│  - Collision     - Door positioning           - Collision detection        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## FloorHeightMap

### Data Format

The server sends the heightmap as a string where:
- Each character represents one tile's height
- Characters `0-9` and `A-Z` represent heights 0-35
- `x` or `X` represents blocked (wall/void) tiles
- Tiles are separated by `\r` (carriage return)

### Example

```
xxxxxxxxxxxx
x222211110xx
x222211110xx
x222211110xx
x222222220xx
x222222220xx
xxxxxxxxxxxx
```

### Constants

```actionscript
public static const TILE_BLOCKED:int = -1;   // Unwalkable
public static const TILE_HOLE:int = -2;    // Floor hole
```

### Height Values

| Character | Value | Description |
|-----------|-------|-------------|
| `0`-`9` | 0-9 | Height level |
| `A`-`Z` | 10-35 | Height level |
| `x`, `X` | -1 | Blocked/wall |
| ` ` (space) | 0 | Empty (legacy) |

### Parser

**File:** `com/sulake.habbo.communication.messages.parser.room.engine/FloorHeightMapMessageParser.as`

```actionscript
public function parse(data:IMessageDataWrapper):Boolean
{
    var heightMap:String = data.readString();
    // Parse string into height array
    // x/X = TILE_BLOCKED
    // Characters 0-9, A-Z = height values 0-35
}
```

## FurniStackingHeightMap

**File:** `src/com/sulake/habbo/room/utils/FurniStackingHeightMap.as`

Tracks the combined height at each tile (floor + furniture) for stacking validation.

### Internal Data

```actionscript
private var _heightMap:Vector.<Number>;      // Height at each tile
private var _isNotStackable:Vector.<Boolean>; // Block stacking
private var _isRoomTile:Vector.<Boolean>;     // Valid room floor
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `getTileHeight(x, y)` | Returns combined height (floor + furniture) |
| `setTileHeight(x, y, height)` | Sets height at position |
| `setStackingBlocked(x, y, blocked)` | Marks tile as non-stackable |
| `setIsRoomTile(x, y, isRoomTile)` | Marks valid room floor |
| `validateLocation(...)` | Validates furniture placement |

### Validation Logic

```actionscript
public function validateLocation(
    x:int, y:int, 
    sizeX:int, sizeY:int, 
    direction:int, 
    checkRoomTile:Boolean
):Boolean
{
    // 1. Check bounds
    // 2. If checkRoomTile: all tiles must be valid room tiles
    // 3. All tiles must have same height (within 0.01 tolerance)
    // 4. Tiles must not be blocked
}
```

## TileObjectMap

**File:** `src/com/sulake/habbo/room/utils/TileObjectMap.as`

Maps each tile to the object occupying it for click detection and collision.

### Internal Data

```actionscript
private var _tileObjectMap:Vector.<Vector.<IRoomObject>>;
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `getObjectInTile(x, y)` | Get topmost object at tile |
| `setObjectInTile(x, y, object)` | Set object at tile |
| `addRoomObject(object)` | Add object based on its size/direction |
| `populate(objects)` | Populate from array of objects |
| `clear()` | Clear all tiles |

### Object Placement Logic

```actionscript
public function addRoomObject(object:IRoomObject):void
{
    var sizeX:int = object.getModel().getNumber(FURNITURE_SIZE_X);
    var sizeY:int = object.getModel().getNumber(FURNITURE_SIZE_Y);
    var direction:int = object.getDirection().z;
    
    // Rotate if direction is 90 or 270
    if (direction == 90 || direction == 270)
    {
        // Swap sizeX and sizeY
    }
    
    // For each tile the object occupies
    // Store the object (with highest Z wins)
}
```

## LegacyWallGeometry

**File:** `src/com/sulake/habbo/room/utils/LegacyWallGeometry.as`

Handles legacy wall positioning - converts between old Habbo wall format and 3D coordinates.

### Old Format

Wall items use a legacy coordinate system:
```
:w=x,y l=x,y side=L|R
```
- `:w=x,y` - Wall position (relative to room corner)
- `l=x,y` - Offset along the wall
- `side=L|R` - Which wall (Left=90°, Right=180°)

### Key Methods

| Method | Purpose |
|--------|---------|
| `initialize(width, height, floorHeight)` | Initialize arrays |
| `setTileHeight(x, y, height)` | Set floor height |
| `getTileHeight(x, y)` | Get floor height |
| `getLocation(x, y, offsetX, offsetY, side)` | Convert tile+offset to 3D |
| `getLocationOldFormat(nx, ny, side)` | Convert old format to 3D |
| `getOldLocation(position, direction)` | Convert 3D to old format |
| `getOldLocationString(position, direction)` | Get legacy location string |

### Wall Constants

```actionscript
public static const LEFT_WALL:String = "L";    // Direction 90
public static const RIGHT_WALL:String = "R";   // Direction 180
```

### Position Calculation

```actionscript
public function getLocation(x:int, y:int, offsetX:int, offsetY:int, side:String):IVector3d
{
    // Convert tile position + wall offset to 3D world coordinates
    // Takes into account floor height
    // Returns Vector3D(x, y, z)
}
```

## Integration Flow

### Server to Client

```
Server Message: FloorHeightMapComposer
        │
        ▼
FloorHeightMapMessageParser.parse()
        │
        ├─► RoomMessageHandler.onHeightMapUpdate()
        │        │
        │        ├─► Creates FurniStackingHeightMap
        │        │        └─► setTileHeight() for each tile
        │        │
        │        ├─► LegacyWallGeometry.initialize()
        │        │        └─► setTileHeight() for each tile
        │        │
        │        └─► Creates TileObjectMap (when needed)
        │
        ▼
RoomEngine updates height maps
```

### Usage in Rendering

```actionscript
// Floor rendering
RoomVisualization.parseRoomPlane()
    └── Uses FloorHeightMap for floor geometry
    
// Furniture Z-positioning
FurnitureVisualization.getHeight()
    └── Uses FurniStackingHeightMap + floor height
```

### Usage in Interaction

```actionscript
// Furniture placement validation
RoomObjectEventHandler.validateFurnitureLocation()
    └── Uses FurniStackingHeightMap.validateLocation()
    
// Click detection
RoomSpriteCanvas.handleMouseEvent()
    └── Uses TileObjectMap.getObjectInTile()
```

## Tile Coordinates

### Coordinate System

```
    ┌─────────────┐
    │    N (y=0)  │
    │             │
W   │   +-----+   │  E
(x=0)│   |     |   │(x=max)
    │   +-----+   │
    │             │
    │    S (y=max)│
    └─────────────┘
```

- X increases going East (right on screen)
- Y increases going South (down on screen)
- Z represents height (up on screen)

## Key Files Reference

| File | Purpose |
|------|---------|
| `FloorHeightMapMessageParser.as` | Parses heightmap from server |
| `src/com/sulake/habbo/room/utils/FurniStackingHeightMap.as` | Furniture stacking |
| `src/com/sulake/habbo/room/utils/TileObjectMap.as` | Tile occupancy |
| `src/com/sulake/habbo/room/utils/LegacyWallGeometry.as` | Wall positioning |
| `src/com/sulake/room/utils/RoomGeometry.as` | 3D projection |

## Next Steps

- [Avatar Rendering](Core-Systems/Avatar-System/Rendering) - Avatar visualization
- [Furniture Architecture](Core-Systems/Furniture-System/Architecture) - Furniture system
