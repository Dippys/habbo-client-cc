# Coding Conventions

This document describes the ActionScript 3 conventions, patterns, and architectural approaches used throughout the Habbo client codebase. Understanding these conventions is essential for maintaining consistency when contributing to this codebase.

## Language and Framework Version

The codebase targets **ActionScript 3.0** (ECMA-4 draft) running on **Adobe Flash Player 10.x - 11.x** (AIR support exists for specific subsystems). The client uses the Sulake core framework, a component-based architecture that predates modern AS3 frameworks like PureMVC or Robotlegs.

```
Flash Player 10.2+ (minimum for late-era Habbo client)
ActionScript 3.0
Sulake Core Framework (pre-2010)
```

## Naming Conventions

### Classes

| Pattern | Example | Notes |
|---------|---------|-------|
| Concrete class | `HabboInventory` | PascalCase, no prefix |
| Interface | `IHabboInventory` | Prefixed with `I` |
| IID (interface ID) | `IIDHabboInventory` | Used for dependency injection |
| Event class | `HabboInventoryTrackingEvent` | Domain-prefixed |
| Enum class | `InventoryCategory` | Static constants only, no enum keyword |
| Model | `FurniModel` | Suffix: `Model` |
| View | `FurniView` | Suffix: `View` |
| Component | `Component` | Base class in `com.sulake.core.runtime` |

### Methods

- **Public methods**: PascalCase — `initialize()`, `toggleInventoryPage()`
- **Private methods**: `_leadingUnderscore` + PascalCase — `_initializeInternal()`, `_onWindowEvent()`
- **Event handlers**: `_on<EventName>` — `_onToolbarEvent()`, `_onConnectionMessage()`

### Variables and Constants

| Pattern | Example | Scope |
|---------|---------|-------|
| Private member | `_inventoryItems:Vector.<FurnitureItem>` | Leading underscore |
| Protected member | `_category:String` | Leading underscore |
| Public member (rare) | `events:IEventDispatcher` | No underscore |
| Local variable | `var item:FurnitureItem = ...` | camelCase |
| Constant (static const) | `COMPONENT_EVENT_RUNNING:String` | UPPER_CASE |
| Enum constant | `InventoryCategory.FURNI:String` | PascalCase (class name) |

```actionscript
// Example from HabboInventory.as:68-89
private var _communication:IHabboCommunicationManager;
private var _incomingMessages:IncomingMessages;
private var _windowManager:IHabboWindowManager;
private var _sessionDataManager:ISessionDataManager;
private var _view:InventoryMainView;
private var _inventories:Map;
private var _purse:Purse;
private var _isInitialized:Boolean;

// Constant from Component.as:19
public static const COMPONENT_EVENT_RUNNING:String = "COMPONENT_EVENT_RUNNING";
```

## Package Structure

The codebase follows a hierarchical namespace convention:

```
com.sulake/
├── core/                    # Framework-level components
│   ├── runtime/            # Component model, context, lifecycle
│   ├── communication/      # Message system, connection, encryption
│   ├── window/            # UI framework
│   ├── assets/            # Resource loading
│   ├── localization/      # i18n
│   └── utils/             # Helpers (Map, XMLUtils)
│
├── habbo/                  # Habbo-specific features
│   ├── inventory/         # Inventory subsystem
│   ├── communication/    # Habbo message parsers/composers
│   ├── catalog/          # Catalog/purchase system
│   ├── room/             # Room rendering and logic
│   ├── toolbar/          # Toolbar components
│   ├── window/           # Habbo-specific windows
│   └── ...
│
├── iid/                   # Interface ID markers for DI
│   ├── IIDHabboInventory.as
│   ├── IIDHabboWindowManager.as
│   └── ...
│
└── habboclient/           # Generated client stub libraries
```

### Directory Organization Within a Feature

Each feature subsystem follows a consistent internal structure:

```
inventory/
├── HabboInventory.as          # Main component (extends Component)
├── IHabboInventory.as        # Public interface
├── InventoryMainView.as      # Primary UI
├── IncomingMessages.as       # Packet dispatcher
├── UnseenItemTracker.as      # "New item" tracking
│
├── furni/                    # Category subfolder
│   ├── FurniModel.as
│   ├── FurniView.as
│   └── FurniGridView.as
│
├── badges/
│   ├── BadgesModel.as
│   ├── BadgesView.as
│   └── Badge.as
│
├── events/                   # Domain events
│   ├── HabboInventoryTrackingEvent.as
│   ├── HabboInventoryItemAddedEvent.as
│   └── ...
│
├── enum/                     # Constants
│   ├── InventoryCategory.as
│   ├── FurniCategory.as
│   └── ...
│
├── items/                    # Data models
│   ├── FurnitureItem.as
│   ├── GroupItem.as
│   └── IFurnitureItem.as
│
└── common/                   # Shared utilities
    ├── ThumbListManager.as
    └── IThumbListDataProvider.as
```

## Class Design Patterns

### Component Model (Sulake Core Framework)

All major features extend `Component` from `com.sulake.core.runtime`. The component model provides:

- **Dependency injection** via interface identifiers (IID)
- **Lifecycle management** — `initialize()`, `update()`, `dispose()`
- **Event dispatching** — built-in `events:IEventDispatcher`
- **Locked state** — components can be locked until dependencies resolve

```actionscript
// HabboInventory.as:66-96
public class HabboInventory extends Component 
    implements IHabboInventory, ILinkEventTracker 
{
    private var _communication:IHabboCommunicationManager;
    private var _windowManager:IHabboWindowManager;
    private var _sessionDataManager:ISessionDataManager;
    
    public function HabboInventory(k:IContext, _arg_2:uint=0, _arg_3:IAssetLibrary=null)
    {
        super(k, _arg_2, _arg_3);
        this._purse = new Purse();
        this._initedInventoryCategories = [];
    }
}
```

The component receives dependencies through constructor injection (IID markers) and initialization order is controlled by the `ComponentContext` at startup.

### Interface / Implementation Split

Every major component exposes a public interface:

```actionscript
// IHabboInventory.as:7-45
public interface IHabboInventory extends IUnknown 
{
    function get events():IEventDispatcher;
    function get clubDays():int;
    function get clubPeriods():int;
    function get clubLevel():int;
    function toggleInventoryPage(_arg_1:String, _arg_2:String=null, _arg_3:Boolean=false):void;
    function getFloorItemById(_arg_1:int):IFurnitureItem;
    function getWallItemById(_arg_1:int):IFurnitureItem;
    // ... more methods
}
```

IID markers (`com.sulake.iid.IIDHabboInventory`) serve as type-safe identifiers for the DI system:

```actionscript
// IIDHabboInventory.as
package com.sulake.iid
{
    import com.sulake.core.runtime.IID;

    public class IIDHabboInventory implements IID 
    {
    }
}
```

### Model-View Segregation

Inventory follows a strict Model/View split per category:

```actionscript
// FurniModel.as:54-60
public class FurniModel implements IInventoryModel 
{
    private static const _Str_14184:int = 100;

    private var _controller:HabboInventory;
    private var _view:FurniView;
    private var _furniData:Vector.<GroupItem>;
    private var _assets:IAssetLibrary;
    // ... model logic
}
```

The pattern:
- **Model** — business logic, data storage, packet handling, state management
- **View** — UI rendering, user interaction, window components
- **Controller** (parent component) — coordinates Model/View, manages lifecycle

### Event System

Domain events follow the Flash AS3 event pattern with static string constants:

```actionscript
// events/HabboInventoryTrackingEvent.as:3-13
public class HabboInventoryTrackingEvent 
{
    public static const HABBO_INVENTORY_TRACKING_EVENT_CLOSED:String = "HABBO_INVENTORY_TRACKING_EVENT_CLOSED";
    public static const HABBO_INVENTORY_TRACKING_EVENT_FURNI:String = "HABBO_INVENTORY_TRACKING_EVENT_FURNI";
    public static const HABBO_INVENTORY_TRACKING_EVENT_BADGES:String = "HABBO_INVENTORY_TRACKING_EVENT_BADGES";
    public static const HABBO_INVENTORY_TRACKING_EVENT_TRADING:String = "HABBO_INVENTORY_TRACKING_EVENT_TRADING";
    public static const HABBO_INVENTORY_TRACKING_EVENT_PETS:String = "HABBO_INVENTORY_TRACKING_EVENT_PETS";
    public static const HABBO_INVENTORY_TRACKING_EVENT_BOTS:String = "HABBO_INVENTORY_TRACKING_EVENT_BOTS";
}
```

