# Avatar Rendering

The Avatar Rendering system generates the visual representation of user avatars - from figure string to composited bitmap. This document details the rendering pipeline, image composition, and asset management.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      AVATAR RENDERING ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      AvatarRenderManager                             │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ AvatarStructure │  │AliasCollection   │  │ AssetDownload   │   │   │
│  │  │                 │  │                  │  │ Manager         │   │   │
│  │  │ - Geometry      │  │ - Asset resolve │  │                 │   │   │
│  │  │ - Animation     │  │ - Figure map    │  │                 │   │   │
│  │  │ - Figure data   │  │                 │  │                 │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         AvatarImage                                 │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ AvatarFigure    │  │ AvatarImageCache │  │   getImage()   │   │   │
│  │  │ Container       │  │                  │  │                 │   │   │
│  │  │ (parsed figure) │  │ - Action cache   │  │ Composite       │   │   │
│  │  │                 │  │ - Direction cache│  │ bitmap output  │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      AvatarVisualization                            │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │   │
│  │  │ Room sprites    │  │ Direction       │  │   Additions    │   │   │
│  │  │                 │  │                  │  │                 │   │   │
│  │  │ - Render to    │  │ - Body + head   │  │ - Typing bubble│   │   │
│  │  │   room canvas  │  │   independent   │  │ - Effects      │   │   │
│  │  └──────────────────┘  └──────────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## AvatarRenderManager

**File:** `src/com/sulake/habbo/avatar/AvatarRenderManager.as`

The central hub for avatar rendering:

```actionscript
public class AvatarRenderManager extends Component implements IAvatarRenderManager
{
    private var _structure:AvatarStructure;
    private var _aliasCollection:AssetAliasCollection;
    private var _avatarAssetDownloadManager:AvatarAssetDownloadManager;
    private var _effectAssetDownloadManager:EffectAssetDownloadManager;
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `createAvatarImage()` | Creates AvatarImage from figure string |
| `validateAvatarFigure()` | Ensures figure has mandatory parts for gender |
| `isValidFigureSetForGender()` | Validates figure set for gender |
| `getAssetByName()` | Gets assets via alias collection |

### Initialization Flow

```actionscript
// 1. Create AvatarStructure
_structure = new AvatarStructure(this);

// 2. Initialize from embedded XML
_structure.initGeometry(embeddedGeometry);
_structure.initPartSets(embeddedPartSets);
_structure.initActions(embeddedActions);
_structure.initAnimation(embeddedAnimation);
_structure.initFigureData(embeddedFigureData);

// 3. Create AssetAliasCollection
_aliasCollection = new AssetAliasCollection(this, assets);

// 4. Download dynamic assets
// - figuremap.xml from server
// - effect assets
```

## AvatarImage

**File:** `src/com/sulake/habbo/avatar/AvatarImage.as`

The core class that generates composited avatar bitmaps:

```actionscript
public class AvatarImage extends Component implements IAvatarImage
{
    private var _structure:AvatarStructure;
    private var _avatarImageCache:AvatarImageCache;
    private var _figure:AvatarFigureContainer;
    private var _activeActionData:IActiveActionData;
    private var _scale:String;
    private var _frameCounter:int;
    private var _image:BitmapData;
}
```

### Main Method - getImage()

```actionscript
public function getImage(k:String, _arg_2:Boolean = false, _arg_3:Number = 1):BitmapData
{
    // k: AvatarSetType ("full", "head", "figure")
    // _arg_2: Return clone vs cached
    // _arg_3: Scale factor
    
    // 1. Get canvas dimensions
    var canvas:IAvatarCanvas = _structure.getCanvas(_scale, "vertical");
    
    // 2. Get body parts sorted by depth
    var parts:Array = _structure.getBodyParts(k, "vertical", _direction);
    
    // 3. For each body part:
    //    - Get image from cache
    //    - Composite onto final image
    // 4. Apply effects (sleep grayscale)
    // 5. Return scaled result
}
```

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `_structure` | AvatarStructure | Geometry/animation reference |
| `_avatarImageCache` | AvatarImageCache | Body part image cache |
| `_figure` | AvatarFigureContainer | Parsed figure configuration |
| `_activeActionData` | IActiveActionData | Current action state |
| `_scale` | String | "large" (64px) or "small" (32px) |
| `_frameCounter` | int | Animation frame |

### Action System

Append actions to modify appearance:

```actionscript
// Postures
appendAction(AvatarAction.POSTURE, "std")     // Stand
appendAction(AvatarAction.POSTURE, "sit")      // Sit
appendAction(AvatarAction.POSTURE, "mv")      // Walk
appendAction(AvatarAction.POSTURE, "lay")     // Lay down
appendAction(AvatarAction.POSTURE, "swim")    // Swimming

// Gestures
appendAction(AvatarAction.GESTURE, "sml")      // Smile
appendAction(AvatarAction.GESTURE, "sad")     // Sad
appendAction(AvatarAction.GESTURE, "agr")      // Aggravated

// Effects
appendAction(AvatarAction.EFFECT, "fx33")      // Effect ID

