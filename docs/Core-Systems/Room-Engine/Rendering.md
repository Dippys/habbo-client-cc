# Room Rendering

The Room Rendering system transforms 3D room data into 2D isometric visuals on the screen. This document details the rendering pipeline, sprite management, and geometry projection.

## Rendering Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ROOM RENDERING ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         RoomRenderer                                 │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │   Room Objects  │  │   Room Canvases  │  │  Render Loop    │   │   │
│  │  │     (Map)        │  │     (Map)        │  │   (30 FPS)      │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      RoomSpriteCanvas                               │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ RoomGeometry    │  │ RoomObjectCache  │  │ BitmapDataCache │   │   │
│  │  │ (3D→2D proj)    │  │ (sprite cache)  │  │ (transforms)    │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  │                                                                       │   │
│  │  ┌──────────────────────────────────────────────────────────────┐   │   │
│  │  │               Sprite Processing Pipeline                    │   │   │
│  │  │  1. Get objects   2. Get sprites  3. Project to 2D         │   │   │
│  │  │  4. Sort by Z     5. Update display 6. Clean up            │   │   │
│  │  └──────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## RoomRenderer

**File:** `src/com/sulake/room/renderer/RoomRenderer.as`

Manages all room objects and canvases:

```actionscript
public class RoomRenderer extends Component implements IRoomRenderer, IRoomSpriteCanvasContainer
{
    private var _objects:Map;
    private var _canvases:Map;
    private var _component:Component;
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `feedRoomObject()` | Add object to renderer |
| `removeRoomObject()` | Remove object from renderer |
| `createCanvas()` | Create new rendering canvas |
| `render()` | Main render call (called each frame) |
| `update()` | Update loop (render + canvas updates) |

### Render Loop

```actionscript
public function update(k:uint):void
{
    // Render all canvases
    render();
    
    // Update each canvas for mouse handling
    for each (var canvas:RoomSpriteCanvas in _canvases)
    {
        canvas.update(k);
    }
}
```

## RoomSpriteCanvas

**File:** `src/com/sulake/room/renderer/RoomSpriteCanvas.as`

The main rendering surface for a single view:

```actionscript
public class RoomSpriteCanvas implements IRoomRenderingCanvas
{
    private var _container:IRoomSpriteCanvasContainer;
    private var _geometry:RoomGeometry;
    private var _bitmapDataCache:BitmapDataCache;
    private var _roomObjectCache:RoomObjectCache;
    private var _sortableSpriteList:Array;
    private var _spritePool:Array;
}
```

### Rendering Pipeline

```
1. render(timestamp)
   │
   ├── 2. Update performance metrics
   │       └── Track frame times, detect slow mode
   │
   ├── 3. Compress bitmap cache
   │       └── Memory management
   │
   ├── 4. Iterate room objects
   │       └── For each: processSprites()
   │
   ├── 5. Get sprites from visualization
   │       └── Call object.getVisualization().getSprites()
   │
   ├── 6. Project to 2D via RoomGeometry
   │       └── Convert x,y,z to screen x,y,z
   │
   ├── 7. Create SortableSprite entries
   │       └── Store x, y, z, sprite reference
   │
   ├── 8. Sort by Z (descending)
   │       └── _sortableSpriteList.sortOn("z", DESCENDING | NUMERIC)
   │
   ├── 9. Update sprites on display
   │       └── updateSprite(index, sortableSprite)
   │
   └── 10. Clean up excess sprites
           └── Return unused to pool