Events are dispatched through the component's `events` property (inherited from `Component`).

### Message Pattern (Composer/Parser)

The communication layer uses a Composer/Parser pattern:

```actionscript
// IMessageComposer (core/communication/messages/IMessageComposer.as)
public interface IMessageComposer 
{
    function getMessageArray():Array;
    function dispose():void;
}

// IMessageParser (core/communication/messages/IMessageParser.as)
public interface IMessageParser 
{
    function flush():Boolean;
    function parse(data:IMessageDataWrapper):Boolean;
}
```

Outgoing messages (Composers):
- Located in `com.sulake.habbo.communication.messages.outgoing.*`
- Example: `RequestFurniInventoryComposer`, `OpenTradingComposer`, `GetCreditsInfoComposer`

Incoming messages (Parsers):
- Located in `com.sulake.habbo.communication.messages.incoming.*`
- Example: `FurniListParser`, `TradingOpenParser`

## Error Handling Approach

### Exception Types

The framework provides custom exception classes in `com.sulake.core.runtime.exceptions`:

| Exception | Use Case |
|-----------|----------|
| `Exception` | Base with optional chained cause |
| `InvalidComponentException` | Missing IContext in Component constructor |
| `ComponentDisposedException` | Access after dispose |

```actionscript
// core/runtime/exceptions/Exception.as:5-62
public class Exception extends Error 
{
    private var _cause:Error;
    
    public function Exception(message:String, id:int=0, cause:Error=null)
    {
        super(message, id);
        this._cause = cause;
    }
    
    public static function getChainedStackTrace(error:Error):String
    {
        var stacktrace:String;
        var out:String;
        while (error != null)
        {
            stacktrace = error.getStackTrace();
            if (stacktrace != null)
            {
                if (out == null)
                {
                    out = stacktrace;
                }
                else
                {
                    out = (out + "\ncaused by ");
                    out = (out + stacktrace);
                }
            }
            if ((error is Exception))
            {
                error = (error as Exception).cause;
            }
            else
            {
                error = null;
            }
        }
        return out;
    }
}
```

### Try-Catch Usage

Explicit try-catch is used sparingly, primarily in asset loading and window contexts:

```actionscript
// core/window/WindowContext.as:330
try
{
    window = this.createWindow(param1,param2);
}
catch (error: Error)
{
    LOGGER.log(4, "Could not create window: " + param1);
}

// core/assets/AssetLibrary.as:462
catch (error: Error)
{
    if (this._disposed)
    {
        return;
    }
    // handle error, continue operation
}
```

### Error Logging

The framework defines logging levels through Component events:
- `COMPONENT_EVENT_DEBUG` — debug messages
- `COMPONENT_EVENT_WARNING` — recoverable issues
- `COMPONENT_EVENT_ERROR` — failures

```actionscript
// Component.as:19-24
public static const COMPONENT_EVENT_RUNNING:String = "COMPONENT_EVENT_RUNNING";
public static const COMPONENT_EVENT_DISPOSING:String = "COMPONENT_EVENT_DISPOSING";
public static const COMPONENT_EVENT_WARNING:String = "COMPONENT_EVENT_WARNING";
public static const COMPONENT_EVENT_ERROR:String = "COMPONENT_EVENT_ERROR";
public static const COMPONENT_EVENT_DEBUG:String = "COMPONENT_EVENT_DEBUG";
public static const COMPONENT_EVENT_UNLOCKED:String = "COMPONENT_EVENT_UNLOCKED";
```

## Sulake Core Framework Patterns

### Component Lifecycle

