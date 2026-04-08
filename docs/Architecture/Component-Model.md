# Component Model

The Habbo client uses a sophisticated **component-based architecture** built on the Sulake Core framework. This document details the dependency injection system, component lifecycle, and event handling patterns.

## Component Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SULAKE CORE COMPONENT SYSTEM                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         ICore                                       │   │
│   │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐   │   │
│   │  │   Context   │  │   Events     │  │   Component Registry    │   │   │
│   │  │  Management │  │   Dispatcher │  │                          │   │   │
│   │  └──────────────┘  └──────────────┘  └─────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                       Component                                      │   │
│   │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐   │   │
│   │  │  Lifecycle  │  │  Dependency  │  │     Asset Library       │   │   │
│   │  │  Management │  │    Queue     │  │                          │   │   │
│   │  └──────────────┘  └──────────────┘  └─────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                    ┌───────────────┼───────────────┐                        │
│                    ▼               ▼               ▼                        │
│            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                 │
│            │  Component  │ │  Component  │ │  Component  │                 │
│            │     A      │ │     B      │ │     C      │                 │
│            └─────────────┘ └─────────────┘ └─────────────┘                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Core Interfaces and Classes

### ICore Interface
**File:** `src/com/sulake/core/runtime/ICore.as`

The central runtime interface that manages the entire application.

```actionscript
public interface ICore
{
    function get events():IEventDispatcher;
    function initialize():void;
    function prepareComponent(k:IUnknown):void;
    function readConfigDocument(k:XML, _arg_2:IUnknown):void;
    function getNumberOfFilesLoaded():uint;
    function getNumberOfFilesPending():uint;
}
```

### Component Class
**File:** `src/com/sulake/core/runtime/Component.as`

Base class for all components in the system.

```actionscript
public class Component implements IUnknown, IHabboConfigurationManager
{
    public var events:IEventDispatcher;
    protected var context:IContext;
    protected var assets:IAssetLibrary;
    protected var disposed:Boolean = false;
    protected var locked:Boolean = true;

    protected function initComponent():void;
    protected function dispose():void;
    protected function purge():void;
}
```

### Component Flags

```actionscript
public static const COMPONENT_FLAG_NULL:uint = 0;
public static const COMPONENT_FLAG_DISPOSABLE:uint = 1;
public static const COMPONENT_FLAG_CONTEXT:uint = 2;
public static const COMPONENT_FLAG_INTERFACE:uint = 4;
```

## Dependency Injection System

### IID (Interface ID) Pattern
**File:** `src/com/sulake/core/runtime/IID.as`

Every interface has a corresponding IID class for dependency identification.

```actionscript
// Interface definition
public interface IHabboConfigurationManager { }

// IID implementation
public class IIDHabboConfigurationManager implements IID { }
```

### ComponentDependency Class
**File:** `src/com/sulake/core/runtime/ComponentDependency.as`

Defines a dependency on another component.

```actionscript
public class ComponentDependency
{
    private var _identifier:IID;
    private var _dependencySetter:Function;
    private var _isRequired:Boolean;
    private var _eventListeners:Array;

    public function ComponentDependency(
        identifier:IID,           // Interface to request
        dependencySetter:Function, // Callback when available
        isRequired:Boolean=true,   // Block init until ready?
        eventListeners:Array=null  // Events to listen
    );
}
```

### Dependency Declaration Pattern

Components declare dependencies by overriding the `dependencies` getter:

```actionscript
override protected function get dependencies():Vector.<ComponentDependency>
{
    return (super.dependencies.concat(new <ComponentDependency>[
        new ComponentDependency(
            new IIDCoreCommunicationManager(),
            function (k:ICoreCommunicationManager):void
            {
                _communication = k;
            }
        ),
        new ComponentDependency(
            new IIDHabboConfigurationManager(),
            null,  // No setter, use queueInterface
            false, // Optional dependency
            [
                { "type": Event.COMPLETE, "callback": this.onConfigurationComplete }
            ]
        )
    ]));
}
```

### Interface Request Queue
**File:** `src/com/sulake/core/runtime/IContext.as`

```actionscript
// Request an interface (async)
context.queueInterface(new IIDSomeInterface(), function(k:IID, obj:SomeInterface):void {
    // obj is available here
});

// Request synchronously if already available
var obj:SomeInterface = context.queueInterface(new IIDSomeInterface());
```

## Component Lifecycle

### Lifecycle State Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPONENT LIFECYCLE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐                                               │
│   │  CREATED    │  new Component(context, flags, assets)       │
│   └──────┬──────┘                                               │
│          │                                                      │
│          ▼                                                      │
│   ┌─────────────┐    Yes    ┌─────────────┐                     │
│   │   LOCKED    │ ────────► │  WAITING   │  Has dependencies?  │
│   └──────┬──────┘           └──────┬──────┘                     │
│          │ No                      │                             │
│          │                         ▼                             │
│          │                  ┌─────────────┐                       │
│          │                  │ READY TO   │  All dependencies    │
│          └────────────────►│   INIT     │  injected             │
│                             └──────┬──────┘                       │
│                                    │                              │
│                                    ▼                              │
│   ┌─────────────┐              ┌─────────────┐                     │
│   │   ACTIVE    │ ◄────────── │INIT_CALLED │  initComponent()   │
│   │             │             └─────────────┘                     │
│   └──────┬──────┘                                             │
│          │                                                      │
│          ▼                                                      │
│   ┌─────────────┐                                               │
│   │  DISPOSED  │  dispose() called                              │
│   └─────────────┘                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Lifecycle Methods

