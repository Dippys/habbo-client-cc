# Window Manager

The Window Manager is the foundation of the Habbo client's UI system, providing a multi-layer architecture for managing all windows, dialogs, and UI elements.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      WINDOW MANAGER ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                  HabboWindowManagerComponent                         │   │
│  │                                                                       │   │
│  │  ┌────────────────┐  ┌────────────────┐  ┌─────────────────────┐  │   │
│  │  │ WindowContext │  │ ThemeManager  │  │   ResourceManager   │  │   │
│  │  │  Array[4]     │  │               │  │                      │  │   │
│  │  │               │  │ - Styles     │  │ - Assets            │  │   │
│  │  │ - layer_0    │  │ - Themes      │  │ - Localization      │  │   │
│  │  │ - layer_1    │  │               │  │                      │  │   │
│  │  │ - layer_2    │  │               │  │                      │  │   │
│  │  │ - layer_3    │  │               │  │                      │  │   │
│  │  └────────────────┘  └────────────────┘  └─────────────────────┘  │   │
│  │                                                                       │   │
│  │  Implements: IHabboWindowManager, IWidgetFactory, IUpdateReceiver    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                          │
│           ┌────────────────────────┼────────────────────────┐               │
│           ▼                        ▼                        ▼                │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐       │
│  │  WindowContext   │    │  WindowContext   │    │  WindowContext  │       │
│  │     (layer_0)    │    │     (layer_1)    │    │     (layer_3)  │       │
│  │                  │    │                  │    │                  │       │
│  │ DesktopController│    │ DesktopController│    │ DesktopController│       │
│  │   - windows      │    │   - windows      │    │   - windows      │       │
│  │   - events       │    │   - events       │    │   - events       │       │
│  └──────────────────┘    └──────────────────┘    └──────────────────┘       │
│                                                                              │
│  Layer 0: Background   Layer 1: Main UI   Layer 2: Overlays   Layer 3: Modals│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## HabboWindowManagerComponent

**File:** `src/com/sulake/habbo/window/HabboWindowManagerComponent.as`

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `_windowContextArray` | Array | 4 WindowContext instances |
| `_windowContext` | IWindowContext | Active context (layer_1) |
| `_windowRenderer` | IWindowRenderer | Renders windows |
| `_skinContainer` | SkinContainer | Skin assets |
| `_themeManager` | ThemeManager | Theme handling |
| `_hintManager` | HintManager | Tooltip hints |

### Constants

```actionscript
private static const _Str_8995:uint = 4;   // 4 layers
private static const _Str_17369:uint = 1; // Default layer
```

### Initialization

```actionscript
override protected function initComponent():void
{
    // Create skin container, theme manager, resource manager
    // Create window renderer
    // Create 4 WindowContext instances (layer_0 through layer_3)
    // Set layer_1 as default context
    // Register for updates and input tracking
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `createWindow()` | Create new window |
| `removeWindow()` | Remove window by name |
| `getWindowByName()` | Get window from specific layer |
| `getActiveWindow()` | Get topmost window |
| `alert()` / `confirm()` | Show dialogs |
| `simpleAlert()` | Show simple alert |
| `registerHintWindow()` | Register tooltip |

### Window Creation

```actionscript
public function createWindow(
    name:String,
    className:String="",
    typeID:uint=0,
    styleID:uint=0,
    params:uint=0,
    bounds:Rectangle=null,
    procedure:Function=null,
    windowID:uint=0,
    layer:uint=1,
    dynamicStyle:String=""
):IWindow
```

## IHabboWindowManager Interface

**File:** `src/com/sulake/habbo/window/IHabboWindowManager.as`

### Window Management

```actionscript
// Create/remove/get windows
createWindow(name, className, typeID, styleID, params, bounds, procedure, windowID, layer, dynamicStyle)
removeWindow(name:String, layer:uint=1):void
getWindowByName(name:String, layer:uint=1):IWindow
getActiveWindow(layer:uint=1):IWindow
getWindowContext(layer:uint):IWindowContext
```

### Dialog Methods

```actionscript
// Alert dialogs
alert(title:String, message:String, flags:uint, callback:Function):IAlertDialog
alertWithLink(title:String, message:String, linkTitle:String, linkURL:String, flags:uint, callback:Function)

// Confirmation
confirm(title:String, message:String, flags:uint, callback:Function):IConfirmDialog

