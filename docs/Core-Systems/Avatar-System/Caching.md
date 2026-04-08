# Avatar Caching

The Avatar Caching system optimizes rendering performance by caching composited body part images at multiple levels. This document details the cache hierarchy and management.

## Cache Hierarchy Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CACHE HIERARCHY                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      AvatarImage                                    │   │
│   │  (Per avatar instance - stored in AvatarImageCache)               │   │
│   │                                                                       │   │
│   │   Cache Key: [figureString, scale, direction, action, frame]       │   │
│   │                                                                       │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                   AvatarImageCache                                  │   │
│   │  ┌───────────────────────────────────────────────────────────────┐  │   │
│   │  │               AvatarImageActionCache                          │  │   │
│   │  │  ┌─────────────────────────────────────────────────────────┐  │  │   │
│   │  │  │            AvatarImageBodyPartCache                     │  │  │   │
│   │  │  │  ┌─────────────────────────────────────────────────────┐ │  │  │   │
│   │  │  │  │         AvatarImageDirectionCache                  │ │  │  │   │
│   │  │  │  │  ┌───────────────────────────────────────────────┐  │ │  │  │   │
│   │  │  │  │  │     AvatarImageBodyPartContainer (BitmapData)│  │ │  │  │   │
│   │  │  │  │  └───────────────────────────────────────────────┘  │ │  │  │   │
│   │  │  │  └─────────────────────────────────────────────────────┘  │  │  │   │
│   │  │  └─────────────────────────────────────────────────────────┘  │  │   │
│   │  └───────────────────────────────────────────────────────────────┘  │   │
│   │                                                                       │   │
│   │   Cache Key: [actionId, direction]                                  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                  BitmapDataCache (global)                          │   │
│   │  - Transformed bitmaps (flip, color transform)                      │   │
│   │  - Memory management                                                 │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## AvatarImageCache

**File:** `src/com/sulake/habbo/avatar/cache/AvatarImageCache.as`

Top-level cache for avatar images:

```actionscript
public class AvatarImageCache
{
    private var _Str_2189:int = 60000;  // 60 second timeout
    private var _caches:Map;            // action -> AvatarImageActionCache
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `getImage(k, _arg_2, _arg_3, _arg_4, _arg_5)` | Get cached image |
| `_Str_2363(k, _arg_2, _arg_3, _arg_4, _arg_5)` | Add image to cache |
| `setCachingEnabled(k, _arg_2)` | Enable/disable caching |

### Cache Key Components

```actionscript
// Key = actionId + direction + frame + avatar set type
var key:String = actionId + "_" + direction + "_" + frame + "_" + avatarSetType;
```

## AvatarImageActionCache

**File:** `src/com/sulake/habbo/avatar/cache/AvatarImageActionCache.as`

Caches images for a specific action:

```actionscript
public class AvatarImageActionCache
{
    private var _caches:Map;  // direction -> AvatarImageBodyPartCache
}
```

### Methods

| Method | Purpose |
|--------|---------|
| `getBodyPartCache(k)` | Get cache for direction |
| `_Str_1768(k, _arg_2)` | Add body part cache |

## AvatarImageBodyPartCache

**File:** `src/com/sulake/habbo/avatar/cache/AvatarImageBodyPartCache.as`

Caches images for a body part type:

```actionscript
public class AvatarImageBodyPartCache
{
    private var _caches:Map;  // bodyPartType -> AvatarImageDirectionCache
}
```

## AvatarImageDirectionCache

**File:** `src/com/sulake/habbo/avatar/cache/AvatarImageDirectionCache.as`

Caches images for a specific direction:

```actionscript
public class AvatarImageDirectionCache
{
    private var _container:AvatarImageBodyPartContainer;
}
```

### AvatarImageBodyPartContainer

```actionscript
public class AvatarImageBodyPartContainer
{
    private var _image:BitmapData;
    private var _imageSet:BitmapData;
    private var _paletteMap:Array;
    private var _Str_2195:int;  // Frame number
}
```

## Cache Invalidation

### Triggers

| Trigger | Cause |
|---------|-------|
| Action change | New POSTURE, GESTURE, etc. |
| Direction change | Avatar turned |
| Figure change | Clothing changed |
| Frame change | Animation advanced |
| Disposal | Avatar removed |

### Invalidation Code

```actionscript
// When action changes
_caches.remove(actionId);

// When direction changes
_caches.remove(direction);

// When figure changes
_caches = new Map();  // Clear all
```

## Cache Size Management

### Memory Limits

```actionscript
// Global bitmap data cache in RoomRenderer
// Max size: ~50MB (configurable)

// Avatar caches are per-instance
// Cleared when AvatarImage is disposed
```

### Cleanup Strategy

```actionscript
// 1. Check if cache entry is stale (> 60 seconds)
if (currentTime - entry.timestamp > _Str_2189) {
    removeEntry(key);
}

// 2. When memory pressure
// AvatarImageCache may reduce quality or clear all

// 3. On avatar disposal
_caches.clear();
```

## Bitmap Transformation Cache

### BitmapDataCache

**File:** `src/com/sulake/room/renderer/cache/BitmapDataCache.as`

Caches transformed bitmaps (flip, color transform):

```actionscript
public function getBitmapData(
    k:BitmapData,           // Source image
    _arg_2:String,          // Transform ID
    _arg_3:Boolean,         // Flip horizontal
    _arg_4:Boolean,         // Flip vertical
    _arg_5:int              // Color transform
):BitmapData
{
    // Check cache
    // If miss: apply transform, store in cache
    // Return cached result
}
```

### Transform Types

| Transform | Parameters |
|-----------|------------|
| Color | RGB adjustment |
| Flip H | Mirror horizontally |
| Flip V | Mirror vertically |
| Combined | Color + Flip H + Flip V |

## Performance Optimization

### Cache Hit Flow

```
1. Request: getImage("full", false, 1.0)
2. Generate cache key: "std_4_0_full"
3. Check AvatarImageCache for key
4. If hit: return cached BitmapData immediately
5. If miss: render, store in cache, return
```

### Rendering Bypass

For animation frames, caching can be bypassed:

```actionscript
// Don't cache animated frames
if (action.isAnimated) {
    return renderWithoutCache();
}
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/avatar/cache/AvatarImageCache.as` | Top-level cache |
| `src/com/sulake/habbo/avatar/cache/AvatarImageActionCache.as` | Action cache |
| `src/com/sulake/habbo/avatar/cache/AvatarImageBodyPartCache.as` | Body part cache |
| `src/com/sulake/habbo/avatar/cache/AvatarImageDirectionCache.as` | Direction cache |
| `src/com/sulake/room/renderer/cache/BitmapDataCache.as` | Global bitmap cache |

## Next Steps

- [Furniture Architecture](Core-Systems/Furniture-System/Architecture) - Furniture system