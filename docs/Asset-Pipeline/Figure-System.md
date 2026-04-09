# Figure System

The Figure System is responsible for loading, resolving, and rendering avatar figure assets. It sits at the intersection of the [Avatar-System](../Core-Systems/Avatar-System/Figure-Data) data structures and the [Asset-Pipeline](./Asset-Libraries), managing the complex dependency graph between figure strings, part definitions, and downloadable asset libraries.

## Overview

The figure system performs three primary operations:

1. **Figure String Parsing** — Converts human-readable figure strings (e.g., `hr-893-45.hd-180-2.ch-210-66.lg-270-82`) into structured `AvatarFigureContainer` objects
2. **Asset Resolution** — Maps figure parts to downloadable SWF libraries containing the graphics
3. **Render Orchestration** — Coordinates async library downloads before instantiating `AvatarImage` for rendering

The entry point is `AvatarRenderManager`, which exposes the `IAvatarRenderManager` interface to all avatar consumers across the codebase.

## Figure String Format

Figure strings encode a user's avatar configuration as a dot-separated sequence of part declarations:

```
type-setId-color1-color2.type-setId-color1-color2...
```

**Example:** `hr-893-45.hd-180-2.ch-210-66.lg-270-82.sh-300-91.wa-2007-`

Each part consists of:
- **type** — Two-letter part type identifier (see table below)
- **setId** — Numeric ID referencing a `FigurePartSet`
- **color1+** — One or more color IDs from the associated `Palette`

| Code | Part Type | Description |
|------|-----------|-------------|
| `hd` | Head/Face | Face/head geometry |
| `hr` | Hair | Primary hair style |
| `ha` | Hair accessory | Additional hair pieces |
| `he` | Head accessory | Hats, glasses, etc. |
| `ea` | Eye accessory | Eye patches, goggles |
| `fa` | Face accessory | Moustaches, masks |
| `ch` | Chest/Torso | Shirts, jackets |
| `cc` | Chest prints | T-shirt designs |
| `ca` | Chest accessories | Scarves, ties |
| `lg` | Legs | Pants, skirts |
| `sh` | Shoes | Footwear |
| `wa` | Waist | Belts, accessories |
| `ri` | Right arm | Right arm items |
| `le` | Left arm | Left arm items |

See [Avatar Figure Data](../Core-Systems/Avatar-System/Figure-Data) for complete part type documentation.

## Asset Resolution

### The Resolution Pipeline

When `AvatarRenderManager.createAvatarImage()` is called, the following sequence executes:

```
createAvatarImage(figureString, scale, gender)
         │
         ▼
AvatarFigureContainer.parseAvatarFigure(figureString)
         │
         ▼
AvatarAssetDownloadManager._Str_1320(container, listener)
         │
         ├─► _Str_708(container) → collect required AvatarAssetDownloadLibrary[]
         │
         ├─► queue pending downloads (max 2 concurrent)
         │
         ▼
onLoaderComplete → notify listener.avatarImageReady()
         │
         ▼
new AvatarImage(structure, aliasCollection, figureContainer, scale, effects)
```

### FigureMap Configuration

The `figuremap.xml` (loaded by `AvatarAssetDownloadManager`) maps part types+IDs to downloadable libraries:

```xml
<figures>
    <lib id="h0001" revision="63">
        <part type="hr" id="893"/>
        <part type="hd" id="180"/>
    </lib>
    <lib id="sh0001" revision="63">
        <part type="sh" id="300"/>
    </lib>
</figures>
```

Resolution at `AvatarAssetDownloadManager._Str_708()` (lines 331–390):
1. Iterate all part types in the `AvatarFigureContainer`
2. For each part, lookup `SetType` → `FigurePartSet` → `FigurePart[]`
3. For each `FigurePart`, construct key `"type:id"` (e.g., `"hr:893"`)
4. Lookup in `_figureMap` to find associated `AvatarAssetDownloadLibrary` instances

### Download URL Template

The download URL is constructed from configuration properties:
- `flash.dynamic.avatar.download.url` — Base CDN URL
- `flash.dynamic.avatar.download.name.template` — URL template (e.g., `"%libname%.swf?r=%revision%"`)

## Figure Part Loading

### Loading Sequence

Part loading is triggered when an avatar enters the view (room, inventory preview, etc.). The process is fully asynchronous:

1. **Immediate Return** — If all required libraries are cached locally, `AvatarImage` is returned immediately
2. **Placeholder** — If libraries are pending, `PlaceholderAvatarImage` is returned to allow the UI to render immediately
3. **Async Resolution** — `AvatarAssetDownloadManager._Str_1320()` queues missing libraries
4. **Callback** — When all downloads complete, `listener.avatarImageReady()` fires and the consumer can request a fresh `AvatarImage`

The placeholder mechanism (see `AvatarRenderManager.as:273–278`) ensures the UI never blocks:

```actionscript
if (this._avatarAssetDownloadManager.isReady(figureContainer))
{
    return new AvatarImage(this._structure, this._aliasCollection, 
        figureContainer, _arg_2, this._effectAssetDownloadManager);
}
this._avatarAssetDownloadManager._Str_1320(figureContainer, _arg_4);
return new PlaceholderAvatarImage(this._structure, this._aliasCollection, 
    this._avatarPlaceholderFigure, _arg_2, this._effectAssetDownloadManager);
```

### Figure Validation

Before rendering, `AvatarRenderManager.validateAvatarFigure()` (lines 380–434) ensures mandatory parts exist:

