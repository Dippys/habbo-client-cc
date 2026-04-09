# Avatar Rendering Flow

This document details the data flow from figure string input through asset resolution to final avatar rendering in the room.

## Avatar Rendering Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       AVATAR RENDERING FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    FIGURE STRING INPUT                              │   │
│  │                                                                       │   │
│  │  "hr-893-45.hd-180-2.ch-210-66.lg-270-82.sh-300-91.wa-2007-.ri-1-"  │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  AvatarFigureContainer.parseAvatarFigure()                          │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  Map { "hr" => {type:"hr", setId:893, colorIds:[45]}, ... }         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                 AVATAR IMAGE CREATION                               │   │
│  │                                                                       │   │
│  │  AvatarRenderManager.createAvatarImage(figure, scale, gender)      │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  AvatarImage(figure, structure, cache)                               │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  getImage(avatarSetType, clone, scale)                                │   │
│  │         │                                                             │   │
│  │    ┌────┴────┐                                                         │   │
│  │    ▼         ▼                                                         │   │
│  │  Cache Hit  Cache Miss                                                 │   │
│  │    │         │                                                         │   │
│  │    ▼         ▼                                                         │   │
│  │  Return    Asset Resolution                                          │   │
│  │  Cached    (figureMap lookup)                                         │   │
│  │  Bitmap    │                                                         │   │
│  │            ▼                                                         │   │
│  │         AvatarAssetDownloadManager                                   │   │
│  │            │                                                         │   │
│  │            ▼                                                         │   │
│  │         Composite body parts                                          │   │
│  │            │                                                         │   │
│  │            ▼                                                         │   │
│  │         Return BitmapData                                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                ROOM VISUALIZATION                                    │   │
│  │                                                                       │   │
│  │  AvatarVisualization.update()                                         │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  AvatarImage.getImage(avatarSetType, ...) ──► RoomObjectSprite[]     │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  getSpriteList() ──► IRoomObjectSprite[]                             │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  RoomSpriteCanvas renders sprites                                     │   │
│  │                                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Figure String Input

### Figure String Format

```
"hr-893-45.hd-180-2.ch-210-66.lg-270-82.sh-300-91.wa-2007-.ri-1-"
  │
  ├── hr = Hair
  ├── hd = Head
  ├── ch = Chest
  ├── lg = Legs
  ├── sh = Shoes
  ├── wa = Waist
  └── ri = Right arm
```

### AvatarFigureContainer Parsing

```
Figure String
        │
        ▼
AvatarFigureContainer.parseAvatarFigure()
        │
        ▼
Map {
  "hr" => {type: "hr", setId: 893, colorIds: [45]},
  "hd" => {type: "hd", setId: 180, colorIds: [2]},
  "ch" => {type: "ch", setId: 210, colorIds: [66]},
  "lg" => {type: "lg", setId: 270, colorIds: [82]},
  ...
}
```

## Avatar Image Creation

### Entry Point

```
AvatarRenderManager.createAvatarImage(figure, scale, gender)
        │
        ├── Validates figure if gender provided
        ├── Creates AvatarImage instance
        └── Returns IAvatarImage interface
```

### AvatarImage Construction

```
AvatarImage(figure, structure, cache)
        │
        ├── Stores AvatarFigureContainer
        ├── Stores AvatarStructure reference
        ├── Initializes AvatarImageCache
        └── Sets default action (stand)
```

### getImage() Method

```
getImage(avatarSetType, clone, scale)
        │
        ├── Check AvatarImageCache for existing image
        │
        ├── If cached: return cached BitmapData
        │
        └── If miss:
                ├── Resolve assets via figureMap
                ├── Download missing assets
                ├── Get body parts from AvatarStructure
                ├── Composite body part images
                ├── Apply color transformations
                ├── Cache result
                └── Return BitmapData
```

### Cache Hierarchy

```
AvatarImageCache (per AvatarImage)
        │
        ├── AvatarImageActionCache (per action)
        │       │
        │       ├── AvatarImageBodyPartCache (per body part)
        │       │       │
        │       │       ├── AvatarImageDirectionCache (per direction)
        │       │       │       │
        │       │       │       └── AvatarImageBodyPartContainer (BitmapData)
        │       │       │
        └── Cache invalidates on: action, direction, figure, frame change
```

## Asset Resolution

### figureMap Lookup

```
figureMap["hr:893"] = ["HR-893"]
figureMap["hd:180"] = ["HD-180"]
        │
        ▼
AvatarAssetDownloadManager queues downloads
        │
        ├── Checks if library loaded
        ├── Queues missing libraries
        └── On complete: notifies AvatarImage
```

### Asset Loading

```
AvatarAssetDownloadLibrary
        │
        ├── URL template: {base_url}{name_template}
        │       Example: "habbo-a/10/HR-893-45.swf"
        │
        └── Loads SWF, registers assets
```

### Body Part Composition

```
AvatarStructure.getBodyParts(avatarSetType, geometryType, direction)
        │
        ├── Returns array of body part IDs sorted by depth
        │       Example: ["sh", "ch", "lg", "hd", "hr"]
        │
        ▼
For each body part:
        ├── Get Asset from AssetAliasCollection
        ├── Apply color from Palette
        ├── Position according to AvatarModelGeometry
        └── Composite onto final BitmapData
```

## Room Visualization

### AvatarVisualization Update

```
AvatarVisualization.update(geometry, time, objectsDirty, forceUpdate)
        │
        ├── Gets AvatarImage from AvatarRenderManager
        │
        ├── Update direction (body and head independently)
        │
        ├── Update actions (expression, gesture, effect)
        │
        ├── Get sprites via getSpriteList()
        │
        └── Return RoomObjectSprite[] for rendering
```

### Sprite List Generation

```
getSpriteList():Array
        │
        ├── For each sprite in AvatarImage:
        │       ├── Get position (x, y)
        │       ├── Get depth (z + relativeDepth)
        │       ├── Get color (if applicable)
        │       └── Create RoomObjectSprite
        │
        └── Return array sorted by z (depth)
```

### Room Canvas Rendering

```
RoomSpriteCanvas.render()
        │
        ├── Get sprites from AvatarVisualization
        │
        ├── Sort by z (descending)
        │
        ├── Draw each sprite to canvas
        │
        └── Apply mouse handling for interaction
```

## Complete Flow Summary

```
Figure String
    │
    ▼
AvatarFigureContainer (parsed)
    │
    ▼
AvatarImage.getImage()
    │
    ├── Cache check
    │       │
    │       └── Hit → Return BitmapData
    │
    └── Miss → Asset Resolution
            │
            ├── figureMap lookup
            ├── Download assets
            ├── Composite body parts
            └── Cache result
    │
    ▼
AvatarVisualization.update()
    │
    ▼
getSpriteList() → RoomObjectSprite[]
    │
    ▼
RoomSpriteCanvas.render()
    │
    ▼
Display
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `AvatarRenderManager.as` | Main entry point |
| `AvatarImage.as` | Image generation |
| `AvatarFigureContainer.as` | Figure parsing |
| `AvatarStructure.as` | Body part data |
| `AvatarImageCache.as` | Image caching |
| `AvatarAssetDownloadManager.as` | Asset loading |
| `AvatarVisualization.as` | Room rendering |