| Method | When Called | Purpose |
|--------|-------------|---------|
| `constructor()` | Object creation | Initialize base properties |
| `initComponent()` | After dependencies ready | Override for initialization |
| `dispose()` | Cleanup | Release resources, remove listeners |
| `purge()` | Before dispose | Override for custom cleanup |

### Lifecycle Example

```actionscript
public class MyComponent extends Component
{
    private var _someService:ISomeService;

    override protected function get dependencies():Vector.<ComponentDependency>
    {
        return (super.dependencies.concat(new <ComponentDependency>[
            new ComponentDependency(
                new IIDSomeService(),
                function (k:IID, service:ISomeService):void
                {
                    _someService = service;
                }
            )
        ]));
    }

    override protected function initComponent():void
    {
        // Component is now ready
        // All dependencies are injected
        _someService.doSomething();
    }

    override protected function dispose():void
    {
        _someService = null;
        super.dispose();
    }
}
```

## Event System

### Component Events
**File:** `src/com/sulake/core/runtime/Component.as`

```actionscript
public static const COMPONENT_EVENT_RUNNING:String = "COMPONENT_EVENT_RUNNING";
public static const COMPONENT_EVENT_DISPOSED:String = "COMPONENT_EVENT_DISPOSED";
public static const COMPONENT_EVENT_LOCKED:String = "COMPONENT_EVENT_LOCKED";
public static const COMPONENT_EVENT_UNLOCKED:String = "COMPONENT_EVENT_UNLOCKED";
```

### Listening for Component Events

```actionscript
// Listen for component ready
component.events.addEventListener(Component.COMPONENT_EVENT_RUNNING, onComponentReady);

// Listen for disposal
component.events.addEventListener(Component.COMPONENT_EVENT_DISPOSED, onComponentDisposed);
```

### Dependency Event Listeners

Events can be declared in the dependency:

```actionscript
new ComponentDependency(
    new IIDHabboConfigurationManager(),
    null,
    false,
    [
        {
            "type": Event.COMPLETE,
            "callback": this.onConfigurationComplete
        }
    ]
)
```

## Component Registry

### Habbo-Specific IIDs
**File:** `src/com/sulake/iid/`

The Habbo client defines 47+ interface IDs:

| IID Class | Interface | Purpose |
|-----------|-----------|---------|
| `IIDHabboCommunicationManager` | `IHabboCommunicationManager` | Server connection |
| `IIDHabboConfigurationManager` | `IHabboConfigurationManager` | Client config |
| `IIDRoomEngine` | `IRoomEngine` | Room rendering |
| `IIDHabboLocalizationManager` | `IHabboLocalizationManager` | Strings |
| `IIDHabboWindowManager` | `IHabboWindowManager` | UI windows |
| `IIDHabboInventoryManager` | `IHabboInventoryManager` | Inventory |
| `IIDHabboCatalogManager` | `IHabboCatalogManager` | Shop |
| `IIDHabboMessenger` | `IHabboMessenger` | Chat |
| `IIDHabboNavigator` | `IHabboNavigator` | Room browser |
| `IIDHabboQuestEngine` | `IHabboQuestEngine` | Quests |

### Bootstrap Classes
**File:** `src/com/sulake/bootstrap/`

Each component has a bootstrap class for factory creation:

```
IIDHabboCommunicationManager  →  HabboCommunicationManagerBootstrap
IIDHabboConfigurationManager →  HabboConfigurationManagerBootstrap
IIDRoomEngine               →  RoomEngineBootstrap
IIDHabboWindowManager       →  HabboWindowManagerComponentBootstrap
...
```

## Creating a New Component

### Step 1: Define the Interface

```actionscript
// src/com/sulake/habbo/mysystem/IMySystem.as
package com.sulake.habbo.mysystem
{
    public interface IMySystem
    {
        function doSomething():void;
    }
}
```

### Step 2: Create the IID

```actionscript
// src/com/sulake/iid/IIDMySystem.as
package com.sulake.iid
{
    import com.sulake.core.runtime.IID;
    import com.sulake.habbo.mysystem.IMySystem;

    public class IIDMySystem implements IID { }
}
```

### Step 3: Implement the Component

```actionscript
// src/com/sulake/habbo/mysystem/MySystem.as
package com.sulake.habbo.mysystem
{
    import com.sulake.core.runtime.Component;
    import com.sulake.core.runtime.IID;
    import com.sulake.iid.IIDMySystem;

    public class MySystem extends Component implements IMySystem, IIDMySystem
    {
        override protected function initComponent():void
        {
            // Initialize
        }
    }
}
```

### Step 4: Create Bootstrap

```actionscript
// src/com/sulake/bootstrap/MySystemBootstrap.as
package com.sulake.bootstrap
{
    import com.sulake.habbo.mysystem.MySystem;

    public class MySystemBootstrap extends MySystem { }
```

### Step 5: Register in HabboMain

```actionscript
// In HabboMain.prepareCore():
this._core.prepareComponent(MySystemBootstrap);
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/com/sulake/core/runtime/ICore.as` | Core interface |
| `src/com/sulake/core/runtime/IContext.as` | Context interface |
| `src/com/sulake/core/runtime/Component.as` | Base component |
| `src/com/sulake/core/runtime/IID.as` | Interface ID base |
| `src/com/sulake/core/runtime/ComponentDependency.as` | Dependency definition |
| `src/com/sulake/iid/` | IID implementations (47 files) |
| `src/com/sulake/bootstrap/` | Bootstrap factories |

## Next Steps

- [Directory Structure](Architecture/Directory-Structure) - Package organization
- [Networking](Core-Systems/Networking) - Connection management
- [Room Engine Architecture](Core-Systems/Room-Engine/Architecture) - Room system