```actionscript
var _local_5:Array = this._structure.getMandatorySetTypeIds(_arg_2, _local_4);
for each (_local_7 in _local_5)
{
    if (!k._Str_744(_local_7))  // part exists?
    {
        _local_8 = this._structure._Str_2264(_local_7, _arg_2);
        if (_local_8)
        {
            k._Str_830(_local_7, _local_8.id, [0]);  // add default
        }
    }
}
```

This guarantees every avatar has at least a default body (`hd`), hair (`hr`), torso (`ch`), and legs (`lg`) even if the figure string is malformed.

## Caching

### Asset Library Caching

Downloaded SWF libraries are cached at the `AssetLibraryCollection` level. When `AvatarAssetDownloadLibrary.startDownloading()` executes:

1. Check if `"libraryName.swf"` already exists in the asset library collection
2. If found, mark as ready immediately without network request
3. If not found, load via `LibraryLoader` and register as new library

This means subsequent avatar renders with the same figure are instant — no re-download.

### Figure Validation Caching

`AvatarAssetDownloadManager._Str_708()` caches the mapping from `AvatarFigureContainer` to required libraries. The result is memoized per figure string to avoid repeated lookups.

### Cache Invalidation

Cache is invalidated when:
- **Figure map updates** — New figuremap.xml loads via `AvatarAssetDownloadManager._Str_1556()`
- **Asset library reloads** — `AvatarRenderManager._Str_1154()` calls `AssetAliasCollection.reset()`
- **Configuration changes** — New `external.figurepartlist.txt` triggers `AvatarStructureDownload.AVATAR_STRUCTURE_DONE`

## Relevant Classes

| Class | File | Role |
|-------|------|------|
| `AvatarRenderManager` | `src/com/sulake/habbo/avatar/AvatarRenderManager.as` | Main entry point — creates avatars, manages structure |
| `IAvatarRenderManager` | `src/com/sulake/habbo/avatar/IAvatarRenderManager.as` | Public interface for avatar consumers |
| `AvatarFigureContainer` | `src/com/sulake/habbo/avatar/AvatarFigureContainer.as` | Runtime figure string parser |
| `IAvatarFigureContainer` | `src/com/sulake/habbo/avatar/IAvatarFigureContainer.as` | Figure container interface |
| `AvatarAssetDownloadManager` | `src/com/sulake/habbo/avatar/AvatarAssetDownloadManager.as` | Async library loading, figuremap resolution |
| `AvatarAssetDownloadLibrary` | `src/com/sulake/habbo/avatar/AvatarAssetDownloadLibrary.as` | Individual SWF library download |
| `FigureData` | `src/com/sulake/habbo/avatar/figuredata/FigureData.as` | Avatar editor figure management |
| `FigureDataView` | `src/com/sulake/habbo/avatar/figuredata/FigureDataView.as` | Editor preview rendering |
| `AvatarStructure` | `src/com/sulake/habbo/avatar/structure/AvatarStructure.as` | Geometry, animation, figure data container |
| `SetType` | `src/com/sulake/habbo/avatar/structure/figure/SetType.as` | Part type (hd, ch, lg, etc.) definition |
| `FigurePartSet` | `src/com/sulake/habbo/avatar/structure/figure/FigurePartSet.as` | Part set (specific clothing item) |
| `FigurePart` | `src/com/sulake/habbo/avatar/structure/figure/FigurePart.as` | Individual part geometry reference |

## Connection to Core-Systems

The Figure System binds to the broader Avatar-System through these documents:

- **[Avatar Figure Data](../Core-Systems/Avatar-System/Figure-Data)** — Data structures (`FigureSetData`, `SetType`, `FigurePartSet`, `PartColor`) parsed from `HabboAvatarFigure.xml`
- **[Avatar Rendering](../Core-Systems/Avatar-System/Rendering)** — How `AvatarImage` composes the final bitmap from resolved parts
- **[Avatar Caching](../Core-Systems/Avatar-System/Caching)** — Higher-level avatar cache (canvas, direction) built atop the figure system
- **[Avatar Actions](../Core-Systems/Avatar-System/Actions)** — Animation state machine that drives figure pose changes

The figure string format originates from server-sent `UserFigureData` packets (see [Packet Reference](../Protocol/Packet-Reference)), flowing into `HabboInventory` and `HabboAvatarEditor` for modification.

## Key Initialization Flow

`AvatarRenderManager.initComponent()` (`AvatarRenderManager.as:67–83`) sets up the system:

```actionscript
this._structure = new AvatarStructure(this);
this._structure.initGeometry(assets.getAssetByName("HabboAvatarGeometry"));
this._structure.initPartSets(assets.getAssetByName("HabboAvatarPartSets"));
this._structure.initActions(assets, k);
this._structure.initAnimation(assets.getAssetByName("HabboAvatarAnimation"));
this._structure.initFigureData(assets.getAssetByName("HabboAvatarFigure"));
this._aliasCollection = new AssetAliasCollection(this, context.assets);
this._aliasCollection.init();
```

Once configuration completes (`onConfigurationComplete`, lines 138–174), the `AvatarAssetDownloadManager` and `EffectAssetDownloadManager` are instantiated to handle dynamic library loading from the CDN.

## See Also

- [Avatar Rendering Flow](../Data-Flows/Avatar-Rendering-Flow) — End-to-end render pipeline
- [Asset Libraries](./Asset-Libraries) — SWF library infrastructure
- [Packet Reference — Avatar](../Protocol/Packet-Reference) — Figure-related packet IDs (UserFigureData, etc.)
- [HabboAvatarFigure.xml Schema](https://github.com/sulake/habbo-api/wiki/HabboAvatarFigure) — External figure data format