// Dance
appendAction(AvatarAction.DANCE, "1")         // Dance style 1
```

## AvatarStructure

**File:** `src/com/sulake/habbo/avatar/AvatarStructure.as`

Holds all avatar data (geometry, figure, animation):

```actionscript
public class AvatarStructure extends Component
{
    private var _geometry:AvatarModelGeometry;
    private var _figureData:FigureSetData;
    private var _animationData:AnimationData;
    private var _animationManager:AnimationManager;
    private var _actionManager:AvatarActionManager;
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `getBodyParts()` | Returns body parts sorted by depth |
| `getCanvas()` | Gets canvas dimensions for scale/type |
| `initGeometry()` | Initialize 3D geometry from XML |
| `initAnimation()` | Initialize animations from XML |

### getBodyParts Output

```actionscript
// Returns array of part IDs ordered by distance from camera
// Render order = front to back (highest z drawn last)
["sh", "ch", "lg", "hd", "hr"]
```

## AvatarVisualization

**File:** `src/com/sulake/room/object/visualization/avatar/AvatarVisualization.as`

Renders avatars within rooms:

```actionscript
public class AvatarVisualization extends RoomObjectVisualization
{
    private var _activeAvatarImage:AvatarImage;
    private var _direction:int;
    private var _headDirection:int;
}
```

### Room Sprite Rendering

```actionscript
// 1. Get or create AvatarImage
_activeAvatarImage = _avatarImage.getImage(AvatarSetType.FULL, true, 1.0);

// 2. Update direction
_activeAvatarImage.setDirectionAngle(AvatarSetType.FULL, bodyDir);
_activeAvatarImage.setDirectionAngle(AvatarSetType.HEAD, headDir);

// 3. Get sprites from image
var sprites:Array = getSpriteList();

// 4. Render to room canvas
```

### Additions System

Overlays rendered on top of avatar:

| Addition | Class | Purpose |
|----------|-------|---------|
| TypingBubble | `TypingBubble.as` | Shows when typing |
| MutedBubble | `MutedBubble.as` | Shows when muted |
| FloatingIdleZ | `FloatingIdleZ.as` | Sleep indicator (Zzz) |
| NumberBubble | `NumberBubble.as` | Player count |

### Direction Independence

```actionscript
// Body direction
_activeAvatarImage.setDirectionAngle(AvatarSetType.FULL, bodyDirection);

// Head direction (can differ from body)
_activeAvatarImage.setDirectionAngle(AvatarSetType.HEAD, headDirection);
```

## Figure String Format

### Format Structure

```
type-setId-color1-color2.type-setId-color1...

Example: hr-893-45.hd-180-2.ch-210-66.lg-270-82.sh-300-91.wa-2007-.ri-1-
```

### Part Type Codes

| Code | Part | Example |
|------|------|---------|
| `hr` | Hair | hr-893-45 |
| `hd` | Head | hd-180-2 |
| `ch` | Chest | ch-210-66 |
| `lg` | Legs | lg-270-82 |
| `sh` | Shoes | sh-300-91 |
| `wa` | Waist | wa-2007 |
| `ri` | Right arm | ri-1 |
| `le` | Left arm | le-1 |
| `fa` | Face | fa-1 |

### Parsing - AvatarFigureContainer

**File:** `src/com/sulake/habbo/avatar/AvatarFigureContainer.as`

```actionscript
// Input: "hr-893-45.hd-180-2.ch-210-66"
// Output: Map {
//   "hr" => {type: "hr", setId: 893, colorIds: [45]}
//   "hd" => {type: "hd", setId: 180, colorIds: [2]}
//   "ch" => {type: "ch", setId: 210, colorIds: [66]}
// }
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `getPartSetId(type)` | Get part set ID for type |
| `getColorIDs(type)` | Get color IDs for type |
| `setPart(type, setId, colors)` | Set part configuration |
| `getFigureString()` | Serialize back to string |

## Asset Loading

### AvatarAssetDownloadManager

**File:** `src/com/sulake/habbo/avatar/AvatarAssetDownloadManager.as`

### Download Flow

```
1. Figure String: "hd-180-2.ch-210-66"
2. Look up in figureMap: "hd:180" -> ["HD-180"]
3. Check if library loaded
4. If not, queue download
5. On load complete, notify
```

### URL Template

```
{base_url}{name_template}
// Example: "habbo-a/10/HR-893-45.swf"
```

### Check Availability

```actionscript
public function isReady(k:AvatarFigureContainer):Boolean
{
    // Parse figure into part types
    // Look up required libraries
    // Return true if all loaded
}
```

## Cache Hierarchy

```
AvatarImageCache (per AvatarImage instance)
    │
    ├── AvatarImageActionCache (per action)
    │       │
    │       ├── AvatarImageBodyPartCache (per body part)
    │       │       │
    │       │       ├── AvatarImageDirectionCache (per direction)
    │       │       │       │
    │       │       │       └── AvatarImageBodyPartContainer (BitmapData)
```

### Cache Invalidation

```actionscript
// Cache invalidates when:
// - Action changes
// - Direction changes
// - Figure changes
// - Frame counter changes
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/avatar/AvatarRenderManager.as` | Main entry point |
| `src/com/sulake/habbo/avatar/AvatarImage.as` | Composite rendering |
| `src/com/sulake/habbo/avatar/AvatarStructure.as` | Data structures |
| `src/com/sulake/habbo/avatar/AvatarFigureContainer.as` | Figure parsing |
| `src/com/sulake/habbo/room/object/visualization/avatar/AvatarVisualization.as` | Room rendering |
| `src/com/sulake/habbo/avatar/cache/AvatarImageCache.as` | Image cache |

## Next Steps

- [Avatar Figure Data](Core-Systems/Avatar-System/Figure-Data) - Detailed figure parsing
- [Avatar Actions](Core-Systems/Avatar-System/Actions) - Animation system
- [Avatar Caching](Core-Systems/Avatar-System/Caching) - Cache implementation