// Simple alert with many options
simpleAlert(title:String, message:String, type:String, imageURL:String=null, ...):void
```

### Hint System

```actionscript
registerHintWindow(name:String, window:IWindow, layer:int=1):void
showHint(name:String, bounds:Rectangle=null):void
hideHint():void
hideMatchingHint(pattern:String):void
```

## WindowContext

**File:** `src/com/sulake/core/window/WindowContext.as`

Each `WindowContext` represents a single layer with its own:
- Desktop window (root)
- Window parser
- Window factory
- Event processor
- Window services

### Error Codes

```actionscript
public static const ERROR_UNKNOWN:int = 0;
public static const ERROR_INVALID_WINDOW:int = 1;
public static const ERROR_WINDOW_NOT_FOUND:int = 2;
public static const ERROR_WINDOW_ALREADY_EXISTS:int = 3;
public static const ERROR_UNKNOWN_WINDOW_TYPE:int = 4;
public static const ERROR_DURING_EVENT_HANDLING:int = 5;
```

## Multi-Layer System

### Layer Architecture

```
Stage
├── Layer 0 (layer_0) - Background
│   └── DesktopController
│       └── Background windows
├── Layer 1 (layer_1) - Main UI (DEFAULT)
│   └── DesktopController
│       └── Standard windows, dialogs
├── Layer 2 (layer_2) - Overlays
│   └── DesktopController
│       └── Tooltips, hints
└── Layer 3 (layer_3) - Modals
    └── DesktopController
        └── Alert dialogs, modal windows
```

### Update Order

**Input Processing** (layer 3 → 0, highest first):
```actionscript
for (var i:uint = 3; i >= 0; i--) {
    _windowContextArray[i].update(frameTime);
}
```

**Rendering** (layer 0 → 3, lowest first):
```actionscript
for (var i:uint = 0; i < 4; i++) {
    _windowContextArray[i].render(frameTime);
}
```

### Layer Usage

| Layer | Name | Usage |
|-------|------|-------|
| 0 | layer_0 | Background elements, world-related UI |
| 1 | layer_1 | Default UI (main windows, dialogs) - **Most common** |
| 2 | layer_2 | Overlay elements, tooltips |
| 3 | layer_3 | Highest priority (modal dialogs, alerts) |

### Creating Windows on Specific Layers

```actionscript
// Default (layer_1)
createWindow("my_window", "frame")

// Specific layer
createWindow("my_window", "frame", 0, 0, 0, null, null, 0, 3)  // layer_3
```

## WindowController

**File:** `src/com/sulake/core/window/WindowController.as`

Base class for all windows:

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `_events` | WindowEventDispatcher | Event dispatcher |
| `_graphics` | IGraphicContext | Graphics context |
| `_procedure` | Function | Event handler |
| `_parent` | WindowController | Parent window |
| `_children` | Vector.<IWindow> | Child windows |
| `_uid` | uint | Unique identifier |

### Lifecycle

1. **Construction**: Initialize properties, create graphics context
2. **Build from XML**: Parse XML to create child hierarchy
3. **Parent Assignment**: Add to parent's children list
4. **Disposal**: Remove from parent, dispose children, release graphics

### Static Tags

```actionscript
public static const TAG_EXCLUDE:String = "_EXCLUDE";     // Exclude from clone
public static const TAG_INTERNAL:String = "_INTERNAL";   // Internal window
public static const _COLORIZE:String = "_COLORIZE";      // Colorization
public static const _IGNORE_INHERITED_STYLE:String = "_IGNORE_INHERITED_STYLE";
```

## Desktop Window Hierarchy

### DesktopController

**File:** `src/com/sulake/core/window/components/DesktopController.as`

Root window for each layer:

```actionscript
public function getActiveWindow():IWindow
public function setActiveWindow(window:IWindow):IWindow
public function get mouseX():int
public function get mouseY():int
```

### Hierarchy Structure

```
DesktopController (layer_X)
├── FrameWindow (title bar + content)
│   ├── HeaderController (title bar)
│   ├── ContainerController (content)
│   └── ...
├── ButtonControl
├── StaticWindow (container)
└── ... (more windows)
```

## Update Loop

```actionscript
public function update(k:uint):void
{
    // Input processing (layer 3 → 0)
    for (var i:uint = 3; i >= 0; i--) {
        _windowContextArray[i].update(k);
    }
    
    // Rendering (layer 0 → 3)
    for (var i:uint = 0; i < 4; i++) {
        _windowContextArray[i].render(k);
    }
}
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/habbo/window/HabboWindowManagerComponent.as` | Main entry point |
| `src/com/sulake/habbo/window/IHabboWindowManager.as` | Interface |
| `src/com/sulake/core/window/WindowContext.as` | Per-layer context |
| `src/com/sulake/core/window/WindowController.as` | Base window class |
| `src/com/sulake/core/window/components/DesktopController.as` | Desktop root |

## Next Steps

- [Widget System](UI-Framework/Widget-System) - Room and UI widgets
- [Event Handling](UI-Framework/Event-Handling) - Mouse and keyboard events
- [Theming](UI-Framework/Skinning-Theming) - UI theming and skins