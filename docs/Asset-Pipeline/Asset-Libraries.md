# Asset Libraries

The asset pipeline is the Habbo client's resource management system for loading, caching, and distributing graphical assets, sounds, XML configurations, and other media across the entire UI. It is built around a layered architecture: `AssetLibrary` instances hold collections of named assets, while `AssetLibraryCollection` aggregates multiple libraries into a unified namespace. The system is designed to handle both embedded SWF resources (compiled at build time) and external assets loaded at runtime from the hotel's CDN.

## Entry Points

| Class / Interface                 | File                                                              | Role                                                                                     |
|-----------------------------------|-------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| `HabboAssetManager`               | `src/com/sulake/habbo/assets/HabboAssetManager.as`               | Main entry point — implements `IAssetManager`, holds the global `AssetLibraryCollection` |
| `IAssetManager`                   | `src/com/sulake/core/assets/IAssetManager.as`                    | Core interface defining asset discovery, loading, and type declaration methods        |
| `AssetLibraryCollection`         | `src/com/sulake/core/assets/AssetLibraryCollection.as`           | Aggregates multiple `AssetLibrary` instances under a single `IAssetLibrary` facade      |
| `AssetLibrary`                   | `src/com/sulake/core/assets/AssetLibrary.as`                     | Single library container — manages loading, manifest parsing, and asset instantiation   |

`HabboAssetManager` is instantiated early in the boot sequence (see [Application-Lifecycle](../Core-Systems/Application-Lifecycle)) and exposes a singleton-like interface for the rest of the client:

```actionscript
public class HabboAssetManager implements IAssetManager
{
    private var _assets:AssetLibraryCollection;
    private var _manifests:XML;
    
    public function get assets():IAssetLibrary
    {
        return this._assets;
    }
    
    public function getAssetByName(name:String):IAsset
    {
        return this._assets.getAssetByName(name);
    }
    // ... additional loader orchestration methods
}
```

The `_assets` field is an `AssetLibraryCollection` that serves as the global asset registry. All subsequent asset lookups route through this collection.

## Asset Library Structure

Each `AssetLibrary` corresponds to a single SWF library (either embedded or loaded remotely). Libraries are defined by an XML **manifest** that enumerates assets and their MIME types:

```xml
<manifest>
  <library>
    <asset name="icon_furni_100" mimeType="image/png" />
    <asset name="badge_001" mimeType="image/png">
      <param key="offset" value="0,0"/>
    </asset>
    <asset name="sfx_click" mimeType="sound/mp3" />
    <asset name="layout_main" mimeType="text/xml" />
  </library>
  <aliases>
    <asset name="icon_furni_100_1x" mimeType="image/png" ref="icon_furni_100"/>
  </aliases>
</manifest>
```

The manifest declares assets under `<library>/<assets>` and optional aliases under `<library>/<aliases>`. The `mimeType` attribute maps to an `AssetTypeDeclaration`, which associates:

- The **MIME type** (e.g., `"image/png"`)
- The **asset class** to instantiate (e.g., `BitmapDataAsset`)
- The **loader class** for remote loading (e.g., `BitmapFileLoader`)
- Supported **file extensions** (e.g., `"png"`, `"jpg"`)

### Built-in Type Declarations

`AssetLibrary` registers a static set of shared type declarations on construction (`AssetLibrary.as:63-78`):

| MIME Type                | Asset Class        | Loader Class        | File Extensions               |
|--------------------------|--------------------|---------------------|-------------------------------|
| `image/png`              | `BitmapDataAsset` | `BitmapFileLoader` | `png`                         |
| `image/jpeg`             | `BitmapDataAsset` | `BitmapFileLoader` | `jpg`, `jpeg`                |
| `image/gif`              | `BitmapDataAsset` | `BitmapFileLoader` | `gif`                         |
| `sound/mp3`              | `SoundAsset`      | `SoundFileLoader`  | `mp3`                         |
| `text/xml`               | `XmlAsset`        | `TextFileLoader`   | `xml`                         |
| `text/plain`             | `TextAsset`       | `TextFileLoader`   | `txt`                         |
| `application/zip`       | `UnknownAsset`    | `ZipFileLoader`    | `zip`                         |
| `application/x-shockwave-flash` | `DisplayAsset` | `BitmapFileLoader` | `swf`                         |

Custom type declarations can be registered via `IAssetLibrary.registerAssetTypeDeclaration()`, either globally (shared across all libraries) or locally (specific to a single library).

## Loading Strategy

### Two Loading Paths

`AssetLibrary` supports two distinct loading mechanisms:

1. **`loadFromFile(libraryLoader, prepareAssets)`** — loads an external SWF/ZIP archive via `LibraryLoader`. The loader fetches the binary, parses its embedded manifest, and registers asset classes. When `prepareAssets` is `true` (default), assets are immediately instantiated from the compiled SWF classes.