```
1. Constructor(IContext, flags, assets)
2. injectDependency() for each declared dependency
3. allDependenciesRequested()
4. initialize() [override point]
5. update() [optional, for frame-based logic]
6. dispose() [cleanup, release references]
```

### Dependency Injection via IID

Components declare dependencies using constructor parameters marked with IID interfaces. The `Component` base class handles injection:

```actionscript
// Component.as:46-73 (simplified)
public function Component(k:IContext, _arg_2:uint=0, assets:IAssetLibrary=null)
{
    this._iids = new InterfaceStructList();
    this._events = new EventDispatcherWrapper();
    this._context = k;
    
    if (this._context == null)
    {
        throw (new InvalidComponentException("IContext not provided to Component's constructor!"));
    }
    
    for each (dependency in this.dependencies)
    {
        if (dependency.isRequired)
        {
            this._requiredDependencyIids.push(getQualifiedClassName(dependency.identifier));
        }
        this.injectDependency(dependency.identifier, dependency.dependencySetter, dependency.isRequired, dependency.eventListeners);
    }
    this.allDependenciesRequested();
}
```

### Component Flags

| Flag | Value | Purpose |
|------|-------|---------|
| `COMPONENT_FLAG_NULL` | 0 | Default |
| `COMPONENT_FLAG_DISPOSABLE` | 1 | Can be disposed |
| `COMPONENT_FLAG_CONTEXT` | 2 | Is a context |
| `COMPONENT_FLAG_INTERFACE` | 4 | Is an interface |

```actionscript
// Component.as:26-29
public static const COMPONENT_FLAG_NULL:uint = 0;
public static const COMPONENT_FLAG_DISPOSABLE:uint = 1;
public static const COMPONENT_FLAG_CONTEXT:uint = 2;
public static const COMPONENT_FLAG_INTERFACE:uint = 4;
```

### Interface Registration

Components register their interfaces at construction time through the IID system:

```actionscript
// Component.as - IUnknown implementation
public function getInterface(name:String):Object
{
    return this._iids.getInterfaceByName(name);
}
```

## Code Examples from src/

### Inventory Category Enum

```actionscript
// enum/InventoryCategory.as:3-12
public class InventoryCategory 
{
    public static const FURNI:String = "furni";
    public static const RENTABLES:String = "rentables";
    public static const BADGES:String = "badges";
    public static const EFFECTS:String = "effects";
    public static const PETS:String = "pets";
    public static const BOTS:String = "bots";
    public static const MARKETPLACE:String = "marketplace";
}
```

### Private Variable Naming

```actionscript
// FurniModel.as:54-80
public class FurniModel implements IInventoryModel 
{
    private static const _Str_14184:int = 100;  // Legacy naming for constants
    
    private var _controller:HabboInventory;
    private var _view:FurniView;
    private var _furniData:Vector.<GroupItem>;
    private var _assets:IAssetLibrary;
    private var _windowManager:IHabboWindowManager;
    private var _roomEngine:IRoomEngine;
    private var _communication:IHabboCommunicationManager;
    private var _disposed:Boolean = false;
    private var _isListInitialized:Boolean;
    // ...
}
```

Note: Some legacy constants use `_Str_` prefix — these are decompiled remnants and should not be replicated in new code.

### Interface-Implementation Pattern

```actionscript
// IInventoryModel.as (inventory/IInventoryModel.as)
public interface IInventoryModel 
{
    function get controller():HabboInventory;
    function get view():IInventoryView;
    function get isInitialized():Boolean;
    function initialize():void;
    function _Str_2664():void;
    function _Str_2596():void;
    function dispose():void;
}
```

## Cross-References

- [Inventory System](../Features/Inventory) — detailed inventory architecture with category breakdown
- [Encryption & Handshake](../Protocol/Encryption) — crypto primitives and handshake sequence
- [Wire Format](../Protocol/Wire-Format) — message framing before/after encryption
- [Message Pattern](../Protocol/Message-Pattern) — composer/parser details and IMessageConfiguration
- [Component Lifecycle](./Application-Lifecycle) — startup sequence and boot order
- [UI Framework/Skinning-Theming](../UI-Framework/Skinning-Theming) — window system and XML layouts