```

### Sprite Processing

```actionscript
private function processSprites(k:IRoomObject, _arg_2:String, _arg_3:int, ...):int
{
    // Get screen position from geometry
    var screenPos:IVector3d = _geometry.getScreenPosition(object.getLocation());
    
    // Get sprites from visualization
    var sprites:Array = object.getVisualization().getSprites();
    
    // Create SortableSprite for each
    for each (var sprite:IRoomObjectSprite in sprites)
    {
        var sortable:SortableSprite = new SortableSprite();
        sortable.x = screenPos.x + sprite.offsetX;
        sortable.y = screenPos.y + sprite.offsetY;
        sortable.z = screenPos.z + sprite.relativeDepth;
        sortable.sprite = sprite;
        
        _sortableSpriteList.push(sortable);
    }
}
```

### Mouse Interaction

```actionscript
public function handleMouseEvent(...):Boolean
{
    // Convert screen coordinates
    // Hit test against sprites
    // Create RoomSpriteMouseEvent
    // Dispatch to object logic
}
```

## RoomGeometry

**File:** `src/com/sulake/room/utils/RoomGeometry.as`

Handles 3D to 2D isometric projection:

```actionscript
public class RoomGeometry extends Component implements IRoomGeometry
{
    private var _x:Vector3D;
    private var _y:Vector3D;
    private var _z:Vector3D;
    private var _loc:Vector3D;
    private var _dir:Vector3D;
    private var _depth:Vector3D;
    private var _scale:Number;
}
```

### Scale Constants

```actionscript
public static const SCALE_ZOOMED_IN:Number = 64;
public static const SCALE_ZOOMED_OUT:Number = 32;
```

### Screen Position Calculation

```actionscript
public function getScreenPosition(k:IVector3d):IVector3d
{
    // 1. Get relative position from camera
    var relative:IVector3d = getCoordinatePosition(k);
    
    // 2. Apply scale
    var scaledX:Number = relative.x * _scale;
    var scaledY:Number = relative.y * _scale;
    var scaledZ:Number = relative.z * _scale;
    
    // 3. Check depth clipping
    if (scaledZ < _clipNear || scaledZ > _clipFar)
        return null;  // Behind camera
    
    // 4. Project to 2D
    return new Vector3D(
        scaledX + _displacement.x,
        scaledY + _displacement.y,
        scaledZ
    );
}
```

### Isometric Projection

The Habbo client uses a fixed isometric projection where:
- Camera looks at the room from a 45-degree angle
- X axis goes down-right on screen
- Y axis goes down-left on screen
- Z axis (height) is vertical

## Sprite Caching

### RoomObjectCache

**File:** `src/com/sulake/room/renderer/cache/RoomObjectCache.as`

Caches objects for efficient rendering:

```actionscript
public function getObjectCache(k:String):RoomObjectCacheItem
{
    // Returns or creates cache item for object ID
}

public function removeObjectCache(k:String):void
{
    // Removes and disposes when object removed
}
```

### BitmapDataCache

**File:** `src/com/sulake/room/renderer/cache/BitmapDataCache.as`

Caches transformed bitmaps:

```actionscript
public function getBitmapData(k:BitmapData, _arg_2:String, ...):BitmapData
{
    // Applies transformations (flip, color)
    // Returns cached result or creates new
}
```

### Sprite Pool

Reuses sprite instances to reduce GC:

```actionscript
private function getSpriteFromPool():ExtendedSprite
{
    if (_spritePool.length > 0)
        return _spritePool.pop();
    return new ExtendedSprite();
}

private function returnSpriteToPool(sprite:ExtendedSprite):void
{
    _spritePool.push(sprite);
}
```

## Z-Ordering and Depth

### SortableSprite Structure

```actionscript
public class SortableSprite
{
    public var x:int = 0;           // Screen X
    public var y:int = 0;           // Screen Y
    public var z:Number = 0;        // Z-depth (higher = farther)
    public var name:String = "";   // Object identifier
    public var sprite:IRoomObjectSprite;  // Source sprite
}
```

### Z-Depth Calculation

```actionscript
// Base Z from projection
var baseZ:Number = screenPosition.z;

// Add relative depth within object
var finalZ:Number = baseZ + sprite.relativeDepth;

// Add tiny offset for tie-breaking
finalZ += 3.7E-11 * objectId;
```

### Sorting

```actionscript
// Higher z = farther = drawn first (behind)
_sortableSpriteList.sortOn("z", (Array.DESCENDING | Array.NUMERIC));
```

## Performance Monitoring

The canvas tracks frame performance:

```actionscript
// Constants
private static const _Str_12906:Number = 60;   // Slow threshold (ms)
private static const _Str_16799:Number = 50;   // Fast threshold (ms)
private static const _Str_7607:int = 50;       // Frame sample count
```

### Slow Mode

When average frame time exceeds 60ms:
- May skip object updates
- Reduces sprite quality
- Prioritizes basic rendering

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/room/renderer/RoomRenderer.as` | Main renderer |
| `src/com/sulake/room/renderer/RoomSpriteCanvas.as` | Canvas rendering |
| `src/com/sulake/room/utils/RoomGeometry.as` | 3D→2D projection |
| `src/com/sulake/room/renderer/cache/RoomObjectCache.as` | Object caching |
| `src/com/sulake/room/renderer/cache/BitmapDataCache.as` | Bitmap caching |
| `src/com/sulake/room/renderer/utils/SortableSprite.as` | Z-sorted sprite |

## Next Steps

- [Room Heightmaps](Core-Systems/Room-Engine/Heightmaps) - Tile geometry
- [Avatar Rendering](Core-Systems/Avatar-System/Rendering) - Avatar visualization