2. **`loadFromResource(xml, type)`** — loads assets from an already-loaded SWF `Class` (typically embedded at compile time). The manifest XML and the SWF's `ApplicationDomain` are provided directly; no network request is made.

The loading flow is asynchronous and event-driven:

```
LibraryLoader.load()
    │
    ▼
LibraryLoaderEvent.LIBRARY_LOADER_EVENT_COMPLETE
    │
    ▼
AssetLibrary.libraryLoadedHandler()
    │
    ├──► fetchLibraryContents()  ← parses manifest, instantiates assets
    │
    ▼
dispatchEvent(AssetLibrary.ASSET_LIBRARY_LOADED)
dispatchEvent(AssetLibrary.ASSET_LIBRARY_READY)
```

### Queue Management in AssetLibraryCollection

`AssetLibraryCollection` manages concurrent library loads via an internal queue:

```actionscript
// AssetLibraryCollection.as:82-94
public function loadFromFile(libraryLoader:LibraryLoader, prepareAssets:Boolean=false):void
{
    var assetLibrary:IAssetLibrary = new AssetLibrary(("lib-" + this._counter++));
    this._fileLoadQueue.push(assetLibrary);
    assetLibrary.loadFromFile(libraryLoader, prepareAssets);
    libraryLoader.addEventListener(LibraryLoaderEvent.LIBRARY_LOADER_EVENT_COMPLETE, this.loadEventHandler);
    // ...
}
```

The `_fileLoadQueue` array tracks pending loads. The collection is considered **ready** only when the queue is empty (`isReady` getter returns `this._fileLoadQueue.length == 0`). Progress events are bubbled up to listeners, enabling the UI to display loading bars.

### On-Demand Asset Loading

Individual assets can be loaded on-demand via `loadAssetFromFile()`:

```actionscript
// AssetLibrary.as:337-385
public function loadAssetFromFile(name:String, urlRequest:URLRequest, type:String=null, ...):AssetLoaderStruct
{
    var typeDeclaration:AssetTypeDeclaration = this.solveAssetTypeDeclarationFromUrl(urlRequest.url);
    var loader:IAssetLoader = new (typeDeclaration.loaderClass)(...);
    var loaderStruct:AssetLoaderStruct = new AssetLoaderStruct(name, loader);
    this._assetLoaderStructs[urlRequest.url] = loaderStruct;
    return loaderStruct;
}
```

This method creates an `AssetLoaderStruct` that wraps the loader and dispatches events on completion. The loaded asset is stored in `_loadedAssets` and becomes available via `getAssetByName()`.

## Cache Management

The asset pipeline implements multiple caching layers:

### 1. In-Memory Asset Cache

Each `AssetLibrary` maintains a `_loadedAssets` dictionary mapping asset names to `IAsset` instances:

```actionscript
// AssetLibrary.as:51
private var _loadedAssets:Dictionary;
```

Lookup is O(1). Assets are disposed when the library is unloaded or explicitly removed.

### 2. Class Cache

Compiled SWF classes are cached separately in `_loadedClasses`:

```actionscript
// AssetLibrary.as:315-335
public function getClass(name:String):Class
{
    var result:Class = this._loadedClasses[name];
    if (result != null) return result;
    if (this._loader != null && this._loader.hasDefinition(name))
    {
        result = this._loader.getDefinition(name) as Class;
        if (result != null)
        {
            this._loadedClasses[name] = result;
            return result;
        }
    }
    return null;
}
```

This avoids repeated `ApplicationDomain.getDefinition()` calls.

### 3. Bin Library (AssetLibraryCollection)

`AssetLibraryCollection` maintains a special "bin" library (`_binLibrary`) that holds assets loaded via `loadFromResource()` — i.e., assets embedded at compile time. This library is always first in the lookup chain:

```actionscript
// AssetLibraryCollection.as:72-80
private function get binLibrary():IAssetLibrary
{
    if (!this._binLibrary)
    {
        this._binLibrary = new AssetLibrary("bin");
        this._assetLibraries.splice(0, 0, this._binLibrary);
    }
    return this._binLibrary;
}
```

Because the bin library is inserted at index 0, its assets take precedence over identically-named assets in later-loaded libraries.

### 4. Lazy Asset Processing

Assets implementing `ILazyAsset` (most notably `BitmapDataAsset`) defer content preparation until first access:

```actionscript
// BitmapDataAsset.as:73-80
public function get content():Object
{
    if (!this._bitmap)
    {
        this.prepareLazyContent();
    }
    return this._bitmap;
}
```

This allows the client to load large manifests without immediately decompressing all bitmap data. A static `LazyAssetProcessor` can optionally queue lazy assets for batch processing, though this is disabled by default (`USE_LAZY_ASSET_PROCESSOR = false` in `AssetLibrary.as:38`).

