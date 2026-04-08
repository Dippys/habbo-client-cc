# Avatar Figure Data

The Avatar Figure Data system manages how avatar appearance is defined, stored, and processed. This document details the figure string format, parsing, and the data structures that define available avatar parts.

## Figure Data Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FIGURE DATA HIERARCHY                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      FigureSetData                                   │   │
│  │  (Root container - parsed from HabboAvatarFigure.xml)               │   │
│  │                                                                       │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │                    SetType (per part type)                     │  │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │   │
│  │  │  │               FigurePartSet (per set ID)               │  │  │   │
│  │  │  │  ┌─────────────────────────────────────────────────────┐ │  │  │   │
│  │  │  │  │                 FigurePart (individual part)       │ │  │  │   │
│  │  │  │  └─────────────────────────────────────────────────────┘ │  │  │   │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  │                                                                       │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │                    Palette (colors)                            │  │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │   │
│  │  │  │                 PartColor (individual color)             │  │  │   │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    AvatarFigureContainer                             │   │
│  │  (Runtime figure string parser)                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Figure String Format

### String Structure

```
type1-setId-color1-color2.type2-setId-color1-color2...

Example: hr-893-45.hd-180-2.ch-210-66.lg-270-82.sh-300-91.wa-2007-.ri-1-
```

### Part Type Codes

| Code | Part Type | Example |
|------|-----------|---------|
| `hd` | Head/Face | hd-180-2 |
| `hr` | Hair | hr-893-45 |
| `ha` | Hair accessory | ha-100-1 |
| `he` | Head accessory | he-50-1 |
| `ea` | Eye accessory | ea-20-1 |
| `fa` | Face accessory | fa-10-1 |
| `ch` | Chest/Torso | ch-210-66 |
| `cc` | Chest accessory | cc-15-1 |
| `ca` | Chest accessory | ca-5-1 |
| `lg` | Legs | lg-270-82 |
| `sh` | Shoes | sh-300-91 |
| `wa` | Waist | wa-2007 |
| `ri` | Right arm | ri-1 |
| `le` | Left arm | le-1 |

### Color Codes

Colors are referenced by ID, resolved through the palette system:
- Primary color: first color ID (e.g., 45 in "hd-180-45")
- Secondary color: second color ID (e.g., 2 in "hd-180-45-2")

## FigureData Class

**File:** `src/com/sulake/habbo/avatar/figuredata/FigureData.as`

Manages avatar appearance in the avatar editor:

```actionscript
public class FigureData
{
    private var _data:Dictionary;        // type -> setId
    private var _colors:Dictionary;     // type -> [colorIds]
    private var _gender:String;          // "M", "F", or "U"
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `loadAvatarData(k, _arg_2)` | Parse figure string into internal format |
| `getPartSetId(k)` | Get set ID for part type |
| `getColourIds(k)` | Get color IDs for part type |
| `getFigureString()` | Serialize back to figure string |
| `savePartSetColourId(k, _arg_2, _arg_3)` | Update part configuration |

### Gender Constants

```actionscript
public static const M:String = "M";
public static const F:String = "F";
public static const U:String = "U";  // Unisex
```

## FigureSetData Class

**File:** `src/com/sulake/habbo/avatar/structure/FigureSetData.as`

Parsed from `HabboAvatarFigure.xml`:

```actionscript
public class FigureSetData extends Component
{
    private var _paletteMap:Map;
    private var _setTypes:Map;
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `init(data)` | Initialize from XML data |
| `_Str_1020(type, setId)` | Get FigurePartSet by type and set ID |
| `getSetType(type)` | Get SetType for category |
| `_Str_727(k)` | Get palette by ID |

## SetType Class

**File:** `src/com/sulake/habbo/avatar/structure/figure/SetType.as`

Represents a category of avatar parts:

```actionscript
public class SetType implements ISetType
{
    private var _type:String;              // e.g., "hd", "ch"
    private var _Str_734:int;              // Mandatory for gender (1=M, 2=F)
    private var _partSets:Map;            // setId -> FigurePartSet
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `type` | String | Part type identifier |
| `_Str_734` | int | Gender requirement (1=M, 2=F, 3=both) |
| `_partSets` | Map | Available part sets |

## FigurePartSet Class

**File:** `src/com/sulake/habbo/avatar/structure/figure/FigurePartSet.as`

A specific configuration within a SetType:

```actionscript
public class FigurePartSet implements IFigurePartSet
{
    private var _id:int;
    private var _clubLevel:int;
    private var _gender:int;
    private var _parts:Array;
    private var _paletteMap:Map;
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `_id` | int | Set ID |
| `_clubLevel` | int | Required club level (0=free) |
| `_gender` | int | Gender (1=M, 2=F, 3=both) |
| `_parts` | Array | FigurePart[] |
| `_paletteMap` | Map | Color palette mapping |

## FigurePart Class

**File:** `src/com/sulake/habbo/avatar/structure/figure/FigurePart.as`

An individual avatar part:

```actionscript
public class FigurePart
{
    private var _id:int;
    private var _type:String;
    private var _breed:int;
    private var _colorLayerIndex:int;
    private var _index:int;
    private var _paletteMapId:int;
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `_id` | int | Part ID |
| `_type` | String | Part type |
| `_breed` | int | Variant ID |
| `_colorLayerIndex` | int | Which color layer |
| `_index` | int | Z-order/index |
| `_paletteMapId` | int | Color mapping ID |

## Palette System

### Palette Class

**File:** `src/com/sulake/habbo/avatar/structure/figure/Palette.as`

```actionscript
public class Palette implements IPalette
{
    private var _id:int;
    private var _colors:Map;  // colorId -> PartColor
}
```

### PartColor Class

**File:** `src/com/sulake/habbo/avatar/structure/figure/PartColor.as`

```actionscript
public class PartColor
{
    private var _id:int;
    private var _rgb:uint;
    private var _clubLevel:int;
    private var _selectable:Boolean;
}
```

### RGB Color Storage

```actionscript
// Colors stored as RGB integers
var color:PartColor = palette.getColor(45);
var red:int = (color.rgb >> 16) & 0xFF;
var green:int = (color.rgb >> 8) & 0xFF;
var blue:int = color.rgb & 0xFF;
```

## AvatarFigureContainer

**File:** `src/com/sulake/habbo/avatar/AvatarFigureContainer.as`

Runtime parser for figure strings:

```actionscript
public class AvatarFigureContainer implements IAvatarFigureContainer
{
    private var _parts:Map;  // type -> {type, setId, colorIds}
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `getPartSetId(type)` | Get set ID for part type |
| `getColorIDs(type)` | Get color array for type |
| `setPart(type, setId, colors)` | Set part configuration |
| `getFigureString()` | Generate figure string |

### Parsing Example

```actionscript
// Input: "hr-893-45.hd-180-2.ch-210-66"
// Internal structure:
// {
//   "hr": {type: "hr", setId: 893, colorIds: [45]},
//   "hd": {type: "hd", setId: 180, colorIds: [2]},
//   "ch": {type: "ch", setId: 210, colorIds: [66]}
// }
```

## FigureDataView

**File:** `src/com/sulake/habbo/avatar/figuredata/FigureDataView.as`

Renders avatar preview in editor:

```actionscript
public function update(k:String, _arg_2:int = 0, _arg_3:int = 4):void
{
    // k: Figure string
    // _arg_2: Effect type
    // _arg_3: Direction
}
```

### Rendering Pipeline

1. If Room Engine available: Use `RoomPreviewer.updateAvatarDirection()`
2. Otherwise: Use `AvatarRenderManager.createAvatarImage()`

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/avatar/figuredata/FigureData.as` | Editor figure data |
| `src/com/sulake/habbo/avatar/figuredata/FigureDataView.as` | Preview rendering |
| `src/com/sulake/habbo/avatar/structure/FigureSetData.as` | XML parsed data |
| `src/com/sulake/habbo/avatar/structure/figure/SetType.as` | Part type category |
| `src/com/sulake/habbo/avatar/structure/figure/FigurePartSet.as` | Part set |
| `src/com/sulake/habbo/avatar/structure/figure/FigurePart.as` | Individual part |
| `src/com/sulake/habbo/avatar/structure/figure/Palette.as` | Color palette |
| `src/com/sulake/habbo/avatar/AvatarFigureContainer.as` | Figure string parser |

## Next Steps

- [Avatar Actions](Core-Systems/Avatar-System/Actions) - Action definitions and animations
- [Avatar Caching](Core-Systems/Avatar-System/Caching) - Cache implementation