### 5. Bitmap Memory Tracking

`BitmapDataAsset` tracks allocated memory to assist with garbage collection:

```actionscript
// BitmapDataAsset.as:13-14
protected static var _instances:uint = 0;
protected static var _allocatedByteCount:uint = 0;

// BitmapDataAsset.as:106-154 (dispose)
allocatedByteCount = (allocatedByteCount - ((_bitmap.width * _bitmap.height) * 4));
```

This data is exposed via static getters and can be used to implement custom memory management policies.

## Relevant Classes

| File                                            | Purpose                                                               |
|-------------------------------------------------|-----------------------------------------------------------------------|
| `src/com/sulake/core/assets/IAsset.as`          | Base interface for all assets                                        |
| `src/com/sulake/core/assets/ILazyAsset.as`      | Interface for lazy-loading assets                                    |
| `src/com/sulake/core/assets/IAssetLibrary.as`  | Interface for single library management                              |
| `src/com/sulake/core/assets/AssetLibrary.as`   | Single library implementation                                        |
| `src/com/sulake/core/assets/AssetLibraryCollection.as` | Multi-library aggregator                                  |
| `src/com/sulake/core/assets/AssetTypeDeclaration.as` | Type mapping (MIME → class/loader)                           |
| `src/com/sulake/core/assets/AssetLoaderStruct.as` | Wrapper around asset loaders                                      |
| `src/com/sulake/core/assets/BitmapDataAsset.as` | Image asset implementation                                         |
| `src/com/sulake/core/assets/SoundAsset.as`     | Audio asset implementation                                           |
| `src/com/sulake/core/assets/XmlAsset.as`       | XML configuration asset                                             |
| `src/com/sulake/core/assets/loaders/IAssetLoader.as` | Loader interface                                                  |
| `src/com/sulake/core/assets/loaders/BitmapFileLoader.as` | PNG/JPG/GIF loader                                          |
| `src/com/sulake/core/assets/loaders/SoundFileLoader.as` | MP3 loader                                                     |
| `src/com/sulake/core/assets/loaders/TextFileLoader.as` | Text/XML loader                                                  |
| `src/com/sulake/habbo/avatar/AvatarAssetDownloadManager.as` | Avatar figure asset download orchestration         |
| `src/com/sulake/habbo/avatar/EffectAssetDownloadManager.as` | Clothing effect asset download orchestration       |

## Cross-References

- **[Figure System](../Avatar/Figure-System)** — The avatar rendering system relies on `AvatarAssetDownloadManager` to fetch figure assets (clothing, hair, accessories) from the CDN. Assets are cached in the global `AssetLibraryCollection` and retrieved by hash identifiers.

- **[Furniture System Architecture](../Core-Systems/Furniture-System/Architecture)** — Furniture visualizers load icon assets (PNG) and display assets (SWF) through the asset pipeline. The furniture manifest maps type IDs to asset names, which are resolved via `IAssetLibrary.getAssetByName()`.

- **[UI-Framework/Skinning-Theming](../UI-Framework/Skinning-Theming)** — UI themes are distributed as XML manifests plus embedded SWF libraries. The asset pipeline loads these as `AssetLibrary` instances; the window manager retrieves skin assets by name.

- **[Room Object Visualization](../Room/Object-Visualization)** — Room object visualizers (`GraphicAssetCollection`) maintain their own asset libraries for tile textures, wall layers, and animation frames. These libraries are loaded on-demand when entering a room.

- **[Sound System](../Core-Systems/Sound-System)** — Sound effects and background music are loaded as `SoundAsset` instances. The sound manager subscribes to `AssetLibrary.ASSET_LIBRARY_LOADED` to know when a library's audio assets are ready for playback.

## Asset Flow Diagram

```
                        HabboAssetManager
  (global IAssetManager, holds AssetLibraryCollection)
                              │
                              ▼
                  AssetLibraryCollection
    ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
    │ Bin Library  │  │  Lib-1 (SWF) │  │  Lib-N (external)    │
    │ (embedded)   │  │ (manifest)   │  │  (loaded at runtime) │
    └──────────────┘  └──────────────┘  └──────────────────────┘
           │                  │                     │
           └──────────────────┼─────────────────────┘
                              ▼
                    _loadedAssets
          { "icon_furni_100": BitmapDataAsset,
            "sfx_click": SoundAsset, "layout_main": XmlAsset }
```

## See Also

- [Application-Lifecycle](../Core-Systems/Application-Lifecycle) — boot order and component initialization
- [Avatar/Figure-System](../Avatar/Figure-System) — figure asset download and caching
- [Furniture-System/Architecture](../Core-Systems/Furniture-System/Architecture) — furni asset resolution
- [UI-Framework/Skinning-Theming](../UI-Framework/Skinning-Theming) — theme loading via asset libraries
